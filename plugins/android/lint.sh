#!/usr/bin/env bash

if [[ -z "${_ANDROID_LINT_LOADED:-}" ]]; then
_ANDROID_LINT_LOADED=1

declare -g ANDROID_LINT_ENABLED="true"
declare -g ANDROID_LINT_CHECKS="all"
declare -g ANDROID_LINT_DISABLE=""
declare -g ANDROID_LINT_FATAL=""
declare -g ANDROID_LINT_REPORT_FORMAT="html"
declare -g ANDROID_LINT_BASELINE_FILE=""
declare -g ANDROID_LINT_CONFIG_FILE=""
declare -g ANDROID_LINT_REPORT_DIR=""
declare -g ANDROID_LINT_ABORT_ON_ERROR="false"

declare -g ANDROID_LINT_RESULT_ERRORS=0
declare -g ANDROID_LINT_RESULT_WARNINGS=0
declare -g ANDROID_LINT_RESULT_INFO=0

android_lint_init() {
    ANDROID_LINT_REPORT_DIR="${ANDROID_BUILD_DIR}/reports/lint"
    
    if [[ -n "${ANDROID_LINT_BASELINE_FILE:-}" ]]; then
        ANDROID_LINT_BASELINE_FILE="${ANDROID_PROJECT_DIR}/${ANDROID_LINT_BASELINE_FILE}"
    else
        ANDROID_LINT_BASELINE_FILE="${ANDROID_PROJECT_DIR}/lint-baseline.xml"
    fi
    
    if [[ -n "${ANDROID_LINT_CONFIG_FILE:-}" ]]; then
        ANDROID_LINT_CONFIG_FILE="${ANDROID_PROJECT_DIR}/${ANDROID_LINT_CONFIG_FILE}"
    else
        ANDROID_LINT_CONFIG_FILE="${ANDROID_PROJECT_DIR}/lint.xml"
    fi
    
    ensure_dir "$ANDROID_LINT_REPORT_DIR"
}

android_get_lint() {
    local lint_path=""
    
    if [[ -n "${ANDROID_SDK_ROOT:-}" ]] && [[ -d "${ANDROID_SDK_ROOT:-}" ]]; then
        lint_path="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/lint"
        if [[ -f "$lint_path" ]]; then
            echo "$lint_path"
            return 0
        fi
        
        lint_path="${ANDROID_SDK_ROOT}/cmdline-tools/bin/lint"
        if [[ -f "$lint_path" ]]; then
            echo "$lint_path"
            return 0
        fi
        
        lint_path="${ANDROID_SDK_ROOT}/tools/bin/lint"
        if [[ -f "$lint_path" ]]; then
            echo "$lint_path"
            return 0
        fi
    fi
    
    if command_exists lint; then
        command -v lint
        return 0
    fi
    
    return 1
}

android_lint_build_options() {
    local -a opts=()
    
    opts+=("--quiet")
    
    if [[ -n "$ANDROID_LINT_CHECKS" ]] && [[ "$ANDROID_LINT_CHECKS" != "all" ]]; then
        opts+=("--check" "$ANDROID_LINT_CHECKS")
    fi
    
    if [[ -n "$ANDROID_LINT_DISABLE" ]]; then
        local -a disable_checks
        IFS=',' read -ra disable_checks <<< "$ANDROID_LINT_DISABLE"
        for check in "${disable_checks[@]}"; do
            opts+=("--disable" "$check")
        done
    fi
    
    if [[ -n "$ANDROID_LINT_FATAL" ]]; then
        local -a fatal_checks
        IFS=',' read -ra fatal_checks <<< "$ANDROID_LINT_FATAL"
        for check in "${fatal_checks[@]}"; then
            opts+=("--fatalcheck" "$check")
        done
    fi
    
    if [[ -f "$ANDROID_LINT_CONFIG_FILE" ]]; then
        opts+=("--config" "$ANDROID_LINT_CONFIG_FILE")
    else
        output_debug "$(android_i18n_get "lint_config_not_found")"
    fi
    
    if [[ -f "$ANDROID_LINT_BASELINE_FILE" ]]; then
        opts+=("--baseline" "$ANDROID_LINT_BASELINE_FILE")
    fi
    
    local format="${ANDROID_LINT_REPORT_FORMAT:-html}"
    case "$format" in
        html)
            opts+=("--html" "${ANDROID_LINT_REPORT_DIR}/lint-report.html")
            ;;
        xml)
            opts+=("--xml" "${ANDROID_LINT_REPORT_DIR}/lint-report.xml")
            ;;
        json)
            opts+=("--json" "${ANDROID_LINT_REPORT_DIR}/lint-report.json")
            ;;
        text|*)
            opts+=("--text" "${ANDROID_LINT_REPORT_DIR}/lint-report.txt")
            ;;
    esac
    
    echo "${opts[@]}"
}

android_lint_check() {
    output_section "$(android_i18n_get "lint_checking")"
    
    android_lint_init
    
    local lint_tool
    lint_tool=$(android_get_lint)
    
    if [[ -z "$lint_tool" ]]; then
        output_error "$(android_i18n_get "lint_not_found")"
        output_info "$(android_i18n_get "installing_sdk_component"): cmdline-tools"
        return 1
    fi
    
    if [[ "$ANDROID_LINT_ENABLED" != "true" ]]; then
        output_info "$(android_i18n_get "lint_disabled")"
        return 0
    fi
    
    local -a lint_opts
    read -ra lint_opts <<< "$(android_lint_build_options)"
    
    lint_opts+=("$ANDROID_PROJECT_DIR")
    
    output_debug "Lint options: ${lint_opts[*]}"
    
    local lint_output
    local lint_exit_code
    
    if [[ "$PLATFORM_OS" == "windows" ]]; then
        lint_output=$("$lint_tool" "${lint_opts[@]}" 2>&1)
    else
        lint_output=$("$lint_tool" "${lint_opts[@]}" 2>&1)
    fi
    lint_exit_code=$?
    
    echo "$lint_output"
    
    android_lint_parse_results "$lint_output"
    
    if [[ $lint_exit_code -ne 0 ]] || [[ $ANDROID_LINT_RESULT_ERRORS -gt 0 ]]; then
        output_error "$(android_i18n_get "lint_failed")"
        output_error "$(android_i18n_printf "lint_errors" "$ANDROID_LINT_RESULT_ERRORS")"
        output_warning "$(android_i18n_printf "lint_warnings" "$ANDROID_LINT_RESULT_WARNINGS")"
        
        if [[ "$ANDROID_LINT_ABORT_ON_ERROR" == "true" ]]; then
            return 1
        fi
    elif [[ $ANDROID_LINT_RESULT_WARNINGS -gt 0 ]]; then
        output_warning "$(android_i18n_printf "lint_warnings" "$ANDROID_LINT_RESULT_WARNINGS")"
    else
        output_success "$(android_i18n_get "lint_no_issues")"
    fi
    
    local format="${ANDROID_LINT_REPORT_FORMAT:-html}"
    local report_file
    case "$format" in
        html) report_file="${ANDROID_LINT_REPORT_DIR}/lint-report.html" ;;
        xml)  report_file="${ANDROID_LINT_REPORT_DIR}/lint-report.xml" ;;
        json) report_file="${ANDROID_LINT_REPORT_DIR}/lint-report.json" ;;
        *)    report_file="${ANDROID_LINT_REPORT_DIR}/lint-report.txt" ;;
    esac
    
    if [[ -f "$report_file" ]]; then
        output_success "$(android_i18n_printf "lint_report_saved" "$report_file")"
    fi
    
    output_success "$(android_i18n_get "lint_complete")"
    
    return 0
}

android_lint_parse_results() {
    local output="$1"
    
    ANDROID_LINT_RESULT_ERRORS=0
    ANDROID_LINT_RESULT_WARNINGS=0
    ANDROID_LINT_RESULT_INFO=0
    
    local error_count
    error_count=$(echo "$output" | grep -oE '[0-9]+ error(s)?' | grep -oE '[0-9]+' | head -1)
    [[ -n "$error_count" ]] && ANDROID_LINT_RESULT_ERRORS=$error_count
    
    local warning_count
    warning_count=$(echo "$output" | grep -oE '[0-9]+ warning(s)?' | grep -oE '[0-9]+' | head -1)
    [[ -n "$warning_count" ]] && ANDROID_LINT_RESULT_WARNINGS=$warning_count
    
    local info_count
    info_count=$(echo "$output" | grep -oE '[0-9]+ informational' | grep -oE '[0-9]+' | head -1)
    [[ -n "$info_count" ]] && ANDROID_LINT_RESULT_INFO=$info_count
}

android_lint_fix() {
    output_section "$(android_i18n_get "lint_fixing")"
    
    android_lint_init
    
    local lint_tool
    lint_tool=$(android_get_lint)
    
    if [[ -z "$lint_tool" ]]; then
        output_error "$(android_i18n_get "lint_not_found")"
        return 1
    fi
    
    local -a lint_opts=("--fix")
    
    if [[ -f "$ANDROID_LINT_CONFIG_FILE" ]]; then
        lint_opts+=("--config" "$ANDROID_LINT_CONFIG_FILE")
    fi
    
    lint_opts+=("$ANDROID_PROJECT_DIR")
    
    local lint_output
    lint_output=$("$lint_tool" "${lint_opts[@]}" 2>&1)
    local lint_exit_code=$?
    
    echo "$lint_output"
    
    local fixed_count
    fixed_count=$(echo "$lint_output" | grep -oE '[0-9]+ issue(s)? fixed' | grep -oE '[0-9]+' | head -1)
    
    if [[ -n "$fixed_count" ]] && [[ $fixed_count -gt 0 ]]; then
        output_success "$(android_i18n_printf "lint_fixed" "$fixed_count")"
    else
        output_info "$(android_i18n_get "lint_no_issues_fix")"
    fi
    
    return $lint_exit_code
}

android_lint_baseline() {
    output_section "$(android_i18n_get "lint_baseline_creating")"
    
    android_lint_init
    
    local lint_tool
    lint_tool=$(android_get_lint)
    
    if [[ -z "$lint_tool" ]]; then
        output_error "$(android_i18n_get "lint_not_found")"
        return 1
    fi
    
    local baseline_file="${ANDROID_LINT_BASELINE_FILE}"
    
    local -a lint_opts=(
        "--baseline" "$baseline_file"
        "--update-baseline"
    )
    
    if [[ -f "$ANDROID_LINT_CONFIG_FILE" ]]; then
        lint_opts+=("--config" "$ANDROID_LINT_CONFIG_FILE")
    fi
    
    lint_opts+=("$ANDROID_PROJECT_DIR")
    
    "$lint_tool" "${lint_opts[@]}" 2>&1
    
    if [[ -f "$baseline_file" ]]; then
        output_success "$(android_i18n_printf "lint_baseline_created" "$baseline_file")"
        return 0
    else
        output_error "$(android_i18n_get "lint_baseline_failed")"
        return 1
    fi
}

android_lint_report() {
    output_section "$(android_i18n_get "lint_generating_report")"
    
    ANDROID_LINT_REPORT_FORMAT="${1:-html}"
    
    android_lint_check
}

fi
