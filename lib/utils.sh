#!/usr/bin/env bash

BUILD_TOOL_VERSION="1.0.0"
BUILD_TOOL_NAME="build-tool"

if [[ -z "${_BUILD_UTILS_LOADED:-}" ]]; then
_BUILD_UTILS_LOADED=1

str_trim() {
    local var="$1"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

str_split() {
    local str="$1"
    local delim="${2:-:}"
    local -n result_array="$3"
    
    local IFS="$delim"
    read -ra result_array <<< "$str"
}

str_join() {
    local delim="$1"
    shift
    local first="$1"
    shift
    
    printf '%s' "$first"
    [[ $# -gt 0 ]] && printf '%s%s' "$delim" "$@"
}

str_lower() {
    printf '%s' "${1,,}"
}

str_upper() {
    printf '%s' "${1^^}"
}

str_starts_with() {
    local str="$1"
    local prefix="$2"
    [[ "$str" == "$prefix"* ]]
}

str_ends_with() {
    local str="$1"
    local suffix="$2"
    [[ "$str" == *"$suffix" ]]
}

str_contains() {
    local str="$1"
    local substr="$2"
    [[ "$str" == *"$substr"* ]]
}

arr_contains() {
    local needle="$1"
    shift
    local item
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

arr_unique() {
    local -n input_arr="$1"
    local -n output_arr="$2"
    local seen=()
    output_arr=()
    
    for item in "${input_arr[@]}"; do
        if ! arr_contains "$item" "${seen[@]}"; then
            seen+=("$item")
            output_arr+=("$item")
        fi
    done
}

arr_filter() {
    local -n input_arr="$1"
    local -n output_arr="$2"
    local filter_func="$3"
    output_arr=()
    
    for item in "${input_arr[@]}"; do
        if $filter_func "$item"; then
            output_arr+=("$item")
        fi
    done
}

arr_map() {
    local -n input_arr="$1"
    local -n output_arr="$2"
    local map_func="$3"
    output_arr=()
    
    for item in "${input_arr[@]}"; do
        output_arr+=("$($map_func "$item")")
    done
}

arr_length() {
    local -n arr="$1"
    echo "${#arr[@]}"
}

arr_first() {
    local -n arr="$1"
    echo "${arr[0]}"
}

arr_last() {
    local -n arr="$1"
    echo "${arr[-1]}"
}

ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi
}

file_exists() {
    [[ -f "$1" ]]
}

dir_exists() {
    [[ -d "$1" ]]
}

file_readable() {
    [[ -r "$1" ]]
}

file_writable() {
    [[ -w "$1" ]]
}

file_executable() {
    [[ -x "$1" ]]
}

safe_copy() {
    local src="$1"
    local dest="$2"
    local backup="${3:-true}"
    
    if [[ ! -f "$src" ]]; then
        return 1
    fi
    
    if [[ -f "$dest" ]] && [[ "$backup" == "true" ]]; then
        mv "$dest" "${dest}.bak.$(date +%Y%m%d%H%M%S)"
    fi
    
    local dest_dir
    dest_dir=$(dirname "$dest")
    ensure_dir "$dest_dir"
    
    cp "$src" "$dest"
}

safe_move() {
    local src="$1"
    local dest="$2"
    local backup="${3:-true}"
    
    if [[ ! -f "$src" ]]; then
        return 1
    fi
    
    if [[ -f "$dest" ]] && [[ "$backup" == "true" ]]; then
        mv "$dest" "${dest}.bak.$(date +%Y%m%d%H%M%S)"
    fi
    
    local dest_dir
    dest_dir=$(dirname "$dest")
    ensure_dir "$dest_dir"
    
    mv "$src" "$dest"
}

safe_delete() {
    local target="$1"
    
    if [[ -f "$target" ]]; then
        rm -f "$target"
    elif [[ -d "$target" ]]; then
        rm -rf "$target"
    fi
}

file_size() {
    local file="$1"
    if [[ -f "$file" ]]; then
        stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || wc -c < "$file"
    else
        echo "0"
    fi
}

file_size_human() {
    local bytes
    bytes=$(file_size "$1")
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0
    local size=$bytes
    
    while (( size > 1024 && unit < 4 )); do
        size=$((size / 1024))
        ((unit++))
    done
    
    echo "${size}${units[$unit]}"
}

file_hash() {
    local file="$1"
    local algorithm="${2:-md5}"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    case "$algorithm" in
        md5)
            md5sum "$file" 2>/dev/null | cut -d' ' -f1 || md5 -q "$file" 2>/dev/null
            ;;
        sha1)
            sha1sum "$file" 2>/dev/null | cut -d' ' -f1 || shasum -a 1 "$file" 2>/dev/null | cut -d' ' -f1
            ;;
        sha256)
            sha256sum "$file" 2>/dev/null | cut -d' ' -f1 || shasum -a 256 "$file" 2>/dev/null | cut -d' ' -f1
            ;;
        *)
            return 1
            ;;
    esac
}

format_duration() {
    local seconds="$1"
    local days=$((seconds / 86400))
    local hours=$(( (seconds % 86400) / 3600 ))
    local minutes=$(( (seconds % 3600) / 60 ))
    local secs=$((seconds % 60))
    
    local result=""
    [[ $days -gt 0 ]] && result+="${days}d "
    [[ $hours -gt 0 ]] && result+="${hours}h "
    [[ $minutes -gt 0 ]] && result+="${minutes}m "
    result+="${secs}s"
    
    echo "$result"
}

format_timestamp() {
    local ts="${1:-$(date +%s)}"
    local format="${2:-%Y-%m-%d %H:%M:%S}"
    date -d "@$ts" "+$format" 2>/dev/null || date -r "$ts" "+$format" 2>/dev/null
}

current_timestamp() {
    date +%s
}

current_datetime() {
    date "+%Y-%m-%d %H:%M:%S"
}

json_get() {
    local json="$1"
    local key="$2"
    
    if command -v jq &>/dev/null; then
        echo "$json" | jq -r ".$key // empty"
    else
        local pattern="\"$key\"[[:space:]]*:[[:space:]]*\"([^\"]*)\""
        if [[ "$json" =~ $pattern ]]; then
            echo "${BASH_REMATCH[1]}"
        else
            pattern="\"$key\"[[:space:]]*:[[:space:]]*([^,}]*)"
            if [[ "$json" =~ $pattern ]]; then
                echo "${BASH_REMATCH[1]}" | tr -d '[:space:]'
            fi
        fi
    fi
}

json_set() {
    local json="$1"
    local key="$2"
    local value="$3"
    
    if command -v jq &>/dev/null; then
        echo "$json" | jq --arg k "$key" --arg v "$value" '.[$k] = $v'
    else
        echo "$json" | sed "s/\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"$key\": \"$value\"/"
    fi
}

is_number() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

is_integer() {
    [[ "$1" =~ ^-?[0-9]+$ ]]
}

is_float() {
    [[ "$1" =~ ^-?[0-9]+\.?[0-9]*$ ]]
}

is_bool() {
    [[ "$1" == "true" || "$1" == "false" || "$1" == "1" || "$1" == "0" ]]
}

to_bool() {
    local value="$1"
    case "${value,,}" in
        true|1|yes|on|y)
            echo "true"
            ;;
        *)
            echo "false"
            ;;
    esac
}

clamp() {
    local value="$1"
    local min="$2"
    local max="$3"
    
    ((value < min)) && value=$min
    ((value > max)) && value=$max
    echo "$value"
}

min() {
    local a="$1"
    local b="$2"
    ((a < b)) && echo "$a" || echo "$b"
}

max() {
    local a="$1"
    local b="$2"
    ((a > b)) && echo "$a" || echo "$b"
}

abs() {
    local n="$1"
    ((n < 0)) && echo $(( -n )) || echo "$n"
}

random_string() {
    local length="${1:-16}"
    tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$length"
}

uuid() {
    if command -v uuidgen &>/dev/null; then
        uuidgen
    else
        printf '%04x%04x-%04x-%04x-%04x-%04x%04x%04x' \
            $RANDOM $RANDOM \
            $RANDOM \
            $(($RANDOM & 0x0fff | 0x4000)) \
            $(($RANDOM & 0x3fff | 0x8000)) \
            $RANDOM $RANDOM $RANDOM
    fi
}

retry() {
    local max_attempts="${1:-3}"
    local delay="${2:-1}"
    shift 2
    local cmd=("$@")
    
    local attempt=1
    while [[ $attempt -le $max_attempts ]]; do
        if "${cmd[@]}"; then
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            sleep "$delay"
        fi
        ((attempt++))
    done
    
    return 1
}

timeout_exec() {
    local timeout_sec="$1"
    shift
    
    if command -v timeout &>/dev/null; then
        timeout "$timeout_sec" "$@"
    else
        local pid
        "$@" &
        pid=$!
        
        (
            sleep "$timeout_sec"
            kill "$pid" 2>/dev/null
        ) &
        local timer_pid=$!
        
        wait "$pid" 2>/dev/null
        local status=$?
        kill "$timer_pid" 2>/dev/null
        return $status
    fi
}

get_script_dir() {
    local source="${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}"
    local dir
    while [[ -L "$source" ]]; do
        dir=$(cd -P "$(dirname "$source")" &>/dev/null && pwd)
        source=$(readlink "$source")
        [[ "$source" != /* ]] && source="$dir/$source"
    done
    dir=$(cd -P "$(dirname "$source")" &>/dev/null && pwd)
    echo "$dir"
}

get_script_name() {
    basename "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}"
}

fi
