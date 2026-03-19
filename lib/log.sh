#!/usr/bin/env bash

if [[ -z "${_BUILD_LOG_LOADED:-}" ]]; then
_BUILD_LOG_LOADED=1

declare -g LOG_LEVEL_DEBUG=0
declare -g LOG_LEVEL_INFO=1
declare -g LOG_LEVEL_WARN=2
declare -g LOG_LEVEL_ERROR=3
declare -g LOG_LEVEL_NONE=99

declare -g LOG_CURRENT_LEVEL=$LOG_LEVEL_INFO
declare -g LOG_FILE=""
declare -g LOG_MAX_SIZE=10485760
declare -g LOG_MAX_FILES=5
declare -g LOG_TO_FILE=false
declare -g LOG_TO_CONSOLE=true
declare -g LOG_FORMAT="[%TIMESTAMP%] [%LEVEL%] %MESSAGE%"
declare -g LOG_DATE_FORMAT="%Y-%m-%d %H:%M:%S"
declare -g LOG_CONTEXT=""

log_set_level() {
    local level="$1"
    case "${level,,}" in
        debug)
            LOG_CURRENT_LEVEL=$LOG_LEVEL_DEBUG
            ;;
        info)
            LOG_CURRENT_LEVEL=$LOG_LEVEL_INFO
            ;;
        warn|warning)
            LOG_CURRENT_LEVEL=$LOG_LEVEL_WARN
            ;;
        error)
            LOG_CURRENT_LEVEL=$LOG_LEVEL_ERROR
            ;;
        none|quiet)
            LOG_CURRENT_LEVEL=$LOG_LEVEL_NONE
            ;;
        *)
            if [[ "$level" =~ ^[0-9]+$ ]]; then
                LOG_CURRENT_LEVEL=$level
            fi
            ;;
    esac
}

log_set_file() {
    local file="$1"
    local enable="${2:-true}"
    
    LOG_FILE="$file"
    LOG_TO_FILE="$enable"
    
    if [[ "$LOG_TO_FILE" == "true" ]] && [[ -n "$LOG_FILE" ]]; then
        local dir
        dir=$(dirname "$LOG_FILE")
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
        fi
    fi
}

log_set_console() {
    local enable="$1"
    LOG_TO_CONSOLE="$enable"
}

log_set_max_size() {
    local size="$1"
    LOG_MAX_SIZE=$size
}

log_set_max_files() {
    local count="$1"
    LOG_MAX_FILES=$count
}

log_set_context() {
    local context="$1"
    LOG_CONTEXT="$context"
}

log_format_message() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date "+$LOG_DATE_FORMAT")
    
    local formatted="$LOG_FORMAT"
    formatted="${formatted//%TIMESTAMP%/$timestamp}"
    formatted="${formatted//%LEVEL%/$level}"
    formatted="${formatted//%MESSAGE%/$message}"
    
    if [[ -n "$LOG_CONTEXT" ]]; then
        formatted="${formatted//%CONTEXT%/$LOG_CONTEXT}"
    fi
    
    echo "$formatted"
}

_log_rotate() {
    if [[ ! -f "$LOG_FILE" ]]; then
        return
    fi
    
    local size
    size=$(stat -c%s "$LOG_FILE" 2>/dev/null || stat -f%z "$LOG_FILE" 2>/dev/null || echo 0)
    
    if [[ $size -ge $LOG_MAX_SIZE ]]; then
        local i=$LOG_MAX_FILES
        while [[ $i -gt 0 ]]; do
            local old_file="${LOG_FILE}.${i}"
            local new_file="${LOG_FILE}.$((i+1))"
            
            if [[ -f "$old_file" ]]; then
                if [[ $i -eq $LOG_MAX_FILES ]]; then
                    rm -f "$old_file"
                else
                    mv "$old_file" "$new_file"
                fi
            fi
            ((i--))
        done
        
        mv "$LOG_FILE" "${LOG_FILE}.1"
    fi
}

_log_write() {
    local level="$1"
    local level_num="$2"
    local message="$3"
    
    if [[ $level_num -lt $LOG_CURRENT_LEVEL ]]; then
        return
    fi
    
    local formatted
    formatted=$(log_format_message "$level" "$message")
    
    if [[ "$LOG_TO_CONSOLE" == "true" ]]; then
        case "$level" in
            DEBUG)
                echo -e "\033[2m${formatted}\033[0m" >&2
                ;;
            INFO)
                echo -e "\033[34m${formatted}\033[0m"
                ;;
            WARN)
                echo -e "\033[33m${formatted}\033[0m" >&2
                ;;
            ERROR)
                echo -e "\033[31m${formatted}\033[0m" >&2
                ;;
            *)
                echo "$formatted"
                ;;
        esac
    fi
    
    if [[ "$LOG_TO_FILE" == "true" ]] && [[ -n "$LOG_FILE" ]]; then
        _log_rotate
        echo "$formatted" >> "$LOG_FILE"
    fi
}

log_debug() {
    local message="$1"
    shift
    if [[ $# -gt 0 ]]; then
        message=$(printf "$message" "$@")
    fi
    _log_write "DEBUG" $LOG_LEVEL_DEBUG "$message"
}

log_info() {
    local message="$1"
    shift
    if [[ $# -gt 0 ]]; then
        message=$(printf "$message" "$@")
    fi
    _log_write "INFO" $LOG_LEVEL_INFO "$message"
}

log_warn() {
    local message="$1"
    shift
    if [[ $# -gt 0 ]]; then
        message=$(printf "$message" "$@")
    fi
    _log_write "WARN" $LOG_LEVEL_WARN "$message"
}

log_error() {
    local message="$1"
    shift
    if [[ $# -gt 0 ]]; then
        message=$(printf "$message" "$@")
    fi
    _log_write "ERROR" $LOG_LEVEL_ERROR "$message"
}

log_fatal() {
    local message="$1"
    shift
    if [[ $# -gt 0 ]]; then
        message=$(printf "$message" "$@")
    fi
    _log_write "ERROR" $LOG_LEVEL_ERROR "$message"
    exit 1
}

log_exception() {
    local message="$1"
    local line="${2:-${BASH_LINENO[0]}}"
    local func="${3:-${FUNCNAME[1]}}"
    local file="${4:-${BASH_SOURCE[1]}}"
    
    local full_message="${message}"
    full_message+="\n  at ${func}() (${file##*/}:${line})"
    
    local i=1
    while [[ -n "${BASH_LINENO[$i]:-}" ]]; do
        full_message+="\n  at ${FUNCNAME[$((i+1))]:-main}() (${BASH_SOURCE[$((i+1))]##*/}:${BASH_LINENO[$i]})"
        ((i++))
    done
    
    _log_write "ERROR" $LOG_LEVEL_ERROR "$full_message"
}

log_stack_trace() {
    local message="${1:-Stack trace}"
    
    log_error "$message"
    
    local i=1
    while [[ -n "${BASH_LINENO[$i]:-}" ]]; do
        log_error "  at ${FUNCNAME[$((i+1))]:-main}() (${BASH_SOURCE[$((i+1))]##*/}:${BASH_LINENO[$i]})"
        ((i++))
    done
}

log_section() {
    local title="$1"
    log_info ""
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "  $title"
    log_info "═══════════════════════════════════════════════════════════════"
}

log_command() {
    local description="$1"
    shift
    log_debug "Executing: $description"
    log_debug "  Command: $*"
}

log_result() {
    local success="$1"
    local message="$2"
    
    if [[ "$success" == "true" ]] || [[ "$success" -eq 0 ]]; then
        log_info "✓ $message"
    else
        log_error "✗ $message"
    fi
}

log_measure() {
    local description="$1"
    shift
    local start_time
    start_time=$(date +%s%N)
    
    "$@"
    local exit_code=$?
    
    local end_time
    end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))
    
    log_debug "$description completed in ${duration}ms"
    
    return $exit_code
}

log_group_start() {
    local name="$1"
    log_info "┌─ $name ───────────────────────────────────────────────────────"
}

log_group_end() {
    log_info "└────────────────────────────────────────────────────────────────"
}

log_var() {
    local name="$1"
    local value="${!1}"
    log_debug "$name = $value"
}

log_array() {
    local -n arr="$1"
    log_debug "Array $1:"
    for i in "${!arr[@]}"; do
        log_debug "  [$i] = ${arr[$i]}"
    done
}

log_clear() {
    if [[ -f "$LOG_FILE" ]]; then
        > "$LOG_FILE"
    fi
}

log_get_file() {
    echo "$LOG_FILE"
}

log_get_level_name() {
    case $LOG_CURRENT_LEVEL in
        $LOG_LEVEL_DEBUG) echo "DEBUG" ;;
        $LOG_LEVEL_INFO)  echo "INFO" ;;
        $LOG_LEVEL_WARN)  echo "WARN" ;;
        $LOG_LEVEL_ERROR) echo "ERROR" ;;
        $LOG_LEVEL_NONE)  echo "NONE" ;;
        *) echo "UNKNOWN" ;;
    esac
}

fi
