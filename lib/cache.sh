#!/usr/bin/env bash

if [[ -z "${_BUILD_CACHE_LOADED:-}" ]]; then
_BUILD_CACHE_LOADED=1

declare -g CACHE_DIR=""
declare -g CACHE_ENABLED=true
declare -g CACHE_MAX_SIZE=1073741824
declare -g CACHE_MAX_AGE=604800
declare -g CACHE_HASH_ALGORITHM="md5"
declare -g CACHE_HIT_COUNT=0
declare -g CACHE_MISS_COUNT=0

cache_init() {
    local dir="${1:-${CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/build-tool}}"
    
    CACHE_DIR="$dir"
    
    mkdir -p "$CACHE_DIR/meta"
    mkdir -p "$CACHE_DIR/files"
    
    cache_load_stats
}

cache_set_dir() {
    local dir="$1"
    CACHE_DIR="$dir"
    cache_init "$dir"
}

cache_enable() {
    CACHE_ENABLED=true
}

cache_disable() {
    CACHE_ENABLED=false
}

cache_is_enabled() {
    [[ "$CACHE_ENABLED" == "true" ]]
}

cache_compute_hash() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    file_hash "$file" "$CACHE_HASH_ALGORITHM"
}

cache_compute_content_hash() {
    local content="$1"
    echo -n "$content" | ${CACHE_HASH_ALGORITHM}sum 2>/dev/null | cut -d' ' -f1 || \
        echo -n "$content" | ${CACHE_HASH_ALGORITHM} -q 2>/dev/null
}

cache_get_meta_file() {
    local key="$1"
    echo "${CACHE_DIR}/meta/${key}.meta"
}

cache_get_data_file() {
    local key="$1"
    echo "${CACHE_DIR}/files/${key}"
}

cache_has() {
    local key="$1"
    
    if ! cache_is_enabled; then
        return 1
    fi
    
    local meta_file
    meta_file=$(cache_get_meta_file "$key")
    local data_file
    data_file=$(cache_get_data_file "$key")
    
    if [[ ! -f "$meta_file" ]] || [[ ! -f "$data_file" ]]; then
        return 1
    fi
    
    source "$meta_file"
    
    local current_time
    current_time=$(date +%s)
    if [[ -n "${CACHE_META_EXPIRES:-}" ]] && [[ $current_time -gt $CACHE_META_EXPIRES ]]; then
        cache_delete "$key"
        return 1
    fi
    
    if [[ -n "${CACHE_META_SOURCE:-}" ]] && [[ -f "$CACHE_META_SOURCE" ]]; then
        local current_hash
        current_hash=$(cache_compute_hash "$CACHE_META_SOURCE")
        if [[ "$current_hash" != "${CACHE_META_HASH:-}" ]]; then
            cache_delete "$key"
            return 1
        fi
    fi
    
    return 0
}

cache_get() {
    local key="$1"
    local output="${2:-}"
    
    if ! cache_has "$key"; then
        ((CACHE_MISS_COUNT++))
        return 1
    fi
    
    local data_file
    data_file=$(cache_get_data_file "$key")
    
    if [[ -n "$output" ]]; then
        cp "$data_file" "$output"
    else
        cat "$data_file"
    fi
    
    ((CACHE_HIT_COUNT++))
    return 0
}

cache_put() {
    local key="$1"
    local source="${2:-}"
    local ttl="${3:-$CACHE_MAX_AGE}"
    local source_file="${4:-}"
    
    if ! cache_is_enabled; then
        return 0
    fi
    
    local meta_file
    meta_file=$(cache_get_meta_file "$key")
    local data_file
    data_file=$(cache_get_data_file "$key")
    
    local current_time
    current_time=$(date +%s)
    local expires=$((current_time + ttl))
    
    local source_hash=""
    if [[ -n "$source_file" ]] && [[ -f "$source_file" ]]; then
        source_hash=$(cache_compute_hash "$source_file")
    fi
    
    {
        echo "CACHE_META_KEY=\"$key\""
        echo "CACHE_META_CREATED=$current_time"
        echo "CACHE_META_EXPIRES=$expires"
        echo "CACHE_META_SOURCE=\"${source_file}\""
        echo "CACHE_META_HASH=\"${source_hash}\""
    } > "$meta_file"
    
    if [[ -n "$source" ]]; then
        if [[ -f "$source" ]]; then
            cp "$source" "$data_file"
        else
            echo "$source" > "$data_file"
        fi
    fi
    
    return 0
}

cache_delete() {
    local key="$1"
    
    local meta_file
    meta_file=$(cache_get_meta_file "$key")
    local data_file
    data_file=$(cache_get_data_file "$key")
    
    rm -f "$meta_file" "$data_file"
}

cache_clear() {
    if [[ -d "$CACHE_DIR/meta" ]]; then
        rm -rf "${CACHE_DIR:?}/meta"/*
    fi
    if [[ -d "$CACHE_DIR/files" ]]; then
        rm -rf "${CACHE_DIR:?}/files"/*
    fi
    
    CACHE_HIT_COUNT=0
    CACHE_MISS_COUNT=0
}

cache_clean_expired() {
    local current_time
    current_time=$(date +%s)
    local cleaned=0
    
    for meta_file in "${CACHE_DIR}/meta"/*.meta; do
        [[ ! -f "$meta_file" ]] && continue
        
        source "$meta_file"
        
        if [[ -n "${CACHE_META_EXPIRES:-}" ]] && [[ $current_time -gt $CACHE_META_EXPIRES ]]; then
            cache_delete "${CACHE_META_KEY}"
            ((cleaned++))
        fi
    done
    
    return $cleaned
}

cache_clean_oversized() {
    local current_size
    current_size=$(cache_get_size)
    
    if [[ $current_size -le $CACHE_MAX_SIZE ]]; then
        return 0
    fi
    
    local -a files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "${CACHE_DIR}/meta" -name "*.meta" -print0 2>/dev/null)
    
    local -a sorted_files=()
    for file in "${files[@]}"; do
        source "$file"
        sorted_files+=("$CACHE_META_CREATED:$CACHE_META_KEY")
    done
    
    IFS=$'\n' sorted_files=($(sort -t: -k1 -n <<< "${sorted_files[*]}"))
    unset IFS
    
    for entry in "${sorted_files[@]}"; do
        local key="${entry#*:}"
        cache_delete "$key"
        
        current_size=$(cache_get_size)
        if [[ $current_size -le $CACHE_MAX_SIZE ]]; then
            break
        fi
    done
}

cache_get_size() {
    local size=0
    
    if [[ -d "$CACHE_DIR/files" ]]; then
        size=$(du -sb "$CACHE_DIR/files" 2>/dev/null | cut -f1)
    fi
    
    echo "${size:-0}"
}

cache_get_entry_count() {
    local count=0
    
    if [[ -d "$CACHE_DIR/meta" ]]; then
        count=$(find "$CACHE_DIR/meta" -name "*.meta" 2>/dev/null | wc -l)
    fi
    
    echo "$count"
}

cache_get_stats() {
    local total=$((CACHE_HIT_COUNT + CACHE_MISS_COUNT))
    local hit_rate=0
    
    if [[ $total -gt 0 ]]; then
        hit_rate=$((CACHE_HIT_COUNT * 100 / total))
    fi
    
    echo "$(i18n_get "cache_statistics")"
    echo "  $(i18n_get "hits"):       $CACHE_HIT_COUNT"
    echo "  $(i18n_get "misses"):     $CACHE_MISS_COUNT"
    echo "  $(i18n_get "hit_rate"):   ${hit_rate}%"
    echo "  $(i18n_get "entries"):    $(cache_get_entry_count)"
    echo "  $(i18n_get "size"):       $(file_size_human "$CACHE_DIR/files")"
}

cache_load_stats() {
    local stats_file="${CACHE_DIR}/stats"
    
    if [[ -f "$stats_file" ]]; then
        source "$stats_file"
    fi
}

cache_save_stats() {
    local stats_file="${CACHE_DIR}/stats"
    
    {
        echo "CACHE_HIT_COUNT=$CACHE_HIT_COUNT"
        echo "CACHE_MISS_COUNT=$CACHE_MISS_COUNT"
    } > "$stats_file"
}

cache_file_needs_rebuild() {
    local source="$1"
    local output="$2"
    local cache_key="$3"
    
    if [[ ! -f "$output" ]]; then
        return 0
    fi
    
    if ! cache_is_enabled; then
        if [[ "$source" -nt "$output" ]]; then
            return 0
        fi
        return 1
    fi
    
    if ! cache_has "$cache_key"; then
        return 0
    fi
    
    return 1
}

cache_store_file_hash() {
    local file="$1"
    local cache_key="$2"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    local hash
    hash=$(cache_compute_hash "$file")
    
    cache_put "$cache_key" "$hash" "$CACHE_MAX_AGE" "$file"
}

cache_check_file_hash() {
    local file="$1"
    local cache_key="$2"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    local current_hash
    current_hash=$(cache_compute_hash "$file")
    
    local cached_hash
    cached_hash=$(cache_get "$cache_key")
    
    if [[ "$current_hash" == "$cached_hash" ]]; then
        return 0
    fi
    
    return 1
}

cache_incremental_key() {
    local file="$1"
    local target="$2"
    
    local hash
    hash=$(cache_compute_hash "$file")
    
    local safe_target="${target//\//_}"
    safe_target="${safe_target//./_}"
    
    echo "${hash}_${safe_target}"
}

cache_mark_built() {
    local source="$1"
    local output="$2"
    local key
    key=$(cache_incremental_key "$source" "$output")
    
    cache_store_file_hash "$source" "$key"
    cache_store_file_hash "$output" "${key}_output"
}

cache_needs_rebuild() {
    local source="$1"
    local output="$2"
    
    if [[ ! -f "$output" ]]; then
        return 0
    fi
    
    local key
    key=$(cache_incremental_key "$source" "$output")
    
    if ! cache_check_file_hash "$source" "$key"; then
        return 0
    fi
    
    return 1
}

cache_cleanup() {
    cache_save_stats
    cache_clean_expired
    cache_clean_oversized
}

fi
