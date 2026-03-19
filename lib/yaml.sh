#!/usr/bin/env bash

if [[ -z "${_BUILD_YAML_LOADED:-}" ]]; then
_BUILD_YAML_LOADED=1

yaml_check_yq() {
    if ! command_exists yq; then
        output_error "$(i18n_get "yaml_required")"
        output_info "$(i18n_get "install_yq")"
        return 1
    fi
    return 0
}

yaml_read() {
    local file="$1"
    local path="$2"
    local default="${3:-}"
    
    if [[ ! -f "$file" ]]; then
        echo "$default"
        return 1
    fi
    
    local result
    result=$(yq eval ".${path}" "$file" 2>/dev/null)
    
    if [[ "$result" == "null" ]] || [[ -z "$result" ]]; then
        echo "$default"
    else
        echo "$result"
    fi
}

yaml_read_str() {
    local file="$1"
    local path="$2"
    local default="${3:-}"
    
    local result
    result=$(yaml_read "$file" "$path" "$default")
    
    if [[ "$result" == "null" ]]; then
        echo "$default"
    else
        echo "$result"
    fi
}

yaml_read_int() {
    local file="$1"
    local path="$2"
    local default="${3:-0}"
    
    local result
    result=$(yaml_read "$file" "$path" "$default")
    
    if [[ "$result" =~ ^[0-9]+$ ]]; then
        echo "$result"
    else
        echo "$default"
    fi
}

yaml_read_bool() {
    local file="$1"
    local path="$2"
    local default="${3:-false}"
    
    local result
    result=$(yaml_read "$file" "$path" "$default")
    
    case "${result,,}" in
        true|yes|1|on)
            echo "true"
            ;;
        false|no|0|off)
            echo "false"
            ;;
        *)
            echo "$default"
            ;;
    esac
}

yaml_read_array() {
    local file="$1"
    local path="$2"
    local -n result_array="$3"
    
    result_array=()
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    local count
    count=$(yq eval ".${path} | length" "$file" 2>/dev/null)
    
    if [[ "$count" == "null" ]] || [[ -z "$count" ]] || [[ "$count" -eq 0 ]]; then
        return 0
    fi
    
    local i
    for ((i=0; i<count; i++)); do
        local item
        item=$(yq eval ".${path}[$i]" "$file" 2>/dev/null)
        [[ "$item" != "null" ]] && result_array+=("$item")
    done
}

yaml_read_keys() {
    local file="$1"
    local path="$2"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    yq eval ".${path} | keys | .[]" "$file" 2>/dev/null
}

yaml_has() {
    local file="$1"
    local path="$2"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    local result
    result=$(yq eval ".${path}" "$file" 2>/dev/null)
    
    [[ "$result" != "null" ]] && [[ -n "$result" ]]
}

yaml_set() {
    local file="$1"
    local path="$2"
    local value="$3"
    
    if [[ ! -f "$file" ]]; then
        echo "{}" > "$file"
    fi
    
    yq eval -i ".${path} = \"${value}\"" "$file" 2>/dev/null
}

yaml_delete() {
    local file="$1"
    local path="$2"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    yq eval -i "del(.${path})" "$file" 2>/dev/null
}

yaml_load_config() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    yaml_check_yq || return 1
    
    PROJECT_NAME=$(yaml_read_str "$file" "project.name" "$(basename "$(dirname "$file")")")
    PROJECT_VERSION=$(yaml_read_str "$file" "project.version" "1.0.0")
    
    SOURCE_DIR=$(yaml_read_str "$file" "directories.source" "src")
    BUILD_DIR=$(yaml_read_str "$file" "directories.build" "output")
    
    local -a plugins=()
    yaml_read_array "$file" "plugins" plugins
    
    for plugin in "${plugins[@]}"; do
        source_plugin "$plugin"
    done
    
    local target_scripts
    target_scripts=$(yaml_read_keys "$file" "targets")
    
    while IFS= read -r target_name; do
        [[ -z "$target_name" ]] && continue
        
        local script_path
        script_path=$(yaml_read_str "$file" "targets.$target_name")
        
        if [[ -n "$script_path" ]]; then
            local full_path
            if [[ "$script_path" == /* ]]; then
                full_path="$script_path"
            else
                full_path="${PROJECT_DIR}/${script_path}"
            fi
            
            if [[ -f "$full_path" ]]; then
                register_target "$target_name" "$(i18n_get "custom_target"): $target_name" "custom_target_$target_name"
                
                eval "custom_target_${target_name}() {
                    source '${full_path}'
                }"
            else
                output_warning "$(i18n_get "target_script_not_found"): $full_path"
            fi
        fi
    done <<< "$target_scripts"
    
    local hook_scripts
    hook_scripts=$(yaml_read_keys "$file" "hooks")
    
    while IFS= read -r hook_name; do
        [[ -z "$hook_name" ]] && continue
        
        local hook_script
        hook_script=$(yaml_read_str "$file" "hooks.$hook_name")
        
        if [[ -n "$hook_script" ]]; then
            local full_path
            if [[ "$hook_script" == /* ]]; then
                full_path="$hook_script"
            else
                full_path="${PROJECT_DIR}/${hook_script}"
            fi
            
            if [[ -f "$full_path" ]]; then
                register_hook "$hook_name" "yaml" "yaml_hook_${hook_name}"
                
                eval "yaml_hook_${hook_name}() {
                    source '${full_path}'
                }"
            fi
        fi
    done <<< "$hook_scripts"
    
    return 0
}

fi
