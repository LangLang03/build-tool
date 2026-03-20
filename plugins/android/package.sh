#!/usr/bin/env bash

if [[ -z "${_ANDROID_PACKAGE_LOADED:-}" ]]; then
_ANDROID_PACKAGE_LOADED=1

declare -g ANDROID_OUTPUT_DIR=""
declare -g ANDROID_APK_TEMP_DIR=""
declare -g ANDROID_UNSIGNED_APK=""
declare -g ANDROID_FINAL_APK=""

android_package_init() {
    ANDROID_OUTPUT_DIR="${ANDROID_BUILD_DIR}/output"
    ANDROID_APK_TEMP_DIR="${ANDROID_BUILD_DIR}/apk_temp"
    
    ensure_dir "$ANDROID_OUTPUT_DIR"
    
    local app_name="${PROJECT_NAME:-app}"
    local build_type="${ANDROID_BUILD_TYPE:-debug}"
    
    ANDROID_UNSIGNED_APK="${ANDROID_OUTPUT_DIR}/${app_name}-${build_type}-unsigned.apk"
    ANDROID_FINAL_APK="${ANDROID_OUTPUT_DIR}/${app_name}-${build_type}.apk"
}

android_package_apk() {
    output_section "$(android_i18n_get "packaging")"
    
    if ! command_exists zip; then
        output_error "$(android_i18n_get "zip_not_found")"
        if confirm_action "$(android_i18n_get "install_zip_prompt")"; then
            if platform_install zip; then
                output_success "$(android_i18n_get "zip_installed")"
            else
                output_error "$(android_i18n_get "zip_install_failed")"
                return 1
            fi
        else
            return 1
        fi
    fi
    
    android_package_init
    
    local resource_ap
    resource_ap=$(android_get_resource_ap)
    
    if [[ -z "$resource_ap" ]] || [[ ! -f "$resource_ap" ]]; then
        output_error "$(android_i18n_get "resources_not_compiled")"
        return 1
    fi
    
    local dex_count
    dex_count=$(android_count_dex_files)
    
    if [[ $dex_count -eq 0 ]]; then
        output_error "$(android_i18n_get "no_dex_files")"
        return 1
    fi
    
    rm -rf "$ANDROID_APK_TEMP_DIR"
    ensure_dir "$ANDROID_APK_TEMP_DIR"
    
    output_info "$(android_i18n_get "extracting_resources")"
    
    if ! unzip -q -o "$resource_ap" -d "$ANDROID_APK_TEMP_DIR"; then
        output_error "$(android_i18n_get "extract_resources_failed")"
        return 1
    fi
    
    output_info "$(android_i18n_get "copying") DEX files..."
    
    local dex_files
    dex_files=$(android_get_dex_files)
    
    for dex_file in $dex_files; do
        if [[ -f "$dex_file" ]]; then
            cp "$dex_file" "$ANDROID_APK_TEMP_DIR/"
        fi
    done
    
    local jni_libs_dir="${ANDROID_SOURCE_DIR}/jniLibs"
    if [[ -d "$jni_libs_dir" ]]; then
        output_info "$(android_i18n_get "copying") native libraries..."
        ensure_dir "${ANDROID_APK_TEMP_DIR}/lib"
        cp -r "$jni_libs_dir"/* "${ANDROID_APK_TEMP_DIR}/lib/" 2>/dev/null || true
    fi
    
    local assets_dir="${ANDROID_SOURCE_DIR}/assets"
    if [[ -d "$assets_dir" ]]; then
        output_info "$(android_i18n_get "copying") assets..."
        cp -r "$assets_dir" "${ANDROID_APK_TEMP_DIR}/assets" 2>/dev/null || true
    fi
    
    output_info "$(android_i18n_get "creating") APK..."
    
    rm -f "$ANDROID_UNSIGNED_APK"
    
    local unsigned_apk_abs
    unsigned_apk_abs=$(cd "$(dirname "$ANDROID_UNSIGNED_APK")" && pwd)/$(basename "$ANDROID_UNSIGNED_APK")
    
    local current_dir
    current_dir=$(pwd)
    cd "$ANDROID_APK_TEMP_DIR"
    
    if ! zip -q -r "$unsigned_apk_abs" .; then
        cd "$current_dir"
        output_error "$(android_i18n_get "package_failed")"
        return 1
    fi
    
    cd "$current_dir"
    
    rm -rf "$ANDROID_APK_TEMP_DIR"
    
    output_success "$(android_i18n_get "package_complete"): $ANDROID_UNSIGNED_APK"
    return 0
}

android_zipalign_apk() {
    local input_apk="$1"
    local output_apk="$2"
    
    local zipalign
    zipalign=$(android_get_zipalign) || return 1
    
    if [[ ! -f "$input_apk" ]]; then
        output_error "$(android_i18n_printf "input_apk_not_found" "$input_apk")"
        return 1
    fi
    
    output_debug "$(android_i18n_get "aligning_apk")"
    
    if "$zipalign" -f -v -p 4 "$input_apk" "$output_apk"; then
        return 0
    else
        output_error "$(android_i18n_get "zipalign_failed")"
        return 1
    fi
}

android_get_apk_size() {
    local apk_file="$1"
    
    if [[ -f "$apk_file" ]]; then
        local size
        size=$(stat -c%s "$apk_file" 2>/dev/null || stat -f%z "$apk_file" 2>/dev/null || echo "0")
        echo "$size"
    else
        echo "0"
    fi
}

android_format_apk_size() {
    local size="$1"
    
    if [[ $size -ge 1048576 ]]; then
        echo "$(echo "scale=2; $size / 1048576" | bc) MB"
    elif [[ $size -ge 1024 ]]; then
        echo "$(echo "scale=2; $size / 1024" | bc) KB"
    else
        echo "${size} B"
    fi
}

android_package_clean() {
    if [[ -d "$ANDROID_OUTPUT_DIR" ]]; then
        rm -rf "$ANDROID_OUTPUT_DIR"
    fi
    
    if [[ -d "$ANDROID_APK_TEMP_DIR" ]]; then
        rm -rf "$ANDROID_APK_TEMP_DIR"
    fi
}

android_get_output_apk() {
    if [[ -f "$ANDROID_FINAL_APK" ]]; then
        echo "$ANDROID_FINAL_APK"
        return 0
    fi
    
    return 1
}

fi
