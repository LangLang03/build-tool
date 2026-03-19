#!/usr/bin/env bash

if [[ -z "${_BUILD_CORE_LOADED:-}" ]]; then
_BUILD_CORE_LOADED=1

declare -gA BUILD_TARGETS=()
declare -gA BUILD_TARGET_DEPS=()
declare -gA BUILD_TARGET_DESC=()
declare -gA BUILD_TARGET_FUNC=()
declare -gA BUILD_TARGET_PLUGIN=()
declare -ga BUILD_EXECUTED_TARGETS=()
declare -g BUILD_CURRENT_TARGET=""
declare -g BUILD_START_TIME=0
declare -g BUILD_END_TIME=0
declare -g BUILD_SUCCESS_COUNT=0
declare -g BUILD_FAIL_COUNT=0
declare -g BUILD_SKIP_COUNT=0
declare -g BUILD_RUNNING=false
declare -g BUILD_INTERRUPTED=false

declare -gA STEP_INFO=()
declare -g CURRENT_STEP=""
declare -g STEP_START_TIME=0

declare -g PARALLEL_ENABLED=true
declare -g PARALLEL_JOBS=4
declare -g PARALLEL_PIDS=()
declare -gA PARALLEL_RESULTS=()

build_init() {
    BUILD_START_TIME=$(date +%s)
    BUILD_EXECUTED_TARGETS=()
    BUILD_SUCCESS_COUNT=0
    BUILD_FAIL_COUNT=0
    BUILD_SKIP_COUNT=0
    BUILD_RUNNING=true
    BUILD_INTERRUPTED=false
    
    trap 'build_interrupt' INT TERM
}

build_cleanup() {
    BUILD_RUNNING=false
    trap - INT TERM
    
    if [[ ${#PARALLEL_PIDS[@]} -gt 0 ]]; then
        for pid in "${PARALLEL_PIDS[@]}"; do
            kill "$pid" 2>/dev/null
        done
        PARALLEL_PIDS=()
    fi
}

build_interrupt() {
    BUILD_INTERRUPTED=true
    output_error "$(i18n_get "build_interrupted")"
    build_cleanup
    exit 130
}

register_target() {
    local name="$1"
    local desc="${2:-$(i18n_get "no_description")}"
    local func="${3:-${name}_build}"
    local plugin="${4:-core}"
    
    BUILD_TARGETS["$name"]="$name"
    BUILD_TARGET_DESC["$name"]="$desc"
    BUILD_TARGET_FUNC["$name"]="$func"
    BUILD_TARGET_PLUGIN["$name"]="$plugin"
    
    if [[ -z "${BUILD_TARGET_DEPS[$name]:-}" ]]; then
        BUILD_TARGET_DEPS["$name"]=""
    fi
}

register_target_deps() {
    local name="$1"
    shift
    local deps=("$@")
    
    BUILD_TARGET_DEPS["$name"]=$(IFS=','; echo "${deps[*]}")
}

target_exists() {
    local name="$1"
    [[ -n "${BUILD_TARGETS[$name]:-}" ]]
}

get_target_func() {
    local name="$1"
    echo "${BUILD_TARGET_FUNC[$name]:-}"
}

get_target_deps() {
    local name="$1"
    echo "${BUILD_TARGET_DEPS[$name]:-}"
}

get_target_desc() {
    local name="$1"
    echo "${BUILD_TARGET_DESC[$name]:-}"
}

list_targets() {
    local verbose="${1:-false}"
    
    if [[ "$verbose" == "true" ]]; then
        output_header "$(i18n_get "available_targets")" 50
        for name in "${!BUILD_TARGETS[@]}"; do
            local desc="${BUILD_TARGET_DESC[$name]}"
            local deps="${BUILD_TARGET_DEPS[$name]}"
            local plugin="${BUILD_TARGET_PLUGIN[$name]}"
            
            output_key_value "$name" "$desc" 15
            [[ -n "$deps" ]] && output_bullet "$(i18n_get "dependencies"): ${deps}" 2
            output_bullet "$(i18n_get "plugin"): $plugin" 2
        done
    else
        for name in "${!BUILD_TARGETS[@]}"; do
            echo "$name - ${BUILD_TARGET_DESC[$name]}"
        done | sort
    fi
}

resolve_deps() {
    local target="$1"
    local resolved_var="$2"
    local visiting_var="$3"
    
    local visiting_value
    visiting_value=$(eval echo "\${${visiting_var}[$target]:-}")
    
    if [[ -n "$visiting_value" ]]; then
        output_error "$(i18n_get "circular_dependency")"
        return 1
    fi
    
    local resolved_value
    resolved_value=$(eval echo "\${${resolved_var}[$target]:-}")
    
    if [[ -n "$resolved_value" ]]; then
        return 0
    fi
    
    eval "${visiting_var}[$target]=1"
    
    local deps="${BUILD_TARGET_DEPS[$target]}"
    if [[ -n "$deps" ]]; then
        IFS=',' read -ra dep_array <<< "$deps"
        for dep in "${dep_array[@]}"; do
            dep=$(echo "$dep" | xargs)
            if [[ -n "$dep" ]]; then
                if ! target_exists "$dep"; then
                    output_error "$(i18n_get "unknown_dependency")"
                    return 1
                fi
                if ! resolve_deps "$dep" "$resolved_var" "$visiting_var"; then
                    return 1
                fi
            fi
        done
    fi
    
    eval "unset ${visiting_var}[$target]"
    eval "${resolved_var}[$target]=1"
    
    return 0
}

get_build_order() {
    local target="$1"
    
    declare -gA _BUILD_RESOLVED=()
    declare -gA _BUILD_VISITING=()
    
    if ! resolve_deps "$target" "_BUILD_RESOLVED" "_BUILD_VISITING"; then
        return 1
    fi
    
    local -a order=()
    local changed=true
    
    while [[ "$changed" == "true" ]]; do
        changed=false
        for t in "${!_BUILD_RESOLVED[@]}"; do
            local all_deps_met=true
            local deps="${BUILD_TARGET_DEPS[$t]}"
            
            if [[ -n "$deps" ]]; then
                IFS=',' read -ra dep_array <<< "$deps"
                for dep in "${dep_array[@]}"; do
                    dep=$(echo "$dep" | xargs)
                    if [[ -n "$dep" ]] && ! arr_contains "$dep" "${order[@]}"; then
                        all_deps_met=false
                        break
                    fi
                done
            fi
            
            if [[ "$all_deps_met" == "true" ]] && ! arr_contains "$t" "${order[@]}"; then
                order+=("$t")
                changed=true
            fi
        done
    done
    
    _BUILD_RESOLVED=()
    _BUILD_VISITING=()
    
    echo "${order[@]}"
}

execute_target() {
    local target="$1"
    
    if ! target_exists "$target"; then
        output_error "$(i18n_get "unknown_target"): $target"
        return 1
    fi
    
    if arr_contains "$target" "${BUILD_EXECUTED_TARGETS[@]}"; then
        return 0
    fi
    
    BUILD_CURRENT_TARGET="$target"
    local func="${BUILD_TARGET_FUNC[$target]}"
    
    if [[ -z "$func" ]] || ! declare -f "$func" &>/dev/null; then
        output_error "$(i18n_get "target_no_implementation"): $target"
        return 1
    fi
    
    output_section "$(i18n_get "building_target"): $target"
    
    local start_time
    start_time=$(date +%s)
    
    if $func; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        output_success "$(i18n_get "target_completed"): $target"
        ((BUILD_SUCCESS_COUNT++))
        BUILD_EXECUTED_TARGETS+=("$target")
        return 0
    else
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        output_error "$(i18n_get "target_failed"): $target"
        ((BUILD_FAIL_COUNT++))
        return 1
    fi
}

execute_target_with_deps() {
    local target="$1"
    
    if ! target_exists "$target"; then
        output_error "$(i18n_get "unknown_target"): $target"
        return 1
    fi
    
    local order
    order=$(get_build_order "$target")
    
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    local -a targets
    read -ra targets <<< "$order"
    
    local total=${#targets[@]}
    output_step_start $total
    
    for t in "${targets[@]}"; do
        if arr_contains "$t" "${BUILD_EXECUTED_TARGETS[@]}"; then
            output_step "$t" "skipped"
            ((BUILD_SKIP_COUNT++))
        else
            output_step "$t" "running"
            if execute_target "$t"; then
                output_step "$t" "success"
            else
                output_step "$t" "error"
                return 1
            fi
        fi
    done
    
    return 0
}

step_start() {
    local name="$1"
    CURRENT_STEP="$name"
    STEP_START_TIME=$(date +%s)
    
    STEP_INFO["name"]="$name"
    STEP_INFO["start_time"]=$STEP_START_TIME
    
    output_debug "$(i18n_get "starting_step"): $name"
}

step_end() {
    local success="${1:-true}"
    local name="${STEP_INFO[name]:-$CURRENT_STEP}"
    local start_time="${STEP_INFO[start_time]:-$STEP_START_TIME}"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [[ "$success" == "true" ]]; then
        output_debug "$(i18n_get "step_completed"): $name ($(format_duration $duration))"
    else
        output_debug "$(i18n_get "step_failed"): $name ($(format_duration $duration))"
    fi
    
    CURRENT_STEP=""
    STEP_INFO=()
}

step_skip() {
    local name="$1"
    local reason="${2:-$(i18n_get "no_reason")}"
    
    output_debug "$(i18n_get "skipping_step")"
    ((BUILD_SKIP_COUNT++))
}

compile_file() {
    local src="$1"
    local dest="$2"
    local action="${3:-$(i18n_get "compiling")}"
    
    if [[ ! -f "$src" ]]; then
        output_file_status "$src" "$dest" "error"
        output_error "$(i18n_get "source_file_not_found")"
        return 1
    fi
    
    output_file_status "$src" "$dest" "processing"
    
    local dest_dir
    dest_dir=$(dirname "$dest")
    ensure_dir "$dest_dir"
    
    return 0
}

file_needs_rebuild() {
    local src="$1"
    local dest="$2"
    
    if [[ ! -f "$dest" ]]; then
        return 0
    fi
    
    if [[ "$src" -nt "$dest" ]]; then
        return 0
    fi
    
    return 1
}

parallel_init() {
    PARALLEL_ENABLED=true
    PARALLEL_JOBS="${1:-$(nproc 2>/dev/null || echo 4)}"
    PARALLEL_PIDS=()
    PARALLEL_RESULTS=()
}

parallel_run() {
    local func="$1"
    shift
    local args=("$@")
    
    while [[ ${#PARALLEL_PIDS[@]} -ge $PARALLEL_JOBS ]]; do
        parallel_wait_one
    done
    
    (
        $func "${args[@]}"
        echo $? > "/tmp/build_parallel_$$_$RANDOM"
    ) &
    PARALLEL_PIDS+=($!)
}

parallel_wait_one() {
    if [[ ${#PARALLEL_PIDS[@]} -eq 0 ]]; then
        return
    fi
    
    local pid
    for pid in "${PARALLEL_PIDS[@]}"; do
        if ! kill -0 "$pid" 2>/dev/null; then
            wait "$pid"
            local status=$?
            
            local new_pids=()
            for p in "${PARALLEL_PIDS[@]}"; do
                [[ "$p" != "$pid" ]] && new_pids+=("$p")
            done
            PARALLEL_PIDS=("${new_pids[@]}")
            
            return $status
        fi
    done
    
    wait "${PARALLEL_PIDS[0]}"
    local status=$?
    
    local new_pids=("${PARALLEL_PIDS[@]:1}")
    PARALLEL_PIDS=("${new_pids[@]}")
    
    return $status
}

parallel_wait_all() {
    local failed=0
    
    while [[ ${#PARALLEL_PIDS[@]} -gt 0 ]]; do
        if ! parallel_wait_one; then
            ((failed++))
        fi
    done
    
    return $failed
}

build_summary() {
    BUILD_END_TIME=$(date +%s)
    local duration=$((BUILD_END_TIME - BUILD_START_TIME))
    
    output_summary "$(i18n_get "build_summary")" \
        "$BUILD_SUCCESS_COUNT" \
        "$BUILD_FAIL_COUNT" \
        "$BUILD_SKIP_COUNT" \
        "$(format_duration $duration)"
}

build_result() {
    if [[ $BUILD_FAIL_COUNT -gt 0 ]]; then
        return 1
    fi
    return 0
}

clean_target() {
    local target="$1"
    local dirs="${2:-build}"
    
    output_section "$(i18n_get "cleaning_target")"
    
    IFS=',' read -ra dir_array <<< "$dirs"
    for dir in "${dir_array[@]}"; do
        dir=$(echo "$dir" | xargs)
        if [[ -d "$dir" ]]; then
            output_info "$(i18n_get "removing_dir")"
            rm -rf "$dir"
        fi
    done
    
    output_success "$(i18n_get "clean_completed")"
}

check_dependencies() {
    local -a missing=()
    
    for dep in "$@"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        output_error "$(i18n_get "missing_dependencies")"
        output_info "$(i18n_get "install_dependencies")"
        return 1
    fi
    
    return 0
}

ensure_dependencies() {
    local -a to_install=()
    
    for dep in "$@"; do
        if ! command_exists "$dep"; then
            to_install+=("$dep")
        fi
    done
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        output_info "$(i18n_get "installing_dependencies")"
        platform_install "${to_install[@]}"
    fi
}

run_hook() {
    local hook_name="$1"
    shift
    local args=("$@")
    
    local hook_func="${hook_name}_hook"
    
    if declare -f "$hook_func" &>/dev/null; then
        output_debug "$(i18n_get "running_hook")"
        $hook_func "${args[@]}"
        return $?
    fi
    
    return 0
}

build_finalize() {
    build_cleanup
    build_summary
    return $(build_result)
}

fi
