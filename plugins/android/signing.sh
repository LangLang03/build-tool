#!/usr/bin/env bash

if [[ -z "${_ANDROID_SIGNING_LOADED:-}" ]]; then
_ANDROID_SIGNING_LOADED=1

declare -g ANDROID_DEBUG_KEYSTORE=""
declare -g ANDROID_RELEASE_KEYSTORE=""

android_signing_init() {
    ANDROID_DEBUG_KEYSTORE="${ANDROID_BUILD_DIR}/debug.keystore"
    ANDROID_RELEASE_KEYSTORE="${ANDROID_BUILD_DIR}/release.keystore"
}

android_get_apksigner() {
    local apksigner="${ANDROID_SDK_ROOT}/build-tools/${ANDROID_BUILD_TOOLS}/apksigner"
    
    if [[ -f "$apksigner" ]]; then
        echo "$apksigner"
        return 0
    fi
    
    if [[ "$PLATFORM_OS" == "windows" ]]; then
        apksigner="${apksigner}.bat"
        if [[ -f "$apksigner" ]]; then
            echo "$apksigner"
            return 0
        fi
    fi
    
    output_error "$(android_i18n_printf "apksigner_not_found" "$ANDROID_BUILD_TOOLS")"
    return 1
}

android_get_keytool() {
    if [[ -n "${JAVA_HOME:-}" ]] && [[ -f "${JAVA_HOME}/bin/keytool" ]]; then
        echo "${JAVA_HOME}/bin/keytool"
        return 0
    fi
    
    if command_exists keytool; then
        command -v keytool
        return 0
    fi
    
    return 1
}

android_create_debug_keystore() {
    android_signing_init
    
    if [[ -f "$ANDROID_DEBUG_KEYSTORE" ]]; then
        output_debug "$(android_i18n_get "debug_keystore_exists")"
        return 0
    fi
    
    local keytool
    keytool=$(android_get_keytool)
    
    if [[ -z "$keytool" ]]; then
        output_error "$(android_i18n_get "keytool_not_found")"
        return 1
    fi
    
    output_info "$(android_i18n_get "creating_debug_keystore")"
    
    ensure_dir "$(dirname "$ANDROID_DEBUG_KEYSTORE")"
    
    "$keytool" \
        -genkey \
        -v \
        -keystore "$ANDROID_DEBUG_KEYSTORE" \
        -storepass "android" \
        -alias "androiddebugkey" \
        -keypass "android" \
        -keyalg "RSA" \
        -keysize 2048 \
        -validity 10000 \
        -dname "CN=Android Debug,O=Android,C=US" \
        2>/dev/null
    
    if [[ -f "$ANDROID_DEBUG_KEYSTORE" ]]; then
        output_success "$(android_i18n_get "debug_keystore_created")"
        return 0
    else
        output_error "$(android_i18n_get "debug_keystore_failed")"
        return 1
    fi
}

android_sign_apk() {
    local input_apk="$1"
    local output_apk="$2"
    local keystore="$3"
    local store_pass="$4"
    local key_alias="$5"
    local key_pass="$6"
    
    output_section "$(android_i18n_get "signing")"
    
    local apksigner
    apksigner=$(android_get_apksigner) || return 1
    
    if [[ ! -f "$input_apk" ]]; then
        output_error "$(android_i18n_printf "input_apk_not_found" "$input_apk")"
        return 1
    fi
    
    if [[ ! -f "$keystore" ]]; then
        output_error "$(android_i18n_printf "keystore_not_found" "$keystore")"
        return 1
    fi
    
    output_info "$(android_i18n_get "signing"): $(basename "$input_apk")"
    
    local sign_opts=(
        "sign"
        "--ks" "$keystore"
        "--ks-pass" "pass:$store_pass"
        "--ks-key-alias" "$key_alias"
        "--key-pass" "pass:$key_pass"
        "--out" "$output_apk"
        "$input_apk"
    )
    
    if "$apksigner" "${sign_opts[@]}" 2>&1; then
        output_success "$(android_i18n_get "sign_complete")"
        return 0
    else
        output_error "$(android_i18n_get "sign_failed")"
        return 1
    fi
}

android_sign_debug() {
    local input_apk="$1"
    local output_apk="${2:-${ANDROID_OUTPUT_DIR}/${PROJECT_NAME}-debug.apk}"
    
    android_signing_init
    
    if [[ ! -f "$ANDROID_DEBUG_KEYSTORE" ]]; then
        if ! android_create_debug_keystore; then
            return 1
        fi
    fi
    
    android_sign_apk \
        "$input_apk" \
        "$output_apk" \
        "$ANDROID_DEBUG_KEYSTORE" \
        "android" \
        "androiddebugkey" \
        "android"
    
    return $?
}

android_sign_release() {
    local input_apk="$1"
    local output_apk="${2:-${ANDROID_OUTPUT_DIR}/${PROJECT_NAME}-release.apk}"
    local keystore="${ANDROID_SIGNING_RELEASE[store_file]:-}"
    local store_pass="${ANDROID_SIGNING_RELEASE[store_password]:-}"
    local key_alias="${ANDROID_SIGNING_RELEASE[key_alias]:-}"
    local key_pass="${ANDROID_SIGNING_RELEASE[key_password]:-}"
    
    if [[ -z "$keystore" ]] || [[ ! -f "$keystore" ]]; then
        output_error "$(android_i18n_get "release_keystore_not_configured")"
        output_info "$(android_i18n_get "configure_signing_yaml")"
        output_info "  android.signing.release.store_file: path/to/keystore"
        output_info "  android.signing.release.store_password: password"
        output_info "  android.signing.release.key_alias: alias"
        output_info "  android.signing.release.key_password: key_password"
        return 1
    fi
    
    android_sign_apk \
        "$input_apk" \
        "$output_apk" \
        "$keystore" \
        "$store_pass" \
        "$key_alias" \
        "$key_pass"
    
    return $?
}

android_verify_apk() {
    local apk_file="$1"
    
    local apksigner
    apksigner=$(android_get_apksigner) || return 1
    
    if [[ ! -f "$apk_file" ]]; then
        output_error "$(android_i18n_printf "apk_not_found_path" "$apk_file")"
        return 1
    fi
    
    output_info "$(android_i18n_get "verifying_signature")"
    
    if "$apksigner" verify "$apk_file" 2>&1; then
        output_success "$(android_i18n_get "signature_verified")"
        return 0
    else
        output_error "$(android_i18n_get "signature_failed")"
        return 1
    fi
}

android_get_apk_info() {
    local apk_file="$1"
    
    if [[ ! -f "$apk_file" ]]; then
        output_error "$(android_i18n_printf "apk_not_found_path" "$apk_file")"
        return 1
    fi
    
    local size
    size=$(android_get_apk_size "$apk_file")
    local size_formatted
    size_formatted=$(android_format_apk_size "$size")
    
    echo "$(android_i18n_get "apk_info_header")"
    echo "  $(android_i18n_get "apk_info_path"): $apk_file"
    echo "  $(android_i18n_get "apk_info_size"): $size_formatted"
    
    local apksigner
    apksigner=$(android_get_apksigner 2>/dev/null)
    
    if [[ -n "$apksigner" ]]; then
        echo "  $(android_i18n_get "apk_info_signature"):"
        "$apksigner" verify --print-certs "$apk_file" 2>/dev/null | head -5
    fi
}

android_signing_clean() {
    if [[ -f "$ANDROID_DEBUG_KEYSTORE" ]]; then
        rm -f "$ANDROID_DEBUG_KEYSTORE"
    fi
}

fi
