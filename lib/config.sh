#!/usr/bin/env bash

if [[ -z "${_BUILD_CONFIG_LOADED:-}" ]]; then
_BUILD_CONFIG_LOADED=1

declare -gA CONFIG_VALUES=()
declare -gA CONFIG_DEFAULTS=()
declare -g CONFIG_FILE=""
declare -g CONFIG_PROJECT_DIR=""
declare -g CONFIG_ENV_PREFIX="BUILD_"

declare -g PROJECT_CONFIG_FILE=""
declare -g PROJECT_DIR=""
declare -g PROJECT_NAME=""
declare -g PROJECT_VERSION=""
declare -g SOURCE_DIR=""
declare -g BUILD_DIR=""

config_set_default() {
    local key="$1"
    local value="$2"
    CONFIG_DEFAULTS["$key"]="$value"
}

config_get() {
    local key="$1"
    local default="${2:-${CONFIG_DEFAULTS[$key]:-}}"
    
    key=$(config_normalize_key "$key")
    
    if [[ -n "${CONFIG_VALUES[$key]:-}" ]]; then
        echo "${CONFIG_VALUES[$key]}"
    else
        echo "$default"
    fi
}

config_set() {
    local key="$1"
    local value="$2"
    
    key=$(config_normalize_key "$key")
    CONFIG_VALUES["$key"]="$value"
}

config_unset() {
    local key="$1"
    key=$(config_normalize_key "$key")
    unset "CONFIG_VALUES[$key]"
}

config_has() {
    local key="$1"
    key=$(config_normalize_key "$key")
    [[ -n "${CONFIG_VALUES[$key]:-}" ]]
}

config_normalize_key() {
    local key="$1"
    key="${key//./_}"
    key="${key//-/_}"
    echo "${key^^}"
}

config_load_file() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    CONFIG_FILE="$file"
    
    local section=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        [[ -z "$line" ]] && continue
        [[ "$line" == \#* ]] && continue
        
        if [[ "$line" == \[*\] ]]; then
            section="${line#[}"
            section="${section%]}"
            continue
        fi
        
        if [[ "$line" == *=* ]]; then
            local key="${line%%=*}"
            local value="${line#*=}"
            
            key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            if [[ "$value" == \"*\" ]] || [[ "$value" == \'*\' ]]; then
                value="${value:1:${#value}-2}"
            fi
            
            if [[ -n "$section" ]]; then
                key="${section}_${key}"
            fi
            
            config_set "$key" "$value"
        fi
    done < "$file"
    
    return 0
}

config_load_env() {
    local prefix="${1:-$CONFIG_ENV_PREFIX}"
    
    while IFS= read -r line; do
        if [[ "$line" == ${prefix}* ]]; then
            local key="${line%%=*}"
            local value="${line#*=}"
            
            key="${key#$prefix}"
            
            if [[ "$value" == \"*\" ]] || [[ "$value" == \'*\' ]]; then
                value="${value:1:${#value}-2}"
            fi
            
            config_set "$key" "$value"
        fi
    done < <(env)
}

config_load_env_file() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        [[ -z "$line" ]] && continue
        [[ "$line" == \#* ]] && continue
        
        if [[ "$line" == *=* ]]; then
            local key="${line%%=*}"
            local value="${line#*=}"
            
            key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            if [[ "$value" == \"*\" ]] || [[ "$value" == \'*\' ]]; then
                value="${value:1:${#value}-2}"
            fi
            
            export "$key"="$value"
            config_set "$key" "$value"
        fi
    done < "$file"
    
    return 0
}

config_save_file() {
    local file="${1:-$CONFIG_FILE}"
    
    if [[ -z "$file" ]]; then
        return 1
    fi
    
    local dir
    dir=$(dirname "$file")
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi
    
    local current_section=""
    local sorted_keys
    sorted_keys=$(printf '%s\n' "${!CONFIG_VALUES[@]}" | sort)
    
    {
        echo "# Build Tool Configuration"
        echo "# Generated: $(date)"
        echo ""
        
        for key in $sorted_keys; do
            local section="${key%%_*}"
            local subkey="${key#*_}"
            
            if [[ "$section" != "$current_section" ]]; then
                echo ""
                echo "[$section]"
                current_section="$section"
            fi
            
            echo "$subkey = \"${CONFIG_VALUES[$key]}\""
        done
    } > "$file"
    
    return 0
}

config_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --*=*)
                local key="${1#--}"
                key="${key%%=*}"
                local value="${1#*=}"
                config_set "$key" "$value"
                shift
                ;;
            --*)
                local key="${1#--}"
                if [[ $# -gt 1 ]] && [[ "$2" != --* ]]; then
                    config_set "$key" "$2"
                    shift 2
                else
                    config_set "$key" "true"
                    shift
                fi
                ;;
            -*)
                local key="${1#-}"
                if [[ ${#key} -eq 1 ]]; then
                    if [[ $# -gt 1 ]] && [[ "$2" != -* ]]; then
                        config_set "$key" "$2"
                        shift 2
                    else
                        config_set "$key" "true"
                        shift
                    fi
                else
                    config_set "$key" "true"
                    shift
                fi
                ;;
            *)
                shift
                ;;
        esac
    done
}

config_get_bool() {
    local key="$1"
    local default="${2:-false}"
    
    local value
    value=$(config_get "$key" "$default")
    
    case "${value,,}" in
        true|1|yes|on|y)
            return 0
            ;;
        false|0|no|off|n)
            return 1
            ;;
        *)
            if [[ -n "$value" ]]; then
                return 0
            else
                return 1
            fi
            ;;
    esac
}

config_get_int() {
    local key="$1"
    local default="${2:-0}"
    
    local value
    value=$(config_get "$key" "$default")
    
    if [[ "$value" =~ ^-?[0-9]+$ ]]; then
        echo "$value"
    else
        echo "$default"
    fi
}

config_get_array() {
    local key="$1"
    local delim="${2:-,}"
    local -n result_array="$3"
    
    local value
    value=$(config_get "$key")
    
    if [[ -n "$value" ]]; then
        IFS="$delim" read -ra result_array <<< "$value"
    else
        result_array=()
    fi
}

config_set_array() {
    local key="$1"
    local delim="${2:-,}"
    shift 2
    local value
    value=$(IFS="$delim"; echo "$*")
    config_set "$key" "$value"
}

config_list() {
    local prefix="${1:-}"
    
    for key in "${!CONFIG_VALUES[@]}"; do
        if [[ -z "$prefix" ]] || [[ "$key" == ${prefix^^}* ]]; then
            echo "$key = ${CONFIG_VALUES[$key]}"
        fi
    done
}

config_list_defaults() {
    local prefix="${1:-}"
    
    for key in "${!CONFIG_DEFAULTS[@]}"; do
        if [[ -z "$prefix" ]] || [[ "$key" == ${prefix^^}* ]]; then
            echo "$key = ${CONFIG_DEFAULTS[$key]} (default)"
        fi
    done
}

config_find_project_dir() {
    local current_dir="${1:-$(pwd)}"
    local markers=("build.sh" "build.conf" ".build" "build.toml" "build.yaml" "build.yml" "build.json")
    
    while [[ "$current_dir" != "/" ]]; do
        for marker in "${markers[@]}"; do
            if [[ -f "$current_dir/$marker" ]]; then
                CONFIG_PROJECT_DIR="$current_dir"
                echo "$current_dir"
                return 0
            fi
        done
        
        current_dir=$(dirname "$current_dir")
    done
    
    CONFIG_PROJECT_DIR=""
    return 1
}

config_init() {
    local project_dir="${1:-$(pwd)}"
    
    config_find_project_dir "$project_dir"
    
    local config_files=(
        "${project_dir}/build.conf"
        "${project_dir}/.build"
        "${project_dir}/config/build.conf"
        "${project_dir}/.build/config.conf"
    )
    
    for file in "${config_files[@]}"; do
        if [[ -f "$file" ]]; then
            config_load_file "$file"
            break
        fi
    done
    
    if [[ -f "${project_dir}/.env" ]]; then
        config_load_env_file "${project_dir}/.env"
    fi
    
    config_load_env
}

config_validate() {
    local -a required=("$@")
    local -a missing=()
    
    for key in "${required[@]}"; do
        if ! config_has "$key"; then
            missing+=("$key")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Missing required configuration: ${missing[*]}" >&2
        return 1
    fi
    
    return 0
}

config_template() {
    local template="$1"
    local result="$template"
    local max_iterations=100
    local iteration=0
    
    while [[ "$result" =~ \$\{([a-zA-Z_][a-zA-Z0-9_]*)\} ]]; do
        ((iteration++))
        if [[ $iteration -gt $max_iterations ]]; then
            break
        fi
        
        local var="${BASH_REMATCH[1]}"
        local value
        value=$(config_get "$var" "")
        
        if [[ -z "$value" ]]; then
            result="${result//\$\{$var\}/}"
        else
            local new_result="${result//\$\{$var\}/$value}"
            if [[ "$new_result" == "$result" ]]; then
                break
            fi
            result="$new_result"
        fi
    done
    
    iteration=0
    while [[ "$result" =~ \$([a-zA-Z_][a-zA-Z0-9_]*) ]]; do
        ((iteration++))
        if [[ $iteration -gt $max_iterations ]]; then
            break
        fi
        
        local var="${BASH_REMATCH[1]}"
        local value
        value=$(config_get "$var" "")
        
        if [[ -z "$value" ]]; then
            result="${result//\$$var/}"
        else
            local new_result="${result//\$$var/$value}"
            if [[ "$new_result" == "$result" ]]; then
                break
            fi
            result="$new_result"
        fi
    done
    
    echo "$result"
}

config_dump() {
    echo "# Current Configuration"
    echo ""
    
    echo "## Values"
    for key in $(printf '%s\n' "${!CONFIG_VALUES[@]}" | sort); do
        echo "  $key = '${CONFIG_VALUES[$key]}'"
    done
    
    echo ""
    echo "## Defaults"
    for key in $(printf '%s\n' "${!CONFIG_DEFAULTS[@]}" | sort); do
        echo "  $key = '${CONFIG_DEFAULTS[$key]}'"
    done
}

config_set_defaults() {
    config_set_default "VERBOSE" "false"
    config_set_default "QUIET" "false"
    config_set_default "COLOR" "true"
    config_set_default "UNICODE" "true"
    config_set_default "LOG_LEVEL" "INFO"
    config_set_default "LOG_FILE" ""
    config_set_default "CACHE_DIR" ""
    config_set_default "BUILD_DIR" "output"
    config_set_default "SOURCE_DIR" "src"
    config_set_default "PARALLEL" "true"
    config_set_default "JOBS" "4"
    config_set_default "INCREMENTAL" "true"
    config_set_default "PROJECT_NAME" ""
    config_set_default "PROJECT_VERSION" "1.0.0"
}

config_set_defaults

fi
