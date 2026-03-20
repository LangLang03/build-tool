#!/usr/bin/env bash

if [[ -z "${_ANDROID_TOOLS_LOADED:-}" ]]; then
_ANDROID_TOOLS_LOADED=1

declare -gA ANDROID_TOOLS_STATUS=()
declare -gA ANDROID_TOOLS_INSTALLABLE=()

android_tools_init() {
    ANDROID_TOOLS_STATUS=()
    ANDROID_TOOLS_INSTALLABLE=()
    
    ANDROID_TOOLS_INSTALLABLE["xmlstarlet"]="xmlstarlet"
    ANDROID_TOOLS_INSTALLABLE["xmllint"]="libxml2-utils"
    ANDROID_TOOLS_INSTALLABLE["yq"]="yq"
    ANDROID_TOOLS_INSTALLABLE["curl"]="curl"
    ANDROID_TOOLS_INSTALLABLE["wget"]="wget"
    ANDROID_TOOLS_INSTALLABLE["unzip"]="unzip"
    ANDROID_TOOLS_INSTALLABLE["zip"]="zip"
    ANDROID_TOOLS_INSTALLABLE["bc"]="bc"
    ANDROID_TOOLS_INSTALLABLE["kotlinc"]="kotlin"
}

android_tool_check_system() {
    local tool="$1"
    
    if command_exists "$tool"; then
        ANDROID_TOOLS_STATUS["$tool"]="installed"
        return 0
    fi
    
    ANDROID_TOOLS_STATUS["$tool"]="missing"
    return 1
}

android_tool_check_sdk() {
    local tool="$1"
    local sdk_path="${ANDROID_SDK_ROOT:-}"
    
    if [[ -z "$sdk_path" ]] || [[ ! -d "$sdk_path" ]]; then
        ANDROID_TOOLS_STATUS["$tool"]="sdk_missing"
        return 1
    fi
    
    local build_tools_version="${ANDROID_BUILD_TOOLS:-34.0.0}"
    local tool_path="${sdk_path}/build-tools/${build_tools_version}/${tool}"
    
    if [[ -f "$tool_path" ]] && [[ -x "$tool_path" ]]; then
        ANDROID_TOOLS_STATUS["$tool"]="installed"
        return 0
    fi
    
    if [[ "$PLATFORM_OS" == "windows" ]]; then
        tool_path="${tool_path}.bat"
        if [[ -f "$tool_path" ]]; then
            ANDROID_TOOLS_STATUS["$tool"]="installed"
            return 0
        fi
    fi
    
    if [[ "$PLATFORM_IS_TERMUX" == "true" ]]; then
        local termux_tool="${PREFIX:-/data/data/com.termux/files/usr}/bin/${tool}"
        if [[ -f "$termux_tool" ]] && [[ -x "$termux_tool" ]]; then
            ANDROID_TOOLS_STATUS["$tool"]="installed"
            return 0
        fi
        if command_exists "$tool"; then
            ANDROID_TOOLS_STATUS["$tool"]="installed"
            return 0
        fi
    fi
    
    ANDROID_TOOLS_STATUS["$tool"]="missing"
    return 1
}

android_tool_check_java() {
    local tool="$1"
    
    if [[ -n "${JAVA_HOME:-}" ]] && [[ -f "${JAVA_HOME}/bin/${tool}" ]]; then
        ANDROID_TOOLS_STATUS["$tool"]="installed"
        return 0
    fi
    
    if command_exists "$tool"; then
        ANDROID_TOOLS_STATUS["$tool"]="installed"
        return 0
    fi
    
    ANDROID_TOOLS_STATUS["$tool"]="missing"
    return 1
}

android_tool_install() {
    local tool="$1"
    local package_name="${ANDROID_TOOLS_INSTALLABLE[$tool]:-$tool}"
    
    output_info "$(android_i18n_printf "installing_tool" "$tool")"
    
    if platform_install "$package_name"; then
        output_success "$(android_i18n_printf "tool_install_success" "$tool")"
        ANDROID_TOOLS_STATUS["$tool"]="installed"
        return 0
    else
        output_error "$(android_i18n_printf "tool_install_failed" "$tool")"
        return 1
    fi
}

android_tool_install_sdk_component() {
    local component="$1"
    
    output_info "$(android_i18n_get "installing_sdk_component"): $component"
    
    if android_install_sdk_component "$component"; then
        return 0
    fi
    
    return 1
}

android_tools_check_all() {
    local check_sdk="${1:-true}"
    local -a missing_tools=()
    local -a missing_sdk_components=()
    
    output_section "$(android_i18n_get "checking_tools")"
    
    output_debug "$(android_i18n_get "checking_java_tools")"
    for tool in java javac keytool; do
        if ! android_tool_check_java "$tool"; then
            missing_tools+=("$tool")
            output_error "  $(android_i18n_printf "tool_missing" "$tool")"
        else
            output_debug "  $(android_i18n_printf "tool_found" "$tool")"
        fi
    done
    
    output_debug "$(android_i18n_get "checking_download_tools")"
    local has_downloader=false
    if android_tool_check_system "curl"; then
        has_downloader=true
        output_debug "  $(android_i18n_printf "tool_found" "curl")"
    fi
    if android_tool_check_system "wget"; then
        has_downloader=true
        output_debug "  $(android_i18n_printf "tool_found" "wget")"
    fi
    if [[ "$has_downloader" == "false" ]]; then
        missing_tools+=("curl/wget")
        output_error "  $(android_i18n_get "need_downloader")"
    fi
    
    output_debug "$(android_i18n_get "checking_archive_tools")"
    for tool in unzip zip; do
        if ! android_tool_check_system "$tool"; then
            missing_tools+=("$tool")
            output_error "  $(android_i18n_printf "tool_missing" "$tool")"
        else
            output_debug "  $(android_i18n_printf "tool_found" "$tool")"
        fi
    done
    
    output_debug "$(android_i18n_get "checking_xml_tools")"
    local has_xml_tool=false
    if android_tool_check_system "xmlstarlet"; then
        has_xml_tool=true
        output_debug "  $(android_i18n_printf "tool_found" "xmlstarlet")"
    elif android_tool_check_system "xmllint"; then
        has_xml_tool=true
        output_debug "  $(android_i18n_printf "tool_found" "xmllint")"
    else
        missing_tools+=("xmlstarlet")
        output_error "  $(android_i18n_get "xml_tool_not_found")"
    fi
    
    output_debug "$(android_i18n_get "checking_yaml_tools")"
    if ! android_tool_check_system "yq"; then
        missing_tools+=("yq")
        output_error "  $(android_i18n_get "yq_not_found")"
    else
        output_debug "  $(android_i18n_printf "tool_found" "yq")"
    fi
    
    output_debug "$(android_i18n_get "checking_other_tools")"
    if ! android_tool_check_system "bc"; then
        missing_tools+=("bc")
        output_error "  $(android_i18n_printf "tool_missing" "bc")"
    else
        output_debug "  $(android_i18n_printf "tool_found" "bc")"
    fi
    
    if [[ "$check_sdk" == "true" ]] && [[ -n "${ANDROID_SDK_ROOT:-}" ]] && [[ -d "${ANDROID_SDK_ROOT:-}" ]]; then
        output_debug "$(android_i18n_get "checking_sdk_tools")"
        
        for tool in aapt aapt2 d8 zipalign apksigner; do
            if ! android_tool_check_sdk "$tool"; then
                missing_sdk_components+=("$tool")
                output_error "  $(android_i18n_printf "tool_missing" "$tool")"
            else
                output_debug "  $(android_i18n_printf "tool_found" "$tool")"
            fi
        done
        
        local android_jar="${ANDROID_SDK_ROOT}/platforms/android-${ANDROID_COMPILE_SDK:-34}/android.jar"
        if [[ ! -f "$android_jar" ]]; then
            missing_sdk_components+=("platform-${ANDROID_COMPILE_SDK:-34}")
            output_error "  $(android_i18n_printf "platform_missing" "${ANDROID_COMPILE_SDK:-34}")"
        else
            output_debug "  $(android_i18n_printf "platform_found" "${ANDROID_COMPILE_SDK:-34}")"
        fi
    fi
    
    if [[ "${ANDROID_KOTLIN_ENABLED:-false}" == "true" ]]; then
        output_debug "$(android_i18n_get "checking_kotlin_tools")"
        if ! android_tool_check_system "kotlinc"; then
            missing_tools+=("kotlinc")
            output_warning "  $(android_i18n_printf "tool_missing" "kotlinc")"
        else
            output_debug "  $(android_i18n_printf "tool_found" "kotlinc")"
        fi
    fi
    
    if [[ ${#missing_tools[@]} -eq 0 ]] && [[ ${#missing_sdk_components[@]} -eq 0 ]]; then
        output_success "$(android_i18n_get "all_tools_found")"
        return 0
    fi
    
    echo ""
    output_section "$(android_i18n_get "missing_tools_section")"
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        output_error "$(android_i18n_get "system_tools_missing"):"
        for tool in "${missing_tools[@]}"; do
            output_bullet "$tool"
        done
    fi
    
    if [[ ${#missing_sdk_components[@]} -gt 0 ]]; then
        output_error "$(android_i18n_get "sdk_tools_missing"):"
        for tool in "${missing_sdk_components[@]}"; do
            output_bullet "$tool"
        done
    fi
    
    ANDROID_MISSING_TOOLS=("${missing_tools[@]}")
    ANDROID_MISSING_SDK_COMPONENTS=("${missing_sdk_components[@]}")
    
    return 1
}

android_tools_install_missing() {
    local -a tools=("${ANDROID_MISSING_TOOLS[@]:-}")
    local -a sdk_components=("${ANDROID_MISSING_SDK_COMPONENTS[@]:-}")
    
    if [[ ${#tools[@]} -eq 0 ]] && [[ ${#sdk_components[@]} -eq 0 ]]; then
        return 0
    fi
    
    echo ""
    output_info "$(android_i18n_get "install_missing_prompt")"
    
    if [[ ${#tools[@]} -gt 0 ]]; then
        output_info "$(android_i18n_get "system_tools"):"
        for tool in "${tools[@]}"; do
            output_bullet "$tool"
        done
    fi
    
    if [[ ${#sdk_components[@]} -gt 0 ]]; then
        output_info "$(android_i18n_get "sdk_components"):"
        for comp in "${sdk_components[@]}"; do
            output_bullet "$comp"
        done
    fi
    
    echo ""
    if ! confirm_action "$(android_i18n_get "install_confirm")"; then
        output_info "$(android_i18n_get "install_skipped")"
        return 1
    fi
    
    local errors=0
    
    if [[ ${#tools[@]} -gt 0 ]]; then
        for tool in "${tools[@]}"; do
            case "$tool" in
                curl/wget)
                    if ! android_tool_install "curl" && ! android_tool_install "wget"; then
                        ((errors++))
                    fi
                    ;;
                kotlinc)
                    if ! android_tool_install "kotlinc"; then
                        ((errors++))
                    fi
                    ;;
                *)
                    if ! android_tool_install "$tool"; then
                        ((errors++))
                    fi
                    ;;
            esac
        done
    fi
    
    if [[ ${#sdk_components[@]} -gt 0 ]]; then
        for comp in "${sdk_components[@]}"; do
            case "$comp" in
                platform-*)
                    local version="${comp#platform-}"
                    if ! android_install_platform "$version"; then
                        ((errors++))
                    fi
                    ;;
                *)
                    if ! android_check_build_tools; then
                        if ! android_install_build_tools; then
                            ((errors++))
                        fi
                    fi
                    ;;
            esac
        done
    fi
    
    if [[ $errors -gt 0 ]]; then
        output_error "$(android_i18n_printf "install_errors" "$errors")"
        return 1
    fi
    
    output_success "$(android_i18n_get "install_complete")"
    return 0
}

android_tools_ensure() {
    local auto_install="${1:-true}"
    
    android_tools_init
    
    if android_tools_check_all; then
        return 0
    fi
    
    if [[ "$auto_install" == "true" ]]; then
        if android_tools_install_missing; then
            android_tools_check_all
            return $?
        fi
    fi
    
    return 1
}

android_tools_check_before_build() {
    output_section "$(android_i18n_get "pre_build_check")"
    
    if ! android_check_java; then
        output_error "$(android_i18n_get "java_required")"
        return 1
    fi
    
    if ! android_detect_sdk; then
        output_warning "$(android_i18n_get "sdk_not_found")"
        if confirm_action "$(android_i18n_get "setup_prompt")"; then
            android_setup_sdk || return 1
        else
            return 1
        fi
    fi
    
    if ! android_tools_ensure "true"; then
        return 1
    fi
    
    output_success "$(android_i18n_get "pre_build_check_passed")"
    return 0
}

android_tools_list() {
    output_section "$(android_i18n_get "tools_list")"
    
    android_tools_init
    
    output_info "$(android_i18n_get "system_tools"):"
    for tool in java javac keytool curl wget unzip zip xmlstarlet xmllint yq bc; do
        if android_tool_check_system "$tool" 2>/dev/null || android_tool_check_java "$tool" 2>/dev/null; then
            output_bullet "$(android_i18n_get "yes"): $tool"
        else
            output_bullet "$(android_i18n_get "no"): $tool"
        fi
    done
    
    if [[ -n "${ANDROID_SDK_ROOT:-}" ]] && [[ -d "${ANDROID_SDK_ROOT:-}" ]]; then
        output_info "$(android_i18n_get "sdk_tools"):"
        for tool in aapt aapt2 d8 zipalign apksigner; do
            if android_tool_check_sdk "$tool" 2>/dev/null; then
                output_bullet "$(android_i18n_get "yes"): $tool"
            else
                output_bullet "$(android_i18n_get "no"): $tool"
            fi
        done
    fi
    
    if [[ "${ANDROID_KOTLIN_ENABLED:-false}" == "true" ]]; then
        output_info "$(android_i18n_get "kotlin_tools"):"
        if android_tool_check_system "kotlinc" 2>/dev/null; then
            output_bullet "$(android_i18n_get "yes"): kotlinc"
        else
            output_bullet "$(android_i18n_get "no"): kotlinc"
        fi
    fi
}

declare -ga ANDROID_MISSING_TOOLS=()
declare -ga ANDROID_MISSING_SDK_COMPONENTS=()

android_tools_init

fi
