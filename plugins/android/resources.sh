#!/usr/bin/env bash

if [[ -z "${_ANDROID_RESOURCES_LOADED:-}" ]]; then
_ANDROID_RESOURCES_LOADED=1

declare -g ANDROID_RES_DIR=""
declare -g ANDROID_COMPILED_RES_DIR=""
declare -g ANDROID_LINKED_RES_DIR=""
declare -g ANDROID_GENERATED_R_DIR=""
declare -g ANDROID_PROCESSED_MANIFEST=""

android_resources_init() {
    ANDROID_RES_DIR="${ANDROID_SOURCE_DIR}/res"
    ANDROID_COMPILED_RES_DIR="${ANDROID_BUILD_DIR}/compiled_res"
    ANDROID_LINKED_RES_DIR="${ANDROID_BUILD_DIR}/linked"
    ANDROID_GENERATED_R_DIR="${ANDROID_BUILD_DIR}/generated/r"
    ANDROID_PROCESSED_MANIFEST="${ANDROID_BUILD_DIR}/processed/AndroidManifest.xml"
    
    ensure_dir "$ANDROID_COMPILED_RES_DIR"
    ensure_dir "$ANDROID_LINKED_RES_DIR"
    ensure_dir "$ANDROID_GENERATED_R_DIR"
    ensure_dir "$(dirname "$ANDROID_PROCESSED_MANIFEST")"
}

android_process_manifest() {
    output_section "$(android_i18n_get "processing_manifest")"
    
    android_resources_init
    
    local manifest="${ANDROID_MANIFEST}"
    
    if [[ ! -f "$manifest" ]]; then
        output_error "$(android_i18n_printf "manifest_not_found_path" "$manifest")"
        return 1
    fi
    
    cp "$manifest" "$ANDROID_PROCESSED_MANIFEST"
    
    local has_uses_sdk
    has_uses_sdk=$(grep -c "<uses-sdk" "$ANDROID_PROCESSED_MANIFEST" 2>/dev/null || echo "0")
    
    if [[ "$has_uses_sdk" -eq 0 ]]; then
        local uses_sdk_tag="    <uses-sdk android:minSdkVersion=\"${ANDROID_MIN_SDK}\" android:targetSdkVersion=\"${ANDROID_TARGET_SDK}\" />"
        
        local temp_file="${ANDROID_PROCESSED_MANIFEST}.tmp"
        
        if grep -q "</application>" "$ANDROID_PROCESSED_MANIFEST"; then
            sed "s|</application>|${uses_sdk_tag}\n    </application>|" "$ANDROID_PROCESSED_MANIFEST" > "$temp_file"
            mv "$temp_file" "$ANDROID_PROCESSED_MANIFEST"
        else
            sed "s|</manifest>|${uses_sdk_tag}\n</manifest>|" "$ANDROID_PROCESSED_MANIFEST" > "$temp_file"
            mv "$temp_file" "$ANDROID_PROCESSED_MANIFEST"
        fi
        
        output_debug "$(android_i18n_printf "added_uses_sdk" "${ANDROID_MIN_SDK}" "${ANDROID_TARGET_SDK}")"
    else
        if command_exists xmlstarlet; then
            xmlstarlet ed -L \
                -u "//uses-sdk/@android:minSdkVersion" -v "${ANDROID_MIN_SDK}" \
                -u "//uses-sdk/@android:targetSdkVersion" -v "${ANDROID_TARGET_SDK}" \
                "$ANDROID_PROCESSED_MANIFEST" 2>/dev/null || true
        fi
        
        output_debug "$(android_i18n_get "updated_uses_sdk")"
    fi
    
    output_success "$(android_i18n_get "manifest_processed")"
    return 0
}

android_compile_single_resource() {
    local input_file="$1"
    local output_dir="$2"
    
    local aapt2
    aapt2=$(android_get_aapt2) || return 1
    
    local rel_path="${input_file#$ANDROID_RES_DIR/}"
    local dir_name="${rel_path%%/*}"
    local file_name="${rel_path#*/}"
    
    local output_file="${output_dir}/${dir_name}_${file_name//\//_}.flat"
    
    if ! "$aapt2" compile -o "$output_dir" "$input_file" 2>&1; then
        output_error "$(android_i18n_printf "failed_compile_resource" "$input_file")"
        return 1
    fi
    
    return 0
}

android_compile_resources() {
    output_section "$(android_i18n_get "resources_compiling")"
    
    if [[ ! -d "$ANDROID_RES_DIR" ]]; then
        android_resources_init
    fi
    
    if [[ ! -d "$ANDROID_RES_DIR" ]]; then
        output_warning "$(android_i18n_printf "res_dir_not_found" "$ANDROID_RES_DIR")"
        return 0
    fi
    
    local aapt2
    aapt2=$(android_get_aapt2) || return 1
    
    local -a resource_files=()
    while IFS= read -r -d '' file; do
        resource_files+=("$file")
    done < <(find "$ANDROID_RES_DIR" -type f \( \
        -name "*.xml" -o \
        -name "*.png" -o \
        -name "*.jpg" -o \
        -name "*.gif" -o \
        -name "*.webp" -o \
        -name "*.9.png" \
    \) -print0 2>/dev/null)
    
    local total=${#resource_files[@]}
    
    if [[ $total -eq 0 ]]; then
        output_warning "$(android_i18n_get "no_resource_files_found")"
        return 0
    fi
    
    output_info "$(android_i18n_get "resources_compiling"): $total files"
    
    output_progress_start $total
    
    local success=0
    local failed=0
    
    for res_file in "${resource_files[@]}"; do
        if "$aapt2" compile -o "$ANDROID_COMPILED_RES_DIR" "$res_file" 2>/dev/null; then
            ((success++))
        else
            output_debug "$(android_i18n_printf "failed_compile_resource" "$res_file")"
            ((failed++))
        fi
        output_progress_update
    done
    
    output_progress_end
    
    if [[ $failed -gt 0 ]]; then
        output_warning "$failed $(android_i18n_get "resources_failed")"
    fi
    
    output_success "$(android_i18n_get "resources_compiled"): $success files"
    return 0
}

android_link_resources() {
    output_section "$(android_i18n_get "linking_resources")"
    
    local aapt2
    aapt2=$(android_get_aapt2) || return 1
    
    local manifest="${ANDROID_PROCESSED_MANIFEST:-${ANDROID_MANIFEST}}"
    
    if [[ ! -f "$manifest" ]]; then
        output_error "$(android_i18n_printf "manifest_not_found_path" "$manifest")"
        return 1
    fi
    
    local android_jar
    android_jar=$(android_get_android_jar)
    
    if [[ -z "$android_jar" ]]; then
        output_error "$(android_i18n_printf "android_jar_not_found" "${ANDROID_COMPILE_SDK}")"
        return 1
    fi
    
    local -a flat_files=()
    while IFS= read -r -d '' file; do
        flat_files+=("$file")
    done < <(find "$ANDROID_COMPILED_RES_DIR" -name "*.flat" -print0 2>/dev/null)
    
    ensure_dir "$ANDROID_LINKED_RES_DIR"
    ensure_dir "$ANDROID_GENERATED_R_DIR"
    
    local output_ap="${ANDROID_LINKED_RES_DIR}/resources.ap_"
    
    local link_opts=(
        "link"
        "--manifest" "$manifest"
        "--java" "$ANDROID_GENERATED_R_DIR"
        "-o" "$output_ap"
        "-I" "$android_jar"
        "--auto-add-overlay"
        "--no-version-vectors"
    )
    
    if [[ ${#flat_files[@]} -gt 0 ]]; then
        link_opts+=("${flat_files[@]}")
    fi
    
    output_debug "$(android_i18n_get "linking_resources")"
    
    if ! "$aapt2" "${link_opts[@]}" 2>&1; then
        output_error "$(android_i18n_get "resource_link_failed")"
        return 1
    fi
    
    output_success "$(android_i18n_printf "resources_linked" "$output_ap")"
    
    local r_java_files=()
    while IFS= read -r -d '' file; do
        r_java_files+=("$file")
    done < <(find "$ANDROID_GENERATED_R_DIR" -name "R.java" -print0 2>/dev/null)
    
    if [[ ${#r_java_files[@]} -gt 0 ]]; then
        output_success "$(android_i18n_printf "generated_r_java" "${#r_java_files[@]}")"
    fi
    
    return 0
}

android_merge_resources() {
    local output_dir="$1"
    
    local -a dep_res_dirs
    read -ra dep_res_dirs <<< "$(android_get_res_dirs)"
    
    if [[ ${#dep_res_dirs[@]} -eq 0 ]]; then
        return 0
    fi
    
    output_debug "$(android_i18n_get "merging_dep_resources")"
    
    for res_dir in "${dep_res_dirs[@]}"; do
        if [[ -d "$res_dir" ]]; then
            output_debug "$(android_i18n_printf "merging" "$res_dir")"
        fi
    done
    
    return 0
}

android_get_resource_ap() {
    local ap_file="${ANDROID_LINKED_RES_DIR}/resources.ap_"
    
    if [[ -f "$ap_file" ]]; then
        echo "$ap_file"
        return 0
    fi
    
    return 1
}

android_get_r_java_dir() {
    if [[ -d "$ANDROID_GENERATED_R_DIR" ]]; then
        echo "$ANDROID_GENERATED_R_DIR"
        return 0
    fi
    
    return 1
}

android_resources_clean() {
    if [[ -d "$ANDROID_COMPILED_RES_DIR" ]]; then
        rm -rf "$ANDROID_COMPILED_RES_DIR"
    fi
    
    if [[ -d "$ANDROID_LINKED_RES_DIR" ]]; then
        rm -rf "$ANDROID_LINKED_RES_DIR"
    fi
    
    if [[ -d "$ANDROID_GENERATED_R_DIR" ]]; then
        rm -rf "$ANDROID_GENERATED_R_DIR"
    fi
}

android_process_resources() {
    android_process_manifest || return 1
    android_compile_resources || return 1
    android_link_resources || return 1
    return 0
}

fi
