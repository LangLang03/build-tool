#!/usr/bin/env bash

if [[ -z "${_ANDROID_DEX_LOADED:-}" ]]; then
_ANDROID_DEX_LOADED=1

declare -g ANDROID_DEX_DIR=""

android_dex_init() {
    ANDROID_DEX_DIR="${ANDROID_BUILD_DIR}/dex"
    ensure_dir "$ANDROID_DEX_DIR"
}

android_get_d8() {
    local d8="${ANDROID_SDK_ROOT}/build-tools/${ANDROID_BUILD_TOOLS}/d8"
    
    if [[ -f "$d8" ]]; then
        echo "$d8"
        return 0
    fi
    
    if [[ "$PLATFORM_OS" == "windows" ]]; then
        d8="${d8}.bat"
        if [[ -f "$d8" ]]; then
            echo "$d8"
            return 0
        fi
    fi
    
    output_error "$(android_i18n_printf "tool_not_found" "d8" "$ANDROID_BUILD_TOOLS")"
    return 1
}

android_dex_classes() {
    output_section "$(android_i18n_get "dex_converting")"
    
    android_dex_init
    
    local d8
    d8=$(android_get_d8) || return 1
    
    if [[ ! -d "$ANDROID_CLASSES_DIR" ]]; then
        output_error "$(android_i18n_printf "classes_dir_not_found" "$ANDROID_CLASSES_DIR")"
        return 1
    fi
    
    local class_count
    class_count=$(android_count_class_files)
    
    if [[ $class_count -eq 0 ]]; then
        output_warning "$(android_i18n_get "no_class_files")"
        return 0
    fi
    
    output_info "$(android_i18n_get "dex_converting"): $class_count class files"
    
    local android_jar
    android_jar=$(android_get_android_jar)
    
    local d8_opts=(
        "--lib" "$android_jar"
        "--output" "$ANDROID_DEX_DIR"
        "--min-api" "${ANDROID_MIN_SDK}"
    )
    
    local -a inputs=()
    
    inputs+=("$ANDROID_CLASSES_DIR")
    
    local jar_files
    jar_files=$(android_get_jar_files)
    
    for jar in $jar_files; do
        if [[ -f "$jar" ]]; then
            inputs+=("$jar")
        fi
    done
    
    output_debug "Running d8 with ${#inputs[@]} inputs"
    
    if "$d8" "${d8_opts[@]}" "${inputs[@]}" 2>&1; then
        output_success "$(android_i18n_get "dex_complete")"
        return 0
    else
        output_error "$(android_i18n_get "dex_failed")"
        return 1
    fi
}

android_dex_jar() {
    local jar_file="$1"
    local output_dir="${2:-$ANDROID_DEX_DIR}"
    
    local d8
    d8=$(android_get_d8) || return 1
    
    if [[ ! -f "$jar_file" ]]; then
        output_error "$(android_i18n_printf "jar_not_found" "$jar_file")"
        return 1
    fi
    
    ensure_dir "$output_dir"
    
    local android_jar
    android_jar=$(android_get_android_jar)
    
    local d8_opts=(
        "--lib" "$android_jar"
        "--output" "$output_dir"
        "--min-api" "${ANDROID_MIN_SDK}"
    )
    
    if "$d8" "${d8_opts[@]}" "$jar_file" 2>&1; then
        return 0
    else
        return 1
    fi
}

android_get_dex_files() {
    local -a dex_files=()
    
    if [[ -d "$ANDROID_DEX_DIR" ]]; then
        while IFS= read -r -d '' file; do
            dex_files+=("$file")
        done < <(find "$ANDROID_DEX_DIR" -name "*.dex" -print0 2>/dev/null)
    fi
    
    echo "${dex_files[@]}"
}

android_count_dex_files() {
    local count=0
    
    if [[ -d "$ANDROID_DEX_DIR" ]]; then
        count=$(find "$ANDROID_DEX_DIR" -name "*.dex" | wc -l)
    fi
    
    echo "$count"
}

android_dex_clean() {
    if [[ -d "$ANDROID_DEX_DIR" ]]; then
        rm -rf "$ANDROID_DEX_DIR"
    fi
}

fi
