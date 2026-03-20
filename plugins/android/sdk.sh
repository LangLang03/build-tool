#!/usr/bin/env bash

if [[ -z "${_ANDROID_SDK_LOADED:-}" ]]; then
_ANDROID_SDK_LOADED=1

declare -g ANDROID_SDK_ROOT=""
declare -g ANDROID_SDK_VALID=false
declare -g ANDROID_SDK_DETECTED=false

declare -g ANDROID_COMPILE_SDK="${ANDROID_COMPILE_SDK:-34}"
declare -g ANDROID_BUILD_TOOLS="${ANDROID_BUILD_TOOLS:-34.0.0}"
declare -g ANDROID_MIN_SDK="${ANDROID_MIN_SDK:-21}"
declare -g ANDROID_TARGET_SDK="${ANDROID_TARGET_SDK:-34}"

declare -gA ANDROID_CMDLINE_TOOLS_URLS=(
    ["linux-x86_64"]="https://googledownloads.cn/android/repository/commandlinetools-linux-14742923_latest.zip"
    ["linux-aarch64"]="https://googledownloads.cn/android/repository/commandlinetools-linux-14742923_latest.zip"
    ["macos-x86_64"]="https://googledownloads.cn/android/repository/commandlinetools-mac-14742923_latest.zip"
    ["macos-aarch64"]="https://googledownloads.cn/android/repository/commandlinetools-mac-14742923_latest.zip"
    ["windows-x86_64"]="https://googledownloads.cn/android/repository/commandlinetools-win-14742923_latest.zip"
)

android_detect_sdk() {
    if [[ "$ANDROID_SDK_DETECTED" == "true" ]]; then
        return 0
    fi
    
    output_debug "$(android_i18n_get "sdk_validating")"
    
    if [[ -n "${ANDROID_HOME:-}" ]] && [[ -d "${ANDROID_HOME:-}" ]]; then
        ANDROID_SDK_ROOT="$ANDROID_HOME"
    elif [[ -n "${ANDROID_SDK_ROOT:-}" ]] && [[ -d "${ANDROID_SDK_ROOT:-}" ]]; then
        : 
    else
        case "$PLATFORM_OS" in
            linux)
                local default="$HOME/Android/Sdk"
                ;;
            macos)
                local default="$HOME/Library/Android/sdk"
                ;;
            windows)
                local default="${LOCALAPPDATA:-${HOME}/AppData/Local}/Android/Sdk"
                ;;
            *)
                local default=""
                ;;
        esac
        
        if [[ -n "$default" ]] && [[ -d "$default" ]]; then
            ANDROID_SDK_ROOT="$default"
        fi
    fi
    
    if [[ -n "$ANDROID_SDK_ROOT" ]] && [[ -d "$ANDROID_SDK_ROOT" ]]; then
        if android_validate_sdk; then
            ANDROID_SDK_VALID=true
            ANDROID_SDK_DETECTED=true
            output_debug "$(android_i18n_get "sdk_found"): $ANDROID_SDK_ROOT"
            return 0
        fi
    fi
    
    output_debug "$(android_i18n_get "sdk_not_found")"
    return 1
}

android_validate_sdk() {
    [[ -n "$ANDROID_SDK_ROOT" ]] && \
    [[ -d "$ANDROID_SDK_ROOT" ]] && \
    [[ -d "$ANDROID_SDK_ROOT/build-tools" ]] && \
    [[ -d "$ANDROID_SDK_ROOT/platforms" ]] && \
    [[ -d "$ANDROID_SDK_ROOT/platform-tools" ]]
}

android_ensure_sdk() {
    if android_detect_sdk; then
        return 0
    fi
    
    output_warning "$(android_i18n_get "sdk_not_found")"
    
    if confirm_action "$(android_i18n_get "setup_prompt")"; then
        android_setup_sdk
        return $?
    fi
    
    return 1
}

android_get_sdkmanager() {
    local sdkmanager="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager"
    
    if [[ -f "$sdkmanager" ]]; then
        echo "$sdkmanager"
        return 0
    fi
    
    sdkmanager="${ANDROID_SDK_ROOT}/cmdline-tools/bin/sdkmanager"
    if [[ -f "$sdkmanager" ]]; then
        echo "$sdkmanager"
        return 0
    fi
    
    return 1
}

android_check_build_tools() {
    local version="${1:-$ANDROID_BUILD_TOOLS}"
    local build_tools_dir="${ANDROID_SDK_ROOT}/build-tools/${version}"
    
    if [[ -d "$build_tools_dir" ]]; then
        output_debug "$(android_i18n_get "build_tools_found"): $version"
        return 0
    fi
    
    output_debug "$(android_i18n_get "build_tools_not_found"): $version"
    return 1
}

android_check_platform() {
    local version="${1:-$ANDROID_COMPILE_SDK}"
    local platform_dir="${ANDROID_SDK_ROOT}/platforms/android-${version}"
    
    if [[ -d "$platform_dir" ]]; then
        output_debug "$(android_i18n_get "platform_found"): $version"
        return 0
    fi
    
    output_debug "$(android_i18n_get "platform_not_found"): $version"
    return 1
}

android_check_cmdline_tools() {
    local sdkmanager
    sdkmanager=$(android_get_sdkmanager)
    
    if [[ -n "$sdkmanager" ]]; then
        output_debug "$(android_i18n_get "cmdline_tools_found")"
        return 0
    fi
    
    output_debug "$(android_i18n_get "cmdline_tools_not_found")"
    return 1
}

android_get_tool() {
    local tool_name="$1"
    local version="${2:-$ANDROID_BUILD_TOOLS}"
    
    local tool_path="${ANDROID_SDK_ROOT}/build-tools/${version}/${tool_name}"
    
    if [[ -f "$tool_path" ]]; then
        echo "$tool_path"
        return 0
    fi
    
    tool_path="${ANDROID_SDK_ROOT}/build-tools/${version}/${tool_name}.bat"
    if [[ -f "$tool_path" ]]; then
        echo "$tool_path"
        return 0
    fi
    
    return 1
}

android_get_aapt2() {
    android_get_tool "aapt2"
}

android_get_d8() {
    android_get_tool "d8"
}

android_get_zipalign() {
    android_get_tool "zipalign"
}

android_get_apksigner() {
    android_get_tool "apksigner"
}

android_get_android_jar() {
    local version="${1:-$ANDROID_COMPILE_SDK}"
    local jar_path="${ANDROID_SDK_ROOT}/platforms/android-${version}/android.jar"
    
    if [[ -f "$jar_path" ]]; then
        echo "$jar_path"
        return 0
    fi
    
    return 1
}

android_download_cmdline_tools() {
    local platform_key="${PLATFORM_OS}-${PLATFORM_ARCH}"
    local url="${ANDROID_CMDLINE_TOOLS_URLS[$platform_key]}"
    
    if [[ -z "$url" ]]; then
        output_error "$(android_i18n_printf "unsupported_platform" "$platform_key")"
        return 1
    fi
    
    output_section "$(android_i18n_get "downloading_cmdline_tools")"
    
    local temp_dir
    temp_dir=$(mktemp -d 2>/dev/null || echo "${TEMP:-/tmp}/android-cmdline-$$")
    ensure_dir "$temp_dir"
    
    local zip_file="${temp_dir}/cmdline-tools.zip"
    
    output_info "$(android_i18n_get "downloading")..."
    
    local download_cmd
    local progress_flag="-#"
    if command_exists curl; then
        download_cmd="curl ${progress_flag}fsSL -o"
    elif command_exists wget; then
        download_cmd="wget -q --show-progress -O"
    else
        output_error "$(android_i18n_get "download_failed"): curl or wget required"
        rm -rf "$temp_dir"
        return 1
    fi
    
    if ! $download_cmd "$zip_file" "$url"; then
        output_error "$(android_i18n_get "download_failed")"
        rm -rf "$temp_dir"
        return 1
    fi
    
    output_success "$(android_i18n_get "download_success")"
    
    local sdk_dir="${ANDROID_SDK_ROOT:-${HOME}/Android/Sdk}"
    
    if [[ ! -d "$sdk_dir" ]]; then
        output_info "$(android_i18n_get "creating_sdk_dir")"
        ensure_dir "$sdk_dir"
    fi
    
    output_info "$(android_i18n_get "extracting_cmdline_tools")..."
    
    ensure_dir "${sdk_dir}/cmdline-tools"
    
    if ! unzip -q "$zip_file" -d "${sdk_dir}/cmdline-tools" 2>/dev/null; then
        output_error "$(android_i18n_get "extract_failed")"
        rm -rf "$temp_dir"
        return 1
    fi
    
    if [[ -d "${sdk_dir}/cmdline-tools/cmdline-tools" ]]; then
        mv "${sdk_dir}/cmdline-tools/cmdline-tools" "${sdk_dir}/cmdline-tools/latest"
    fi
    
    if [[ "$PLATFORM_OS" != "windows" ]]; then
        chmod +x "${sdk_dir}/cmdline-tools/latest/bin/"* 2>/dev/null
    fi
    
    rm -rf "$temp_dir"
    
    ANDROID_SDK_ROOT="$sdk_dir"
    export ANDROID_SDK_ROOT
    export ANDROID_HOME="$sdk_dir"
    
    output_success "$(android_i18n_get "extracting") $(android_i18n_get "ok")"
    return 0
}

android_install_sdk_component() {
    local component="$1"
    
    local sdkmanager
    sdkmanager=$(android_get_sdkmanager)
    
    if [[ -z "$sdkmanager" ]]; then
        if ! android_download_cmdline_tools; then
            return 1
        fi
        sdkmanager=$(android_get_sdkmanager)
    fi
    
    if [[ -z "$sdkmanager" ]]; then
        output_error "$(android_i18n_get "cmdline_tools_not_found")"
        return 1
    fi
    
    output_info "$(android_i18n_get "installing_sdk_component"): $component"
    
    export JAVA_HOME="${JAVA_HOME:-}"
    
    if [[ "$PLATFORM_OS" == "windows" ]]; then
        local sdkmanager_cmd="$sdkmanager"
    else
        local sdkmanager_cmd="$sdkmanager"
    fi
    
    yes 2>/dev/null | "$sdkmanager_cmd" --licenses 2>/dev/null || true
    
    if "$sdkmanager_cmd" "$component" 2>&1; then
        output_success "$(android_i18n_get "install_success"): $component"
        return 0
    else
        output_error "$(android_i18n_get "install_failed"): $component"
        return 1
    fi
}

android_install_build_tools() {
    local version="${1:-$ANDROID_BUILD_TOOLS}"
    android_install_sdk_component "build-tools;${version}"
}

android_install_platform() {
    local version="${1:-$ANDROID_COMPILE_SDK}"
    android_install_sdk_component "platforms;android-${version}"
}

android_install_platform_tools() {
    android_install_sdk_component "platform-tools"
}

android_install_all_required() {
    local -a components=()
    
    if ! android_check_build_tools; then
        components+=("build-tools;${ANDROID_BUILD_TOOLS}")
    fi
    
    if ! android_check_platform; then
        components+=("platforms;android-${ANDROID_COMPILE_SDK}")
    fi
    
    if [[ ! -d "${ANDROID_SDK_ROOT}/platform-tools" ]]; then
        components+=("platform-tools")
    fi
    
    if [[ ${#components[@]} -eq 0 ]]; then
        output_info "$(android_i18n_get "check_passed")"
        return 0
    fi
    
    output_section "$(android_i18n_get "missing_components")"
    
    for component in "${components[@]}"; do
        output_bullet "$component"
    done
    
    for component in "${components[@]}"; do
        android_install_sdk_component "$component" || return 1
    done
    
    return 0
}

android_setup_sdk() {
    local sdk_dir="${1:-${HOME}/Android/Sdk}"
    
    output_section "$(android_i18n_get "setting_up_env")"
    
    if [[ ! -d "$sdk_dir" ]]; then
        output_info "$(android_i18n_get "creating_sdk_dir")"
        ensure_dir "$sdk_dir"
    fi
    
    ANDROID_SDK_ROOT="$sdk_dir"
    export ANDROID_SDK_ROOT
    export ANDROID_HOME="$sdk_dir"
    
    if ! android_check_cmdline_tools; then
        if ! android_download_cmdline_tools; then
            return 1
        fi
    fi
    
    if ! android_install_all_required; then
        return 1
    fi
    
    android_setup_env_vars
    
    output_success "$(android_i18n_get "setup_complete")"
    return 0
}

android_setup_env_vars() {
    local sdk_dir="${ANDROID_SDK_ROOT}"
    
    local rc_file
    case "${SHELL##*/}" in
        bash) rc_file="$HOME/.bashrc" ;;
        zsh)  rc_file="$HOME/.zshrc" ;;
        *)    rc_file="$HOME/.profile" ;;
    esac
    
    if grep -q "ANDROID_HOME" "$rc_file" 2>/dev/null; then
        output_debug "Environment variables already configured in $rc_file"
        return 0
    fi
    
    {
        echo ""
        echo "# Android SDK (added by build-tool)"
        echo "export ANDROID_HOME=\"${sdk_dir}\""
        echo "export ANDROID_SDK_ROOT=\"${sdk_dir}\""
        echo "export PATH=\"\${ANDROID_HOME}/cmdline-tools/latest/bin:\${PATH}\""
        echo "export PATH=\"\${ANDROID_HOME}/platform-tools:\${PATH}\""
        echo "export PATH=\"\${ANDROID_HOME}/emulator:\${PATH}\""
    } >> "$rc_file"
    
    output_info "$(android_i18n_get "env_added_to"): $rc_file"
    output_info "$(android_i18n_printf "please_source" "$rc_file")"
}

android_get_sdk_info() {
    echo "Android SDK Information"
    echo "  SDK Root:     ${ANDROID_SDK_ROOT:-not set}"
    echo "  Compile SDK:  ${ANDROID_COMPILE_SDK}"
    echo "  Build Tools:  ${ANDROID_BUILD_TOOLS}"
    echo "  Min SDK:      ${ANDROID_MIN_SDK}"
    echo "  Target SDK:   ${ANDROID_TARGET_SDK}"
}

fi
