#!/usr/bin/env bash

if [[ -z "${_ANDROID_COMPILE_LOADED:-}" ]]; then
_ANDROID_COMPILE_LOADED=1

declare -g ANDROID_CLASSES_DIR=""
declare -g ANDROID_JAVA_SOURCE_DIR=""
declare -g ANDROID_KOTLIN_SOURCE_DIR=""

android_compile_init() {
    ANDROID_CLASSES_DIR="${ANDROID_BUILD_DIR}/classes"
    ANDROID_JAVA_SOURCE_DIR="${ANDROID_SOURCE_DIR}/java"
    ANDROID_KOTLIN_SOURCE_DIR="${ANDROID_SOURCE_DIR}/kotlin"
    
    ensure_dir "$ANDROID_CLASSES_DIR"
}

android_get_javac() {
    if [[ -n "${JAVA_HOME:-}" ]] && [[ -f "${JAVA_HOME}/bin/javac" ]]; then
        echo "${JAVA_HOME}/bin/javac"
        return 0
    fi
    
    if command_exists javac; then
        command -v javac
        return 0
    fi
    
    return 1
}

android_get_kotlinc() {
    if command_exists kotlinc; then
        command -v kotlinc
        return 0
    fi
    
    return 1
}

android_build_classpath() {
    local cp=""
    
    local android_jar
    android_jar=$(android_get_android_jar)
    
    if [[ -n "$android_jar" ]]; then
        cp="$android_jar"
    fi
    
    local r_java_dir
    r_java_dir=$(android_get_r_java_dir)
    
    if [[ -n "$r_java_dir" ]] && [[ -d "$r_java_dir" ]]; then
        local r_java_file
        r_java_file=$(find "$r_java_dir" -name "R.java" | head -1)
        if [[ -n "$r_java_file" ]]; then
            local r_java_dir_path
            r_java_dir_path=$(dirname "$r_java_file")
            [[ -n "$cp" ]] && cp="${cp}:"
            cp="${cp}${r_java_dir_path}"
        fi
    fi
    
    local dep_cp
    dep_cp=$(android_get_classpath)
    
    if [[ -n "$dep_cp" ]]; then
        [[ -n "$cp" ]] && cp="${cp}:"
        cp="${cp}${dep_cp}"
    fi
    
    echo "$cp"
}

android_compile_java() {
    output_section "$(android_i18n_get "java_compiling")"
    
    android_compile_init
    
    local javac
    javac=$(android_get_javac)
    
    if [[ -z "$javac" ]]; then
        output_error "$(android_i18n_get "javac_not_found")"
        return 1
    fi
    
    local -a java_files=()
    
    if [[ -d "$ANDROID_JAVA_SOURCE_DIR" ]]; then
        while IFS= read -r -d '' file; do
            java_files+=("$file")
        done < <(find "$ANDROID_JAVA_SOURCE_DIR" -name "*.java" -print0 2>/dev/null)
    fi
    
    local r_java_dir
    r_java_dir=$(android_get_r_java_dir)
    
    if [[ -n "$r_java_dir" ]] && [[ -d "$r_java_dir" ]]; then
        while IFS= read -r -d '' file; do
            java_files+=("$file")
        done < <(find "$r_java_dir" -name "*.java" -print0 2>/dev/null)
    fi
    
    local total=${#java_files[@]}
    
    if [[ $total -eq 0 ]]; then
        output_warning "$(android_i18n_get "no_java_sources_found")"
        return 0
    fi
    
    output_info "$(android_i18n_printf "compiling_files" "$total")"
    
    local classpath
    classpath=$(android_build_classpath)
    
    local java_opts="${ANDROID_JAVA_OPTS:-}"
    local java_source="${ANDROID_JAVA_SOURCE:-11}"
    local java_target="${ANDROID_JAVA_TARGET:-11}"
    
    local javac_opts=(
        "-source" "$java_source"
        "-target" "$java_target"
        "-d" "$ANDROID_CLASSES_DIR"
    )
    
    if [[ -n "$classpath" ]]; then
        javac_opts+=("-cp" "$classpath")
    fi
    
    if [[ -n "$java_opts" ]]; then
        javac_opts+=($java_opts)
    fi
    
    javac_opts+=("-encoding" "UTF-8")
    
    output_progress_start $total
    
    local success=0
    local failed=0
    local batch_size=100
    local -a batch=()
    
    for java_file in "${java_files[@]}"; do
        batch+=("$java_file")
        
        if [[ ${#batch[@]} -ge $batch_size ]]; then
            if "$javac" "${javac_opts[@]}" "${batch[@]}" 2>&1; then
                ((success += ${#batch[@]}))
            else
                ((failed += ${#batch[@]}))
            fi
            batch=()
        fi
        
        output_progress_update
    done
    
    if [[ ${#batch[@]} -gt 0 ]]; then
        if "$javac" "${javac_opts[@]}" "${batch[@]}" 2>&1; then
            ((success += ${#batch[@]}))
        else
            ((failed += ${#batch[@]}))
        fi
    fi
    
    output_progress_end
    
    if [[ $failed -gt 0 ]]; then
        output_error "$failed $(android_i18n_get "compile_failed")"
        return 1
    fi
    
    output_success "$(android_i18n_printf "compile_success_files" "$success")"
    return 0
}

android_compile_kotlin() {
    output_section "$(android_i18n_get "kotlin_compiling")"
    
    if [[ "${ANDROID_KOTLIN_ENABLED:-false}" != "true" ]]; then
        output_debug "$(android_i18n_get "kotlin_compilation_disabled")"
        return 0
    fi
    
    local kotlinc
    kotlinc=$(android_get_kotlinc)
    
    if [[ -z "$kotlinc" ]]; then
        output_warning "$(android_i18n_get "kotlinc_not_found_skip")"
        return 0
    fi
    
    android_compile_init
    
    local -a kotlin_files=()
    
    if [[ -d "$ANDROID_KOTLIN_SOURCE_DIR" ]]; then
        while IFS= read -r -d '' file; do
            kotlin_files+=("$file")
        done < <(find "$ANDROID_KOTLIN_SOURCE_DIR" -name "*.kt" -print0 2>/dev/null)
    fi
    
    local total=${#kotlin_files[@]}
    
    if [[ $total -eq 0 ]]; then
        output_debug "$(android_i18n_get "no_kotlin_sources_found")"
        return 0
    fi
    
    output_info "$(android_i18n_printf "compiling_files" "$total")"
    
    local classpath
    classpath=$(android_build_classpath)
    
    local kotlin_opts="${ANDROID_KOTLIN_OPTS:-}"
    
    local kotlinc_opts=(
        "-d" "$ANDROID_CLASSES_DIR"
    )
    
    if [[ -n "$classpath" ]]; then
        kotlinc_opts+=("-cp" "$classpath")
    fi
    
    if [[ -n "$kotlin_opts" ]]; then
        kotlinc_opts+=($kotlin_opts)
    fi
    
    if "$kotlinc" "${kotlinc_opts[@]}" "${kotlin_files[@]}" 2>&1; then
        output_success "$(android_i18n_printf "compile_kotlin_success" "$total")"
        return 0
    else
        output_error "$(android_i18n_get "compile_failed")"
        return 1
    fi
}

android_compile_all() {
    android_compile_java || return 1
    android_compile_kotlin || return 1
    return 0
}

android_compile_clean() {
    if [[ -d "$ANDROID_CLASSES_DIR" ]]; then
        rm -rf "$ANDROID_CLASSES_DIR"
    fi
}

android_get_classes_dir() {
    if [[ -d "$ANDROID_CLASSES_DIR" ]]; then
        echo "$ANDROID_CLASSES_DIR"
        return 0
    fi
    
    return 1
}

android_count_class_files() {
    local count=0
    
    if [[ -d "$ANDROID_CLASSES_DIR" ]]; then
        count=$(find "$ANDROID_CLASSES_DIR" -name "*.class" | wc -l)
    fi
    
    echo "$count"
}

fi
