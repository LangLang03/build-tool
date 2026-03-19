#!/usr/bin/env bash

if [[ -z "${_BUILD_PLUGIN_LOADED:-}" ]]; then
_BUILD_PLUGIN_LOADED=1

declare -gA PLUGINS=()
declare -gA PLUGIN_PATHS=()
declare -gA PLUGIN_VERSIONS=()
declare -gA PLUGIN_DESCRIPTIONS=()
declare -gA PLUGIN_DEPENDENCIES=()
declare -gA PLUGIN_LOADED=()
declare -gA PLUGIN_PATHS_BY_NAME=()

declare -ga PLUGIN_DIRS=()
declare -g PLUGIN_EXTENSIONS=(".sh" ".plugin.sh" ".bash")

declare -gA HOOKS_PRE_BUILD=()
declare -gA HOOKS_POST_BUILD=()
declare -gA HOOKS_PRE_STEP=()
declare -gA HOOKS_POST_STEP=()
declare -gA HOOKS_ON_ERROR=()
declare -gA HOOKS_ON_CLEAN=()

plugin_add_dir() {
    local dir="$1"
    
    if [[ -d "$dir" ]] && ! arr_contains "$dir" "${PLUGIN_DIRS[@]}"; then
        PLUGIN_DIRS+=("$dir")
    fi
}

plugin_discover() {
    local found=0
    
    for dir in "${PLUGIN_DIRS[@]}"; do
        if [[ ! -d "$dir" ]]; then
            continue
        fi
        
        for ext in "${PLUGIN_EXTENSIONS[@]}"; do
            while IFS= read -r -d '' file; do
                local name
                name=$(basename "$file" "$ext")
                name=$(basename "$name" ".plugin")
                
                if [[ -z "${PLUGINS[$name]:-}" ]]; then
                    PLUGINS["$name"]="$file"
                    PLUGIN_PATHS["$name"]="$file"
                    ((found++))
                fi
            done < <(find "$dir" -maxdepth 1 -type f -name "*${ext}" -print0 2>/dev/null)
        done
    done
    
    return $found
}

plugin_load() {
    local name="$1"
    local force="${2:-false}"
    
    if [[ "$force" != "true" ]] && [[ -n "${PLUGIN_LOADED[$name]:-}" ]]; then
        return 0
    fi
    
    local path="${PLUGINS[$name]}"
    
    if [[ -z "$path" ]]; then
        output_error "Plugin not found: $name"
        return 1
    fi
    
    if [[ ! -f "$path" ]]; then
        output_error "Plugin file not found: $path"
        return 1
    fi
    
    PLUGIN_NAME=""
    PLUGIN_VERSION=""
    PLUGIN_DESCRIPTION=""
    PLUGIN_DEPENDENCIES=""
    
    if ! source "$path"; then
        output_error "Failed to load plugin: $name"
        return 1
    fi
    
    local plugin_name="${PLUGIN_NAME:-$name}"
    local plugin_version="${PLUGIN_VERSION:-1.0.0}"
    local plugin_desc="${PLUGIN_DESCRIPTION:-No description}"
    local plugin_deps="${PLUGIN_DEPENDENCIES:-}"
    
    PLUGIN_VERSIONS["$plugin_name"]="$plugin_version"
    PLUGIN_DESCRIPTIONS["$plugin_name"]="$plugin_desc"
    PLUGIN_DEPENDENCIES["$plugin_name"]="$plugin_deps"
    PLUGIN_LOADED["$plugin_name"]="1"
    
    output_debug "Loaded plugin: $plugin_name v$plugin_version"
    
    return 0
}

plugin_load_all() {
    local failed=0
    
    for name in "${!PLUGINS[@]}"; do
        if ! plugin_load "$name"; then
            ((failed++))
        fi
    done
    
    return $failed
}

plugin_unload() {
    local name="$1"
    
    if [[ -z "${PLUGIN_LOADED[$name]:-}" ]]; then
        return 0
    fi
    
    unset "PLUGIN_LOADED[$name]"
    unset "PLUGIN_VERSIONS[$name]"
    unset "PLUGIN_DESCRIPTIONS[$name]"
    unset "PLUGIN_DEPENDENCIES[$name]"
    
    output_debug "Unloaded plugin: $name"
}

plugin_reload() {
    local name="$1"
    
    plugin_unload "$name"
    plugin_load "$name" "true"
}

plugin_is_loaded() {
    local name="$1"
    [[ -n "${PLUGIN_LOADED[$name]:-}" ]]
}

plugin_get_version() {
    local name="$1"
    echo "${PLUGIN_VERSIONS[$name]:-unknown}"
}

plugin_get_description() {
    local name="$1"
    echo "${PLUGIN_DESCRIPTIONS[$name]:-No description}"
}

plugin_get_dependencies() {
    local name="$1"
    echo "${PLUGIN_DEPENDENCIES[$name]:-}"
}

plugin_list() {
    local verbose="${1:-false}"
    
    if [[ "$verbose" == "true" ]]; then
        output_header "Loaded Plugins" 50
        
        for name in "${!PLUGIN_LOADED[@]}"; do
            local version="${PLUGIN_VERSIONS[$name]}"
            local desc="${PLUGIN_DESCRIPTIONS[$name]}"
            local deps="${PLUGIN_DEPENDENCIES[$name]}"
            
            output_key_value "$name" "v$version" 15
            output_bullet "$desc" 2
            [[ -n "$deps" ]] && output_bullet "Dependencies: $deps" 2
        done
    else
        for name in "${!PLUGIN_LOADED[@]}"; do
            echo "$name - ${PLUGIN_DESCRIPTIONS[$name]}"
        done | sort
    fi
}

plugin_check_dependencies() {
    local name="$1"
    local deps="${PLUGIN_DEPENDENCIES[$name]}"
    
    if [[ -z "$deps" ]]; then
        return 0
    fi
    
    local -a missing=()
    IFS=',' read -ra dep_array <<< "$deps"
    
    for dep in "${dep_array[@]}"; do
        dep=$(echo "$dep" | xargs)
        if [[ -n "$dep" ]] && ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        output_warning "Plugin '$name' has missing dependencies: ${missing[*]}"
        return 1
    fi
    
    return 0
}

plugin_install_dependencies() {
    local name="$1"
    local deps="${PLUGIN_DEPENDENCIES[$name]}"
    
    if [[ -z "$deps" ]]; then
        return 0
    fi
    
    local -a to_install=()
    IFS=',' read -ra dep_array <<< "$deps"
    
    for dep in "${dep_array[@]}"; do
        dep=$(echo "$dep" | xargs)
        if [[ -n "$dep" ]] && ! command_exists "$dep"; then
            to_install+=("$dep")
        fi
    done
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        output_info "Installing dependencies for '$name': ${to_install[*]}"
        platform_install "${to_install[@]}"
    fi
}

register_hook() {
    local hook_type="$1"
    local plugin_name="$2"
    local hook_func="$3"
    
    case "$hook_type" in
        pre_build)
            HOOKS_PRE_BUILD["$plugin_name"]="$hook_func"
            ;;
        post_build)
            HOOKS_POST_BUILD["$plugin_name"]="$hook_func"
            ;;
        pre_step)
            HOOKS_PRE_STEP["$plugin_name"]="$hook_func"
            ;;
        post_step)
            HOOKS_POST_STEP["$plugin_name"]="$hook_func"
            ;;
        on_error)
            HOOKS_ON_ERROR["$plugin_name"]="$hook_func"
            ;;
        on_clean)
            HOOKS_ON_CLEAN["$plugin_name"]="$hook_func"
            ;;
        *)
            output_warning "Unknown hook type: $hook_type"
            return 1
            ;;
    esac
    
    output_debug "Registered $hook_type hook for plugin: $plugin_name"
    return 0
}

run_hooks() {
    local hook_type="$1"
    shift
    local args=("$@")
    
    local -n hooks_ref="HOOKS_${hook_type^^}"
    
    for plugin_name in "${!hooks_ref[@]}"; do
        local hook_func="${hooks_ref[$plugin_name]}"
        
        if declare -f "$hook_func" &>/dev/null; then
            output_debug "Running $hook_type hook: $hook_func"
            if ! $hook_func "${args[@]}"; then
                output_warning "Hook $hook_func failed"
            fi
        fi
    done
}

run_pre_build_hooks() {
    run_hooks "pre_build" "$@"
}

run_post_build_hooks() {
    run_hooks "post_build" "$@"
}

run_pre_step_hooks() {
    run_hooks "pre_step" "$@"
}

run_post_step_hooks() {
    run_hooks "post_step" "$@"
}

run_error_hooks() {
    run_hooks "on_error" "$@"
}

run_clean_hooks() {
    run_hooks "on_clean" "$@"
}

declare_dependencies() {
    local deps=("$@")
    PLUGIN_DEPENDENCIES="${PLUGIN_NAME:-unknown}"
    PLUGIN_DEPENDENCIES[$PLUGIN_NAME]=$(IFS=','; echo "${deps[*]}")
}

plugin_create() {
    local name="$1"
    local output_dir="${2:-plugins}"
    local file="${output_dir}/${name}.sh"
    
    if [[ -f "$file" ]]; then
        output_error "Plugin already exists: $file"
        return 1
    fi
    
    ensure_dir "$output_dir"
    
    cat > "$file" << 'PLUGIN_TEMPLATE'
#!/usr/bin/env bash

PLUGIN_NAME="__PLUGIN_NAME__"
PLUGIN_VERSION="1.0.0"
PLUGIN_DESCRIPTION="Plugin description"
PLUGIN_DEPENDENCIES=""

register_target "build" "Build the project" "__PLUGIN_NAME___build"
register_target "clean" "Clean build artifacts" "__PLUGIN_NAME___clean"

pre_build_hook() {
    log_info "Preparing to build..."
}

post_build_hook() {
    log_info "Build completed!"
}

__PLUGIN_NAME___build() {
    step_start "Building..."
    
    output_info "Building..."
    
    step_end
    return 0
}

__PLUGIN_NAME___clean() {
    output_info "Cleaning..."
    rm -rf build/
    return 0
}
PLUGIN_TEMPLATE

    sed -i "s/__PLUGIN_NAME__/$name/g" "$file"
    
    output_success "Created plugin: $file"
    output_info "Edit the file to implement your build logic"
}

plugin_validate() {
    local name="$1"
    local path="${PLUGINS[$name]}"
    
    if [[ -z "$path" ]]; then
        output_error "Plugin not found: $name"
        return 1
    fi
    
    local errors=0
    
    if ! grep -q "PLUGIN_NAME=" "$path" 2>/dev/null; then
        output_warning "Plugin '$name' missing PLUGIN_NAME"
        ((errors++))
    fi
    
    if ! grep -q "register_target" "$path" 2>/dev/null; then
        output_warning "Plugin '$name' has no registered targets"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        output_success "Plugin '$name' is valid"
        return 0
    else
        return 1
    fi
}

plugin_init() {
    local script_dir
    script_dir=$(get_script_dir)
    
    plugin_add_dir "${script_dir}/plugins"
    plugin_add_dir "./plugins"
    plugin_add_dir "./.build/plugins"
    plugin_add_dir "${HOME}/.build-tool/plugins"
    
    plugin_discover
}

source_plugin() {
    local plugin_name="$1"
    local plugin_file=""
    
    local script_dir="${SCRIPT_DIR:-}"
    if [[ -z "$script_dir" ]]; then
        script_dir=$(get_script_dir)
    fi
    
    local search_dirs=()
    
    if [[ -n "$PROJECT_DIR" ]]; then
        search_dirs+=("$PROJECT_DIR/plugins")
        search_dirs+=("$PROJECT_DIR/.build/plugins")
    fi
    
    search_dirs+=("$(pwd)/plugins")
    search_dirs+=("$(pwd)/.build/plugins")
    search_dirs+=("${script_dir}/plugins")
    search_dirs+=("${HOME}/.build-tool/plugins")
    
    if [[ "$plugin_name" == /* ]]; then
        if [[ -f "$plugin_name" ]]; then
            plugin_file="$plugin_name"
        fi
    else
        for dir in "${search_dirs[@]}"; do
            local test_file="$dir/${plugin_name}.sh"
            if [[ -f "$test_file" ]]; then
                plugin_file="$test_file"
                break
            fi
        done
    fi
    
    if [[ -z "$plugin_file" ]]; then
        output_error "Plugin not found: $plugin_name"
        output_debug "Searched directories: ${search_dirs[*]}"
        return 1
    fi
    
    PLUGIN_NAME=""
    PLUGIN_VERSION=""
    PLUGIN_DESCRIPTION=""
    PLUGIN_DEPENDENCIES=""
    
    if ! source "$plugin_file"; then
        output_error "Failed to load plugin: $plugin_name"
        return 1
    fi
    
    local plugin_name_final="${PLUGIN_NAME:-$plugin_name}"
    local plugin_version="${PLUGIN_VERSION:-1.0.0}"
    local plugin_desc="${PLUGIN_DESCRIPTION:-No description}"
    local plugin_deps="${PLUGIN_DEPENDENCIES:-}"
    
    PLUGIN_VERSIONS["$plugin_name_final"]="$plugin_version"
    PLUGIN_DESCRIPTIONS["$plugin_name_final"]="$plugin_desc"
    PLUGIN_DEPENDENCIES["$plugin_name_final"]="$plugin_deps"
    PLUGIN_LOADED["$plugin_name_final"]="1"
    PLUGINS["$plugin_name_final"]="$plugin_file"
    PLUGIN_PATHS["$plugin_name_final"]="$plugin_file"
    
    output_debug "Loaded plugin: $plugin_name_final v$plugin_version from $plugin_file"
    
    return 0
}

depends_on() {
    local deps=("$@")
    local target="${BUILD_CURRENT_TARGET:-}"
    
    if [[ -n "$target" ]]; then
        local current_deps="${BUILD_TARGET_DEPS[$target]:-}"
        for dep in "${deps[@]}"; do
            if [[ -n "$current_deps" ]]; then
                if [[ ! ",$current_deps," == *",$dep,"* ]]; then
                    current_deps="$current_deps,$dep"
                fi
            else
                current_deps="$dep"
            fi
        done
        BUILD_TARGET_DEPS["$target"]="$current_deps"
    fi
}

fi
