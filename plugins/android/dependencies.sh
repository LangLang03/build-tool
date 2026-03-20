#!/usr/bin/env bash

if [[ -z "${_ANDROID_DEPS_LOADED:-}" ]]; then
_ANDROID_DEPS_LOADED=1

declare -g ANDROID_DEPS_DIR=""
declare -g ANDROID_DEPS_CACHE_DIR=""

declare -ga ANDROID_RESOLVED_DEPS=()
declare -gA ANDROID_DEP_PATHS=()

android_deps_init() {
    ANDROID_DEPS_DIR="${ANDROID_BUILD_DIR}/dependencies"
    ANDROID_DEPS_CACHE_DIR="${CACHE_DIR}/android/dependencies"
    
    ensure_dir "$ANDROID_DEPS_DIR"
    ensure_dir "$ANDROID_DEPS_CACHE_DIR"
}

android_maven_parse_coord() {
    local coord="$1"
    local group artifact version
    
    IFS=':' read -r group artifact version <<< "$coord"
    
    echo "${group}|${artifact}|${version}"
}

android_maven_to_path() {
    local coord="$1"
    local group artifact version
    
    IFS='|' read -r group artifact version <<< "$(android_maven_parse_coord "$coord")"
    
    local group_path="${group//.//}"
    echo "${group_path}/${artifact}/${version}/${artifact}-${version}"
}

android_maven_get_filename() {
    local coord="$1"
    local ext="${2:-aar}"
    
    local group artifact version
    IFS='|' read -r group artifact version <<< "$(android_maven_parse_coord "$coord")"
    
    echo "${artifact}-${version}.${ext}"
}

android_download_file() {
    local url="$1"
    local output="$2"
    
    local download_cmd
    
    if command_exists curl; then
        curl -fsSL -o "$output" "$url"
        return $?
    elif command_exists wget; then
        wget -q -O "$output" "$url"
        return $?
    else
        output_error "$(android_i18n_get "download_failed"): curl or wget required"
        return 1
    fi
}

android_download_dependency() {
    local coord="$1"
    local type="${2:-aar}"
    
    local group artifact version
    IFS='|' read -r group artifact version <<< "$(android_maven_parse_coord "$coord")"
    
    if [[ -z "$group" ]] || [[ -z "$artifact" ]] || [[ -z "$version" ]]; then
        output_error "$(android_i18n_printf "invalid_dep_coord" "$coord")"
        return 1
    fi
    
    local dep_path
    dep_path=$(android_maven_to_path "$coord")
    local filename
    filename=$(android_maven_get_filename "$coord" "$type")
    
    local cache_file="${ANDROID_DEPS_CACHE_DIR}/${dep_path}.${type}"
    
    if [[ -f "$cache_file" ]]; then
        output_debug "$(android_i18n_printf "cache_hit_coord" "$coord")"
        ANDROID_DEP_PATHS["$coord"]="$cache_file"
        return 0
    fi
    
    ensure_dir "$(dirname "$cache_file")"
    
    output_info "$(android_i18n_get "downloading"): $coord"
    
    for repo in "${ANDROID_REPOSITORIES[@]}"; do
        local url="${repo}/${dep_path}.${type}"
        
        output_debug "$(android_i18n_printf "trying_url" "$url")"
        
        if android_download_file "$url" "$cache_file"; then
            if [[ -f "$cache_file" ]] && [[ -s "$cache_file" ]]; then
                output_success "$(android_i18n_get "download_success"): $coord"
                ANDROID_DEP_PATHS["$coord"]="$cache_file"
                return 0
            fi
            rm -f "$cache_file"
        fi
    done
    
    output_error "$(android_i18n_get "download_failed"): $coord"
    return 1
}

android_extract_aar() {
    local aar_file="$1"
    local output_dir="$2"
    
    if [[ ! -f "$aar_file" ]]; then
        output_error "$(android_i18n_printf "aar_not_found" "$aar_file")"
        return 1
    fi
    
    ensure_dir "$output_dir"
    
    output_debug "$(android_i18n_get "extracting"): $aar_file"
    
    if ! unzip -q -o "$aar_file" -d "$output_dir" 2>/dev/null; then
        output_error "$(android_i18n_get "extract_failed"): $aar_file"
        return 1
    fi
    
    return 0
}

android_extract_jar() {
    local jar_file="$1"
    local output_dir="$2"
    
    if [[ ! -f "$jar_file" ]]; then
        output_error "$(android_i18n_printf "jar_not_found" "$jar_file")"
        return 1
    fi
    
    ensure_dir "$output_dir"
    
    output_debug "$(android_i18n_get "extracting"): $jar_file"
    
    if ! unzip -q -o "$jar_file" -d "$output_dir" 2>/dev/null; then
        output_error "$(android_i18n_get "extract_failed"): $jar_file"
        return 1
    fi
    
    return 0
}

android_process_aar() {
    local coord="$1"
    
    local aar_file="${ANDROID_DEP_PATHS[$coord]}"
    
    if [[ -z "$aar_file" ]] || [[ ! -f "$aar_file" ]]; then
        if ! android_download_dependency "$coord" "aar"; then
            return 1
        fi
        aar_file="${ANDROID_DEP_PATHS[$coord]}"
    fi
    
    local group artifact version
    IFS='|' read -r group artifact version <<< "$(android_maven_parse_coord "$coord")"
    
    local extract_dir="${ANDROID_DEPS_DIR}/${artifact}-${version}"
    
    if [[ -d "$extract_dir" ]]; then
        output_debug "$(android_i18n_printf "already_extracted_coord" "$coord")"
        return 0
    fi
    
    android_extract_aar "$aar_file" "$extract_dir"
    
    local classes_jar="${extract_dir}/classes.jar"
    if [[ -f "$classes_jar" ]]; then
        local classes_dir="${extract_dir}/classes"
        android_extract_jar "$classes_jar" "$classes_dir"
    fi
    
    return 0
}

android_process_jar() {
    local coord="$1"
    
    local jar_file="${ANDROID_DEP_PATHS[$coord]}"
    
    if [[ -z "$jar_file" ]] || [[ ! -f "$jar_file" ]]; then
        if ! android_download_dependency "$coord" "jar"; then
            return 1
        fi
        jar_file="${ANDROID_DEP_PATHS[$coord]}"
    fi
    
    local group artifact version
    IFS='|' read -r group artifact version <<< "$(android_maven_parse_coord "$coord")"
    
    local extract_dir="${ANDROID_DEPS_DIR}/${artifact}-${version}"
    
    if [[ -d "$extract_dir" ]]; then
        output_debug "$(android_i18n_printf "already_extracted_coord" "$coord")"
        return 0
    fi
    
    android_extract_jar "$jar_file" "$extract_dir"
    
    return 0
}

android_resolve_dependency() {
    local coord="$1"
    local type="${2:-implementation}"
    
    if arr_contains "$coord" "${ANDROID_RESOLVED_DEPS[@]}"; then
        return 0
    fi
    
    output_debug "$(android_i18n_get "deps_resolving"): $coord"
    
    if android_download_dependency "$coord" "aar" 2>/dev/null; then
        android_process_aar "$coord"
        ANDROID_RESOLVED_DEPS+=("$coord")
        return 0
    fi
    
    if android_download_dependency "$coord" "jar" 2>/dev/null; then
        android_process_jar "$coord"
        ANDROID_RESOLVED_DEPS+=("$coord")
        return 0
    fi
    
    output_error "$(android_i18n_get "deps_failed"): $coord"
    return 1
}

android_resolve_all_dependencies() {
    output_section "$(android_i18n_get "deps_resolving")"
    
    android_deps_init
    
    local total=0
    local success=0
    local failed=0
    
    for dep in "${ANDROID_DEPS_IMPLEMENTATION[@]}"; do
        ((total++))
        if android_resolve_dependency "$dep" "implementation"; then
            ((success++))
        else
            ((failed++))
        fi
    done
    
    for dep in "${ANDROID_DEPS_COMPILE_ONLY[@]}"; do
        ((total++))
        if android_resolve_dependency "$dep" "compile_only"; then
            ((success++))
        else
            ((failed++))
        fi
    done
    
    output_info "$(android_i18n_printf "deps_resolved_count" "$success" "$total")"
    
    if [[ $failed -gt 0 ]]; then
        output_warning "$(android_i18n_printf "deps_failed_count" "$failed")"
        return 1
    fi
    
    output_success "$(android_i18n_get "deps_resolved")"
    return 0
}

android_get_classpath() {
    local cp=""
    
    local android_jar
    android_jar=$(android_get_android_jar)
    
    if [[ -n "$android_jar" ]]; then
        cp="$android_jar"
    fi
    
    for dep_dir in "${ANDROID_DEPS_DIR}"/*; do
        if [[ -d "$dep_dir" ]]; then
            if [[ -d "${dep_dir}/classes" ]]; then
                [[ -n "$cp" ]] && cp="${cp}:"
                cp="${cp}${dep_dir}/classes"
            fi
            
            if [[ -f "${dep_dir}/classes.jar" ]]; then
                [[ -n "$cp" ]] && cp="${cp}:"
                cp="${cp}${dep_dir}/classes.jar"
            fi
        fi
    done
    
    echo "$cp"
}

android_get_jar_files() {
    local -a jars=()
    
    for dep_dir in "${ANDROID_DEPS_DIR}"/*; do
        if [[ -d "$dep_dir" ]]; then
            if [[ -f "${dep_dir}/classes.jar" ]]; then
                jars+=("${dep_dir}/classes.jar")
            fi
        fi
    done
    
    echo "${jars[@]}"
}

android_get_manifest_files() {
    local -a manifests=()
    
    for dep_dir in "${ANDROID_DEPS_DIR}"/*; do
        if [[ -d "$dep_dir" ]]; then
            if [[ -f "${dep_dir}/AndroidManifest.xml" ]]; then
                manifests+=("${dep_dir}/AndroidManifest.xml")
            fi
        fi
    done
    
    echo "${manifests[@]}"
}

android_get_res_dirs() {
    local -a res_dirs=()
    
    for dep_dir in "${ANDROID_DEPS_DIR}"/*; do
        if [[ -d "$dep_dir" ]] && [[ -d "${dep_dir}/res" ]]; then
            res_dirs+=("${dep_dir}/res")
        fi
    done
    
    echo "${res_dirs[@]}"
}

android_deps_list() {
    output_section "$(android_i18n_get "resolved_deps")"
    
    if [[ ${#ANDROID_RESOLVED_DEPS[@]} -eq 0 ]]; then
        output_info "$(android_i18n_get "no_deps_resolved")"
        return 0
    fi
    
    for dep in "${ANDROID_RESOLVED_DEPS[@]}"; do
        local path="${ANDROID_DEP_PATHS[$dep]}"
        output_bullet "$dep"
        [[ -n "$path" ]] && output_bullet "  -> $path" 2
    done
}

android_deps_clean() {
    if [[ -d "$ANDROID_DEPS_DIR" ]]; then
        output_info "$(android_i18n_get "cleaning_deps_dir")"
        rm -rf "$ANDROID_DEPS_DIR"
    fi
}

fi
