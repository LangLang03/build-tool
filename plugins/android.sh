#!/usr/bin/env bash

PLUGIN_NAME="android"
PLUGIN_VERSION="1.0.0"
PLUGIN_DESCRIPTION="Complete Android build system without Gradle"
PLUGIN_DEPENDENCIES="java,javac"

source "${SCRIPT_DIR}/plugins/android/i18n.sh"
source "${SCRIPT_DIR}/plugins/android/tools.sh"
source "${SCRIPT_DIR}/plugins/android/xml.sh"
source "${SCRIPT_DIR}/plugins/android/sdk.sh"
source "${SCRIPT_DIR}/plugins/android/dependencies.sh"
source "${SCRIPT_DIR}/plugins/android/resources.sh"
source "${SCRIPT_DIR}/plugins/android/compile.sh"
source "${SCRIPT_DIR}/plugins/android/dex.sh"
source "${SCRIPT_DIR}/plugins/android/package.sh"
source "${SCRIPT_DIR}/plugins/android/signing.sh"
source "${SCRIPT_DIR}/plugins/android/lint.sh"

declare -g ANDROID_PROJECT_DIR=""
declare -g ANDROID_BUILD_DIR=""
declare -g ANDROID_SOURCE_DIR=""
declare -g ANDROID_MANIFEST=""

declare -g ANDROID_APPLICATION_ID=""
declare -g ANDROID_VERSION_NAME=""
declare -g ANDROID_VERSION_CODE=""

declare -g ANDROID_BUILD_TYPE="debug"
declare -g ANDROID_MINIFY=false
declare -g ANDROID_SHRINK=false

declare -gA ANDROID_SIGNING_DEBUG=()
declare -gA ANDROID_SIGNING_RELEASE=()

declare -ga ANDROID_REPOSITORIES=()
declare -ga ANDROID_DEPS_IMPLEMENTATION=()
declare -ga ANDROID_DEPS_COMPILE_ONLY=()
declare -ga ANDROID_DEPS_TEST_IMPL=()
declare -ga ANDROID_DEPS_ANDROID_TEST_IMPL=()

declare -g ANDROID_JAVA_SOURCE="11"
declare -g ANDROID_JAVA_TARGET="11"
declare -g ANDROID_JAVA_OPTS=""
declare -g ANDROID_KOTLIN_ENABLED="false"
declare -g ANDROID_KOTLIN_OPTS=""

android_config_init() {
    ANDROID_PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
    ANDROID_BUILD_DIR="${BUILD_DIR:-${ANDROID_PROJECT_DIR}/build/android}"
    ANDROID_SOURCE_DIR="${SOURCE_DIR:-${ANDROID_PROJECT_DIR}/src/main}"
    
    local config_file="${PROJECT_CONFIG_FILE:-${ANDROID_PROJECT_DIR}/build.yaml}"
    
    if [[ -f "$config_file" ]] && command_exists yq; then
        android_config_load "$config_file"
    fi
    
    ANDROID_MANIFEST="${ANDROID_SOURCE_DIR}/AndroidManifest.xml"
}

android_config_load() {
    local config_file="$1"
    
    ANDROID_APPLICATION_ID=$(yaml_read_str "$config_file" "android.application.id" "${PROJECT_NAME:-com.example.app}")
    ANDROID_VERSION_NAME=$(yaml_read_str "$config_file" "android.application.version_name" "${PROJECT_VERSION:-1.0.0}")
    ANDROID_VERSION_CODE=$(yaml_read_str "$config_file" "android.application.version_code" "1")
    
    ANDROID_COMPILE_SDK=$(yaml_read_int "$config_file" "android.sdk.compile_sdk" "34")
    ANDROID_BUILD_TOOLS=$(yaml_read_str "$config_file" "android.sdk.build_tools" "34.0.0")
    ANDROID_MIN_SDK=$(yaml_read_int "$config_file" "android.sdk.min_sdk" "21")
    ANDROID_TARGET_SDK=$(yaml_read_int "$config_file" "android.sdk.target_sdk" "34")
    
    ANDROID_BUILD_TYPE=$(yaml_read_str "$config_file" "android.build.type" "debug")
    ANDROID_MINIFY=$(yaml_read_bool "$config_file" "android.build.minify" "false")
    ANDROID_SHRINK=$(yaml_read_bool "$config_file" "android.build.shrink" "false")
    
    ANDROID_JAVA_SOURCE=$(yaml_read_str "$config_file" "android.java.source" "11")
    ANDROID_JAVA_TARGET=$(yaml_read_str "$config_file" "android.java.target" "11")
    ANDROID_JAVA_OPTS=$(yaml_read_str "$config_file" "android.java.opts" "")
    
    ANDROID_KOTLIN_ENABLED=$(yaml_read_bool "$config_file" "android.kotlin.enabled" "false")
    ANDROID_KOTLIN_OPTS=$(yaml_read_str "$config_file" "android.kotlin.opts" "")
    
    local -a repos=()
    yaml_read_array "$config_file" "android.repositories" repos
    if [[ ${#repos[@]} -gt 0 ]]; then
        ANDROID_REPOSITORIES=("${repos[@]}")
    else
        ANDROID_REPOSITORIES=(
            "https://maven.aliyun.com/repository/google"
            "https://maven.aliyun.com/repository/public"
            "https://dl.google.com/dl/android/maven2"
            "https://repo1.maven.org/maven2"
            "https://maven.google.com"
        )
    fi
    
    yaml_read_array "$config_file" "android.dependencies.implementation" ANDROID_DEPS_IMPLEMENTATION
    yaml_read_array "$config_file" "android.dependencies.compile_only" ANDROID_DEPS_COMPILE_ONLY
    yaml_read_array "$config_file" "android.dependencies.test_implementation" ANDROID_DEPS_TEST_IMPL
    yaml_read_array "$config_file" "android.dependencies.android_test_implementation" ANDROID_DEPS_ANDROID_TEST_IMPL
    
    local keystore_file
    keystore_file=$(yaml_read_str "$config_file" "android.signing.release.store_file" "")
    if [[ -n "$keystore_file" ]]; then
        ANDROID_SIGNING_RELEASE[store_file]="$keystore_file"
        ANDROID_SIGNING_RELEASE[store_password]=$(yaml_read_str "$config_file" "android.signing.release.store_password" "")
        ANDROID_SIGNING_RELEASE[key_alias]=$(yaml_read_str "$config_file" "android.signing.release.key_alias" "")
        ANDROID_SIGNING_RELEASE[key_password]=$(yaml_read_str "$config_file" "android.signing.release.key_password" "")
    fi
    
    ANDROID_LINT_ENABLED=$(yaml_read_bool "$config_file" "android.lint.enabled" "true")
    ANDROID_LINT_CHECKS=$(yaml_read_str "$config_file" "android.lint.checks" "all")
    ANDROID_LINT_DISABLE=$(yaml_read_str "$config_file" "android.lint.disable" "")
    ANDROID_LINT_FATAL=$(yaml_read_str "$config_file" "android.lint.fatal" "")
    ANDROID_LINT_REPORT_FORMAT=$(yaml_read_str "$config_file" "android.lint.report_format" "html")
    ANDROID_LINT_BASELINE_FILE=$(yaml_read_str "$config_file" "android.lint.baseline_file" "")
    ANDROID_LINT_CONFIG_FILE=$(yaml_read_str "$config_file" "android.lint.config_file" "")
    ANDROID_LINT_ABORT_ON_ERROR=$(yaml_read_bool "$config_file" "android.lint.abort_on_error" "false")
}

android_config_get() {
    local key="$1"
    local default="${2:-}"
    
    case "$key" in
        application_id)    echo "${ANDROID_APPLICATION_ID:-$default}" ;;
        version_name)      echo "${ANDROID_VERSION_NAME:-$default}" ;;
        version_code)      echo "${ANDROID_VERSION_CODE:-$default}" ;;
        compile_sdk)       echo "${ANDROID_COMPILE_SDK:-$default}" ;;
        build_tools)       echo "${ANDROID_BUILD_TOOLS:-$default}" ;;
        min_sdk)           echo "${ANDROID_MIN_SDK:-$default}" ;;
        target_sdk)        echo "${ANDROID_TARGET_SDK:-$default}" ;;
        build_type)        echo "${ANDROID_BUILD_TYPE:-$default}" ;;
        minify)            echo "${ANDROID_MINIFY:-$default}" ;;
        shrink)            echo "${ANDROID_SHRINK:-$default}" ;;
        build_dir)         echo "${ANDROID_BUILD_DIR:-$default}" ;;
        source_dir)        echo "${ANDROID_SOURCE_DIR:-$default}" ;;
        manifest)          echo "${ANDROID_MANIFEST:-$default}" ;;
        *)                 echo "$default" ;;
    esac
}

android_config_set() {
    local key="$1"
    local value="$2"
    
    case "$key" in
        application_id)    ANDROID_APPLICATION_ID="$value" ;;
        version_name)      ANDROID_VERSION_NAME="$value" ;;
        version_code)      ANDROID_VERSION_CODE="$value" ;;
        compile_sdk)       ANDROID_COMPILE_SDK="$value" ;;
        build_tools)       ANDROID_BUILD_TOOLS="$value" ;;
        min_sdk)           ANDROID_MIN_SDK="$value" ;;
        target_sdk)        ANDROID_TARGET_SDK="$value" ;;
        build_type)        ANDROID_BUILD_TYPE="$value" ;;
        minify)            ANDROID_MINIFY="$value" ;;
        shrink)            ANDROID_SHRINK="$value" ;;
        build_dir)         ANDROID_BUILD_DIR="$value" ;;
        source_dir)        ANDROID_SOURCE_DIR="$value" ;;
        manifest)          ANDROID_MANIFEST="$value" ;;
    esac
}

android_check_java() {
    if ! command_exists java; then
        output_error "$(android_i18n_get "java_not_found")"
        return 1
    fi
    
    output_debug "$(android_i18n_get "java_version_check")"
    
    local java_version
    java_version=$(java -version 2>&1 | head -n1 | grep -oP '"\K[0-9]+' | head -1)
    
    if [[ -z "$java_version" ]]; then
        java_version=$(java -version 2>&1 | head -n1 | grep -oP 'version "?\K[0-9]+' | head -1)
    fi
    
    if [[ -n "$java_version" ]] && [[ $java_version -lt 11 ]]; then
        output_error "$(android_i18n_printf "java_version_incompatible" "$java_version")"
        return 1
    fi
    
    if [[ -z "${JAVA_HOME:-}" ]]; then
        output_warning "$(android_i18n_get "java_home_not_set")"
        
        local java_path
        java_path=$(command -v java 2>/dev/null)
        if [[ -n "$java_path" ]]; then
            java_path=$(readlink -f "$java_path" 2>/dev/null || echo "$java_path")
            JAVA_HOME=$(dirname "$(dirname "$java_path")")
            export JAVA_HOME
            output_debug "$(android_i18n_get "java_home_detected"): $JAVA_HOME"
        fi
    fi
    
    if ! command_exists javac; then
        output_error "$(android_i18n_get "javac_not_found")"
        return 1
    fi
    
    output_success "$(android_i18n_get "java_found"): ${java_version:-unknown}"
    return 0
}

android_check_environment() {
    output_header "$(android_i18n_get "check_environment")" 50
    
    local errors=0
    
    output_section "Java"
    if ! android_check_java; then
        ((errors++))
    fi
    
    output_section "Android SDK"
    if ! android_detect_sdk; then
        output_warning "$(android_i18n_get "sdk_not_found")"
        ((errors++))
    else
        output_success "$(android_i18n_get "sdk_found"): $ANDROID_SDK_ROOT"
        
        output_section "SDK Components"
        
        if android_check_build_tools; then
            output_success "$(android_i18n_get "build_tools_found"): $ANDROID_BUILD_TOOLS"
        else
            output_warning "$(android_i18n_get "build_tools_not_found"): $ANDROID_BUILD_TOOLS"
            ((errors++))
        fi
        
        if android_check_platform; then
            output_success "$(android_i18n_get "platform_found"): $ANDROID_COMPILE_SDK"
        else
            output_warning "$(android_i18n_get "platform_not_found"): $ANDROID_COMPILE_SDK"
            ((errors++))
        fi
        
        if android_check_cmdline_tools; then
            output_success "$(android_i18n_get "cmdline_tools_found")"
        else
            output_warning "$(android_i18n_get "cmdline_tools_not_found")"
        fi
    fi
    
    output_section "$(android_i18n_get "check_environment")"
    if [[ $errors -eq 0 ]]; then
        output_success "$(android_i18n_get "check_passed")"
        return 0
    else
        output_error "$errors $(android_i18n_get "missing_components")"
        return 1
    fi
}

android_setup() {
    output_section "$(android_i18n_get "setup_required")"
    
    if ! android_check_java; then
        return 1
    fi
    
    android_setup_sdk
}

android_clean() {
    output_section "$(android_i18n_get "clean_start")"
    
    android_config_init
    
    if [[ -d "$ANDROID_BUILD_DIR" ]]; then
        output_info "$(android_i18n_get "clean_start"): $ANDROID_BUILD_DIR"
        rm -rf "$ANDROID_BUILD_DIR"
        output_success "$(android_i18n_get "clean_complete")"
    else
        output_info "$(android_i18n_get "nothing_to_clean")"
    fi
    
    return 0
}

android_check() {
    android_config_init
    android_check_environment
}

android_sdk_info() {
    android_detect_sdk
    android_get_sdk_info
}

android_deps() {
    android_config_init
    android_resolve_all_dependencies
}

android_resources() {
    android_config_init
    android_tools_ensure || return 1
    android_resolve_all_dependencies || return 1
    android_process_resources
}

android_compile() {
    android_config_init
    android_tools_ensure || return 1
    android_resolve_all_dependencies || return 1
    android_process_resources || return 1
    android_compile_all
}

android_dex() {
    android_config_init
    android_tools_ensure || return 1
    android_resolve_all_dependencies || return 1
    android_process_resources || return 1
    android_compile_all || return 1
    android_dex_classes
}

android_package() {
    android_config_init
    android_tools_ensure || return 1
    android_resolve_all_dependencies || return 1
    android_process_resources || return 1
    android_compile_all || return 1
    android_dex_classes || return 1
    android_package_apk
}

android_sign() {
    android_config_init
    android_package_init
    
    local aligned_apk="${ANDROID_OUTPUT_DIR}/${PROJECT_NAME}-aligned.apk"
    
    local zipalign
    zipalign=$(android_get_zipalign) || return 1
    
    if ! android_zipalign_apk "$ANDROID_UNSIGNED_APK" "$aligned_apk"; then
        return 1
    fi
    
    if [[ "$ANDROID_BUILD_TYPE" == "release" ]]; then
        android_sign_release "$aligned_apk" "$ANDROID_FINAL_APK"
    else
        android_sign_debug "$aligned_apk" "$ANDROID_FINAL_APK"
    fi
}

android_build() {
    local start_time
    start_time=$(date +%s)
    
    output_header "$(android_i18n_get "build_start")" 50
    
    android_config_init
    
    if ! android_tools_check_before_build; then
        return 1
    fi
    
    if [[ "$ANDROID_LINT_ENABLED" == "true" ]]; then
        android_lint_check || {
            if [[ "$ANDROID_LINT_ABORT_ON_ERROR" == "true" ]]; then
                return 1
            fi
        }
    fi
    
    android_resolve_all_dependencies || return 1
    android_process_resources || return 1
    android_compile_all || return 1
    android_dex_classes || return 1
    android_package_apk || return 1
    
    android_package_init
    
    local aligned_apk="${ANDROID_OUTPUT_DIR}/${PROJECT_NAME}-aligned.apk"
    
    if ! android_zipalign_apk "$ANDROID_UNSIGNED_APK" "$aligned_apk"; then
        return 1
    fi
    
    if [[ "$ANDROID_BUILD_TYPE" == "release" ]]; then
        android_sign_release "$aligned_apk" "$ANDROID_FINAL_APK" || return 1
    else
        android_sign_debug "$aligned_apk" "$ANDROID_FINAL_APK" || return 1
    fi
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    output_section "$(android_i18n_get "build_complete")"
    
    if [[ -f "$ANDROID_FINAL_APK" ]]; then
        local size
        size=$(android_get_apk_size "$ANDROID_FINAL_APK")
        local size_formatted
        size_formatted=$(android_format_apk_size "$size")
        
        output_success "APK: $ANDROID_FINAL_APK"
        output_success "Size: $size_formatted"
        output_success "Time: ${duration}s"
    fi
    
    return 0
}

android_install() {
    android_config_init
    
    local apk_file="${ANDROID_FINAL_APK}"
    
    if [[ ! -f "$apk_file" ]]; then
        output_error "$(android_i18n_get "apk_not_found_build")"
        return 1
    fi
    
    local adb="${ANDROID_SDK_ROOT}/platform-tools/adb"
    
    if [[ ! -f "$adb" ]]; then
        output_error "$(android_i18n_get "adb_not_found")"
        return 1
    fi
    
    output_section "$(android_i18n_get "installing")"
    
    local devices
    devices=$("$adb" devices 2>/dev/null | grep -v "List" | grep "device$" | wc -l)
    
    if [[ $devices -eq 0 ]]; then
        output_error "$(android_i18n_get "no_device")"
        return 1
    fi
    
    if [[ $devices -gt 1 ]]; then
        output_warning "$(android_i18n_get "multiple_devices")"
    fi
    
    if "$adb" install -r "$apk_file" 2>&1; then
        output_success "$(android_i18n_get "install_complete")"
        return 0
    else
        output_error "$(android_i18n_get "install_failed")"
        return 1
    fi
}

android_run() {
    android_config_init
    
    local adb="${ANDROID_SDK_ROOT}/platform-tools/adb"
    
    if [[ ! -f "$adb" ]]; then
        output_error "$(android_i18n_get "adb_not_found")"
        return 1
    fi
    
    local package="${ANDROID_APPLICATION_ID}"
    
    if [[ -z "$package" ]]; then
        output_error "$(android_i18n_get "app_id_not_configured")"
        return 1
    fi
    
    output_info "$(android_i18n_printf "starting_package" "$package")"
    
    "$adb" shell am start -n "${package}/.MainActivity" 2>&1
}

android_info() {
    android_config_init
    
    output_header "$(android_i18n_get "android_project_info")" 50
    
    output_section "$(android_i18n_get "project_section")"
    output_key_value "Application ID" "${ANDROID_APPLICATION_ID:-$(android_i18n_get "not_set")}" 20
    output_key_value "Version Name" "${ANDROID_VERSION_NAME:-$(android_i18n_get "not_set")}" 20
    output_key_value "Version Code" "${ANDROID_VERSION_CODE:-$(android_i18n_get "not_set")}" 20
    
    output_section "$(android_i18n_get "sdk_section")"
    output_key_value "Compile SDK" "${ANDROID_COMPILE_SDK:-$(android_i18n_get "not_set")}" 20
    output_key_value "Build Tools" "${ANDROID_BUILD_TOOLS:-$(android_i18n_get "not_set")}" 20
    output_key_value "Min SDK" "${ANDROID_MIN_SDK:-$(android_i18n_get "not_set")}" 20
    output_key_value "Target SDK" "${ANDROID_TARGET_SDK:-$(android_i18n_get "not_set")}" 20
    
    output_section "$(android_i18n_get "build_section")"
    output_key_value "Build Type" "${ANDROID_BUILD_TYPE:-debug}" 20
    output_key_value "Minify" "${ANDROID_MINIFY:-false}" 20
    
    output_section "$(android_i18n_get "directories_section")"
    output_key_value "Project" "$ANDROID_PROJECT_DIR" 20
    output_key_value "Source" "$ANDROID_SOURCE_DIR" 20
    output_key_value "Build" "$ANDROID_BUILD_DIR" 20
    
    if [[ ${#ANDROID_DEPS_IMPLEMENTATION[@]} -gt 0 ]]; then
        output_section "$(android_i18n_get "dependencies_section")"
        for dep in "${ANDROID_DEPS_IMPLEMENTATION[@]}"; do
            output_bullet "$dep"
        done
    fi
}

register_target "android:check" "Check Android build environment" "android_check"
register_target "android:setup" "Setup Android SDK" "android_setup"
register_target "android:clean" "Clean Android build artifacts" "android_clean"
register_target "android:deps" "Download and resolve dependencies" "android_deps"
register_target "android:resources" "Compile resources" "android_resources"
register_target "android:compile" "Compile Java/Kotlin sources" "android_compile"
register_target "android:dex" "Convert to DEX" "android_dex"
register_target "android:package" "Package APK" "android_package"
register_target "android:sign" "Sign APK" "android_sign"
register_target "android:build" "Build complete APK" "android_build"
register_target "android:install" "Install APK to device" "android_install"
register_target "android:run" "Run application on device" "android_run"
register_target "android:info" "Show project information" "android_info"
register_target "android:sdk-info" "Show Android SDK information" "android_sdk_info"
register_target "android:tools" "Check and install required tools" "android_tools_list"
register_target "android:lint" "Run lint check" "android_lint_check"
register_target "android:lint-fix" "Auto-fix lint issues" "android_lint_fix"
register_target "android:lint-baseline" "Create lint baseline file" "android_lint_baseline"

register_hook "pre_build" "android" "android_config_init"

android_config_init
