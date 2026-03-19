#!/usr/bin/env bash

if [[ -z "${_BUILD_OUTPUT_LOADED:-}" ]]; then
_BUILD_OUTPUT_LOADED=1

declare -g OUTPUT_USE_COLOR=true
declare -g OUTPUT_USE_UNICODE=true
declare -g OUTPUT_VERBOSE=false
declare -g OUTPUT_QUIET=false
declare -g OUTPUT_TIMESTAMP=false
declare -g OUTPUT_PROGRESS_CURRENT=0
declare -g OUTPUT_PROGRESS_TOTAL=0
declare -g OUTPUT_STEP_CURRENT=0
declare -g OUTPUT_STEP_TOTAL=0
declare -g OUTPUT_SPINNER_PID=""
declare -g OUTPUT_SPINNER_CHARS=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
declare -g OUTPUT_SPINNER_IDX=0

if [[ "$OUTPUT_USE_UNICODE" != "true" ]]; then
    OUTPUT_SPINNER_CHARS=('-' '\' '|' '/')
fi

COLOR_RESET=""
COLOR_BOLD=""
COLOR_DIM=""
COLOR_RED=""
COLOR_GREEN=""
COLOR_YELLOW=""
COLOR_BLUE=""
COLOR_MAGENTA=""
COLOR_CYAN=""
COLOR_WHITE=""

output_init_colors() {
    if [[ "$OUTPUT_USE_COLOR" == "true" ]] && [[ -t 1 ]]; then
        COLOR_RESET=$'\033[0m'
        COLOR_BOLD=$'\033[1m'
        COLOR_DIM=$'\033[2m'
        COLOR_RED=$'\033[31m'
        COLOR_GREEN=$'\033[32m'
        COLOR_YELLOW=$'\033[33m'
        COLOR_BLUE=$'\033[34m'
        COLOR_MAGENTA=$'\033[35m'
        COLOR_CYAN=$'\033[36m'
        COLOR_WHITE=$'\033[37m'
    fi
}

output_set_color() {
    local enable="$1"
    OUTPUT_USE_COLOR="$enable"
    output_init_colors
}

output_set_unicode() {
    local enable="$1"
    OUTPUT_USE_UNICODE="$enable"
    if [[ "$OUTPUT_USE_UNICODE" != "true" ]]; then
        OUTPUT_SPINNER_CHARS=('-' '\' '|' '/')
    else
        OUTPUT_SPINNER_CHARS=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    fi
}

output_set_verbose() {
    OUTPUT_VERBOSE=true
}

output_set_quiet() {
    OUTPUT_QUIET=true
}

output_set_timestamp() {
    OUTPUT_TIMESTAMP=true
}

_output_prefix() {
    local prefix=""
    if [[ "$OUTPUT_TIMESTAMP" == "true" ]]; then
        prefix="[$(date '+%H:%M:%S')] "
    fi
    echo -n "$prefix"
}

_output_write() {
    if [[ "$OUTPUT_QUIET" != "true" ]]; then
        echo -e "$@"
    fi
}

output_print() {
    local msg="$1"
    _output_write "$(_output_prefix)${msg}${COLOR_RESET}"
}

output_info() {
    local msg="$1"
    _output_write "$(_output_prefix)${COLOR_BLUE}ℹ${COLOR_RESET} ${msg}"
}

output_success() {
    local msg="$1"
    _output_write "$(_output_prefix)${COLOR_GREEN}✓${COLOR_RESET} ${msg}"
}

output_warning() {
    local msg="$1"
    _output_write "$(_output_prefix)${COLOR_YELLOW}⚠${COLOR_RESET} ${msg}"
}

output_error() {
    local msg="$1"
    _output_write "$(_output_prefix)${COLOR_RED}✗${COLOR_RESET} ${msg}" >&2
}

output_debug() {
    if [[ "$OUTPUT_VERBOSE" == "true" ]]; then
        local msg="$1"
        _output_write "$(_output_prefix)${COLOR_DIM}⚙${COLOR_RESET} ${msg}"
    fi
}

output_header() {
    local title="$1"
    local width="${2:-60}"
    local border
    border=$(printf '═%.0s' $(seq 1 $width))
    
    _output_write ""
    _output_write "${COLOR_CYAN}╔${border}╗${COLOR_RESET}"
    _output_write "${COLOR_CYAN}║${COLOR_RESET} ${COLOR_BOLD}${title}${COLOR_RESET}"
    _output_write "${COLOR_CYAN}╚${border}╝${COLOR_RESET}"
    _output_write ""
}

output_section() {
    local title="$1"
    _output_write ""
    _output_write "${COLOR_BOLD}${COLOR_CYAN}▶ ${title}${COLOR_RESET}"
    _output_write "${COLOR_DIM}$(printf '─%.0s' {1..60})${COLOR_RESET}"
}

output_subsection() {
    local title="$1"
    _output_write ""
    _output_write "${COLOR_CYAN}  ○ ${title}${COLOR_RESET}"
}

output_bullet() {
    local msg="$1"
    local level="${2:-1}"
    local indent=""
    local bullet="•"
    
    case $level in
        1) indent="  "; bullet="•" ;;
        2) indent="    "; bullet="◦" ;;
        3) indent="      "; bullet="▪" ;;
        *) indent="        "; bullet="·" ;;
    esac
    
    _output_write "${COLOR_DIM}${indent}${bullet}${COLOR_RESET} ${msg}"
}

output_key_value() {
    local key="$1"
    local value="$2"
    local width="${3:-20}"
    
    printf "  ${COLOR_CYAN}%-${width}s${COLOR_RESET} %s\n" "${key}:" "${value}"
}

output_progress_start() {
    OUTPUT_PROGRESS_TOTAL="$1"
    OUTPUT_PROGRESS_CURRENT=0
}

output_progress_update() {
    local increment="${1:-1}"
    ((OUTPUT_PROGRESS_CURRENT += increment))
    
    if [[ "$OUTPUT_QUIET" != "true" ]]; then
        local percent=0
        if [[ $OUTPUT_PROGRESS_TOTAL -gt 0 ]]; then
            percent=$((OUTPUT_PROGRESS_CURRENT * 100 / OUTPUT_PROGRESS_TOTAL))
        fi
        
        local width=40
        local filled=$((percent * width / 100))
        local empty=$((width - filled))
        
        local bar=""
        if [[ "$OUTPUT_USE_UNICODE" == "true" ]]; then
            bar="${COLOR_GREEN}$(printf '█%.0s' $(seq 1 $filled))${COLOR_RESET}${COLOR_DIM}$(printf '░%.0s' $(seq 1 $empty))${COLOR_RESET}"
        else
            bar="${COLOR_GREEN}$(printf '#%.0s' $(seq 1 $filled))${COLOR_RESET}${COLOR_DIM}$(printf '-%.0s' $(seq 1 $empty))${COLOR_RESET}"
        fi
        
        printf "\r  [%s] %3d%% (%d/%d)" "$bar" "$percent" "$OUTPUT_PROGRESS_CURRENT" "$OUTPUT_PROGRESS_TOTAL"
    fi
}

output_progress_end() {
    if [[ "$OUTPUT_QUIET" != "true" ]]; then
        echo ""
    fi
    OUTPUT_PROGRESS_CURRENT=0
    OUTPUT_PROGRESS_TOTAL=0
}

output_step_start() {
    OUTPUT_STEP_TOTAL="${1:-0}"
    OUTPUT_STEP_CURRENT=0
}

output_step() {
    local name="$1"
    local status="${2:-running}"
    ((OUTPUT_STEP_CURRENT++))
    
    local step_num=""
    if [[ $OUTPUT_STEP_TOTAL -gt 0 ]]; then
        step_num="[${OUTPUT_STEP_CURRENT}/${OUTPUT_STEP_TOTAL}]"
    else
        step_num="[${OUTPUT_STEP_CURRENT}]"
    fi
    
    local icon=""
    local color=""
    case "$status" in
        running)
            icon="◐"
            color="$COLOR_YELLOW"
            ;;
        success)
            icon="✓"
            color="$COLOR_GREEN"
            ;;
        error|failed)
            icon="✗"
            color="$COLOR_RED"
            ;;
        skipped)
            icon="○"
            color="$COLOR_DIM"
            ;;
    esac
    
    _output_write "  ${color}${icon}${COLOR_RESET} ${COLOR_DIM}${step_num}${COLOR_RESET} ${name}"
}

output_step_end() {
    OUTPUT_STEP_CURRENT=0
    OUTPUT_STEP_TOTAL=0
}

output_file_status() {
    local src="$1"
    local dest="$2"
    local status="${3:-processing}"
    
    local icon=""
    local color=""
    case "$status" in
        processing)
            icon="→"
            color="$COLOR_BLUE"
            ;;
        success)
            icon="✓"
            color="$COLOR_GREEN"
            ;;
        error|failed)
            icon="✗"
            color="$COLOR_RED"
            ;;
        skipped)
            icon="○"
            color="$COLOR_DIM"
            ;;
        cached)
            icon="≡"
            color="$COLOR_CYAN"
            ;;
    esac
    
    _output_write "    ${color}${icon}${COLOR_RESET} ${COLOR_DIM}${src}${COLOR_RESET} ${COLOR_DIM}→${COLOR_RESET} ${dest}"
}

output_spinner_start() {
    local msg="${1:-Processing...}"
    
    if [[ "$OUTPUT_QUIET" == "true" ]]; then
        return
    fi
    
    _output_spinner_stop
    
    (
        while true; do
            printf "\r  ${OUTPUT_SPINNER_CHARS[$OUTPUT_SPINNER_IDX]} %s" "$msg"
            OUTPUT_SPINNER_IDX=$(( (OUTPUT_SPINNER_IDX + 1) % ${#OUTPUT_SPINNER_CHARS[@]} ))
            sleep 0.1
        done
    ) &
    OUTPUT_SPINNER_PID=$!
}

output_spinner_update() {
    local msg="$1"
    if [[ -n "$OUTPUT_SPINNER_PID" ]] && [[ "$OUTPUT_QUIET" != "true" ]]; then
        printf "\r  ${OUTPUT_SPINNER_CHARS[$OUTPUT_SPINNER_IDX]} %s" "$msg"
        OUTPUT_SPINNER_IDX=$(( (OUTPUT_SPINNER_IDX + 1) % ${#OUTPUT_SPINNER_CHARS[@]} ))
    fi
}

_output_spinner_stop() {
    if [[ -n "$OUTPUT_SPINNER_PID" ]]; then
        kill "$OUTPUT_SPINNER_PID" 2>/dev/null
        wait "$OUTPUT_SPINNER_PID" 2>/dev/null
        OUTPUT_SPINNER_PID=""
        printf "\r%50s\r" ""
    fi
}

output_spinner_stop() {
    local msg="${1:-Done}"
    local status="${2:-success}"
    
    if [[ "$OUTPUT_QUIET" == "true" ]]; then
        return
    fi
    
    _output_spinner_stop
    
    local icon=""
    local color=""
    case "$status" in
        success)
            icon="✓"
            color="$COLOR_GREEN"
            ;;
        error|failed)
            icon="✗"
            color="$COLOR_RED"
            ;;
    esac
    
    _output_write "  ${color}${icon}${COLOR_RESET} ${msg}"
}

output_table() {
    local -n headers="$1"
    local -n rows="$2"
    
    if [[ "$OUTPUT_QUIET" == "true" ]]; then
        return
    fi
    
    local -a widths=()
    local i
    
    for i in "${!headers[@]}"; do
        widths[$i]=${#headers[$i]}
    done
    
    for row in "${rows[@]}"; do
        local -a cols
        IFS=$'\t' read -ra cols <<< "$row"
        for i in "${!cols[@]}"; do
            if [[ ${#cols[$i]} -gt ${widths[$i]:-0} ]]; then
                widths[$i]=${#cols[$i]}
            fi
        done
    done
    
    local header_line=""
    local separator_line=""
    for i in "${!headers[@]}"; do
        local w=${widths[$i]}
        header_line+=" ${COLOR_BOLD}$(printf "%-${w}s" "${headers[$i]}")${COLOR_RESET} │"
        separator_line+="$(printf '%*s' $((w+2)) '' | tr ' ' '─')┼"
    done
    
    _output_write " ┌${separator_line%?}┐"
    _output_write " │${header_line%│}│"
    _output_write " ├${separator_line%?}┤"
    
    for row in "${rows[@]}"; do
        local -a cols
        IFS=$'\t' read -ra cols <<< "$row"
        local row_line=""
        for i in "${!cols[@]}"; do
            local w=${widths[$i]}
            row_line+=" $(printf "%-${w}s" "${cols[$i]}") │"
        done
        _output_write " │${row_line%│}│"
    done
    
    _output_write " └${separator_line%?}┘"
}

output_tree() {
    local -n items="$1"
    local prefix="${2:-}"
    local is_last="${3:-false}"
    
    local connector="├──"
    local extension="│  "
    
    if [[ "$is_last" == "true" ]]; then
        connector="└──"
        extension="   "
    fi
    
    local count=${#items[@]}
    local i=0
    
    for item in "${items[@]}"; do
        ((i++))
        local is_item_last="false"
        [[ $i -eq $count ]] && is_item_last="true"
        
        local item_connector="├──"
        [[ "$is_item_last" == "true" ]] && item_connector="└──"
        
        if [[ "$item" == *":"* ]]; then
            local name="${item%%:*}"
            local -a children_str="${item#*:}"
            
            if [[ -n "$children_str" ]] && [[ "$children_str" != "$item" ]]; then
                _output_write "${prefix}${item_connector} ${COLOR_CYAN}${name}${COLOR_RESET}"
                
                local -a child_items
                IFS=',' read -ra child_items <<< "$children_str"
                
                local new_prefix="${prefix}${extension}"
                output_tree child_items "$new_prefix" "$is_item_last"
            else
                _output_write "${prefix}${item_connector} ${name}"
            fi
        else
            _output_write "${prefix}${item_connector} ${item}"
        fi
    done
}

output_summary() {
    local title="${1:-Build Summary}"
    local success_count="${2:-0}"
    local fail_count="${3:-0}"
    local skip_count="${4:-0}"
    local duration="${5:-0s}"
    
    _output_write ""
    _output_write "${COLOR_BOLD}${COLOR_CYAN}═══ ${title} ═══${COLOR_RESET}"
    _output_write ""
    
    local total=$((success_count + fail_count + skip_count))
    
    _output_write "  ${COLOR_GREEN}✓ Success:${COLOR_RESET}  ${success_count}"
    _output_write "  ${COLOR_RED}✗ Failed:${COLOR_RESET}   ${fail_count}"
    _output_write "  ${COLOR_DIM}○ Skipped:${COLOR_RESET}  ${skip_count}"
    _output_write "  ${COLOR_CYAN}Σ Total:${COLOR_RESET}    ${total}"
    _output_write ""
    _output_write "  ${COLOR_DIM}Duration:${COLOR_RESET} ${duration}"
    
    if [[ $fail_count -gt 0 ]]; then
        _output_write ""
        _output_write "${COLOR_RED}Build completed with errors.${COLOR_RESET}"
        return 1
    else
        _output_write ""
        _output_write "${COLOR_GREEN}Build completed successfully.${COLOR_RESET}"
        return 0
    fi
}

output_divider() {
    local char="${1:--}"
    local width="${2:-60}"
    _output_write "${COLOR_DIM}$(printf '%s%.0s' "$char" $(seq 1 $width))${COLOR_RESET}"
}

output_clear_line() {
    printf "\r%*s\r" "$(tput cols 2>/dev/null || echo 80)" ""
}

output_init_colors

fi
