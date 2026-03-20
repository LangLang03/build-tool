#!/usr/bin/env bash

if [[ -z "${_ANDROID_DEPS_LOADED:-}" ]]; then
_ANDROID_DEPS_LOADED=1

declare -g ANDROID_DEPS_DIR=""
declare -g ANDROID_DEPS_CACHE_DIR=""
declare -g ANDROID_NO_CACHE="${ANDROID_NO_CACHE:-false}"

declare -ga ANDROID_RESOLVED_DEPS=()
declare -gA ANDROID_DEP_PATHS=()
declare -gA ANDROID_DEP_POMS=()
declare -gA ANDROID_DEP_RESOLVING=()
declare -ga ANDROID_ALL_DEPS=()

declare -ga ANDROID_EXCLUDED_DEPS=(
    "androidx.databinding:databinding-compiler"
    "androidx.databinding:databinding-compiler-common"
    "com.android.tools.build:aapt2"
    "com.android.tools.build:builder"
    "com.android.tools.build:gradle"
    "com.android.tools.build:gradle-api"
    "com.android.tools.build:manifest-merger"
)

declare -ga ANDROID_EXCLUDED_SUFFIXES=(
    "-lint"
    "-lint-checks"
    "-truth"
    "-test"
    "-testing"
    "-samples"
)

android_deps_init() {
    ANDROID_DEPS_DIR="${ANDROID_BUILD_DIR}/dependencies"
    ANDROID_DEPS_CACHE_DIR="${CACHE_DIR}/android/dependencies"
    
    ensure_dir "$ANDROID_DEPS_DIR"
    ensure_dir "$ANDROID_DEPS_CACHE_DIR"
}

android_maven_parse_coord() {
    local coord="$1"
    local group artifact version
    
    IFS=':' read -r group artifact version <<< "$coord"
    
    version=$(android_maven_normalize_version "$version")
    
    echo "${group}|${artifact}|${version}"
}

android_maven_normalize_version() {
    local version="$1"
    
    version="${version#\[\]}"
    version="${version//\[}"
    version="${version//\]}"
    
    if [[ "$version" == *","* ]]; then
        version="${version##*,}"
        version="${version%%,*}"
    fi
    
    echo "$version"
}

android_maven_to_path() {
    local coord="$1"
    local group artifact version
    
    IFS='|' read -r group artifact version <<< "$(android_maven_parse_coord "$coord")"
    
    local group_path="${group//.//}"
    echo "${group_path}/${artifact}/${version}/${artifact}-${version}"
}

android_maven_get_filename() {
    local coord="$1"
    local ext="${2:-aar}"
    
    local group artifact version
    IFS='|' read -r group artifact version <<< "$(android_maven_parse_coord "$coord")"
    
    echo "${artifact}-${version}.${ext}"
}

android_download_file() {
    local url="$1"
    local output="$2"
    local timeout="${3:-15}"
    
    if command_exists curl; then
        curl -fsSL --connect-timeout "$timeout" --max-time "$((timeout * 3))" -o "$output" "$url"
        return $?
    elif command_exists wget; then
        wget -q --timeout="$timeout" -O "$output" "$url"
        return $?
    else
        output_error "$(android_i18n_get "download_failed"): curl or wget required"
        return 1
    fi
}

android_download_pom() {
    local coord="$1"
    
    local group artifact version
    IFS='|' read -r group artifact version <<< "$(android_maven_parse_coord "$coord")"
    
    local dep_path
    dep_path=$(android_maven_to_path "$coord")
    local pom_file="${ANDROID_DEPS_CACHE_DIR}/${dep_path}.pom"
    
    if [[ "$ANDROID_NO_CACHE" != "true" ]] && [[ -f "$pom_file" ]]; then
        ANDROID_DEP_POMS["$coord"]="$pom_file"
        return 0
    fi
    
    ensure_dir "$(dirname "$pom_file")"
    
    for repo in "${ANDROID_REPOSITORIES[@]}"; do
        local url="${repo}/${dep_path}.pom"
        
        if android_download_file "$url" "$pom_file"; then
            if [[ -f "$pom_file" ]] && [[ -s "$pom_file" ]]; then
                ANDROID_DEP_POMS["$coord"]="$pom_file"
                return 0
            fi
            rm -f "$pom_file"
        fi
    done
    
    return 1
}

android_parse_pom_dependencies() {
    local pom_file="$1"
    
    if [[ ! -f "$pom_file" ]]; then
        return 0
    fi
    
    local -a deps=()
    local in_dep=false
    local in_deps=false
    local group=""
    local artifact=""
    local version=""
    local scope=""
    local skip=false
    
    while IFS= read -r line; do
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        
        if [[ "$line" == "<dependencies>" ]]; then
            in_deps=true
            continue
        fi
        
        if [[ "$line" == "</dependencies>" ]]; then
            in_deps=false
            continue
        fi
        
        if ! $in_deps; then
            continue
        fi
        
        if [[ "$line" == "<dependency>" ]]; then
            in_dep=true
            group=""
            artifact=""
            version=""
            scope=""
            skip=false
            continue
        fi
        
        if [[ "$line" == "</dependency>" ]]; then
            in_dep=false
            if [[ -n "$group" ]] && [[ -n "$artifact" ]] && [[ -n "$version" ]] && ! $skip; then
                if [[ -z "$scope" ]] || [[ "$scope" == "compile" ]] || [[ "$scope" == "runtime" ]]; then
                    deps+=("${group}:${artifact}:${version}")
                fi
            fi
            continue
        fi
        
        if $in_dep; then
            if [[ "$line" =~ ^\<groupId\>([^<]+)\</groupId\>$ ]]; then
                group="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^\<artifactId\>([^<]+)\</artifactId\>$ ]]; then
                artifact="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^\<version\>([^<]+)\</version\>$ ]]; then
                version="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^\<scope\>([^<]+)\</scope\>$ ]]; then
                scope="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^\<optional\>([^<]+)\</optional\>$ ]]; then
                if [[ "${BASH_REMATCH[1]}" == "true" ]]; then
                    skip=true
                fi
            fi
        fi
    done < "$pom_file"
    
    for dep in "${deps[@]}"; do
        echo "$dep"
    done
}

android_is_dep_excluded() {
    local coord="$1"
    
    local group artifact version
    IFS=':' read -r group artifact version <<< "$coord"
    
    local key="${group}:${artifact}"
    
    for excluded in "${ANDROID_EXCLUDED_DEPS[@]}"; do
        if [[ "$key" == "$excluded" ]]; then
            return 0
        fi
    done
    
    for suffix in "${ANDROID_EXCLUDED_SUFFIXES[@]}"; do
        if [[ "$artifact" == *"$suffix" ]]; then
            return 0
        fi
    done
    
    return 1
}

android_download_dependency() {
    local coord="$1"
    local type="${2:-aar}"
    
    local group artifact version
    IFS='|' read -r group artifact version <<< "$(android_maven_parse_coord "$coord")"
    
    if [[ -z "$group" ]] || [[ -z "$artifact" ]] || [[ -z "$version" ]]; then
        output_error "$(android_i18n_printf "invalid_dep_coord" "$coord")"
        return 1
    fi
    
    local dep_path
    dep_path=$(android_maven_to_path "$coord")
    local filename
    filename=$(android_maven_get_filename "$coord" "$type")
    
    local cache_file="${ANDROID_DEPS_CACHE_DIR}/${dep_path}.${type}"
    
    if [[ "$ANDROID_NO_CACHE" != "true" ]] && [[ -f "$cache_file" ]]; then
        output_debug "$(android_i18n_printf "cache_hit_coord" "$coord")"
        ANDROID_DEP_PATHS["$coord"]="$cache_file"
        return 0
    fi
    
    ensure_dir "$(dirname "$cache_file")"
    
    output_info "$(android_i18n_get "downloading"): $coord"
    
    local -a failed_repos=()
    
    for repo in "${ANDROID_REPOSITORIES[@]}"; do
        local url="${repo}/${dep_path}.${type}"
        
        output_debug "$(android_i18n_printf "trying_url" "$url")"
        
        if android_download_file "$url" "$cache_file"; then
            if [[ -f "$cache_file" ]] && [[ -s "$cache_file" ]]; then
                output_success "$(android_i18n_get "download_success"): $coord"
                ANDROID_DEP_PATHS["$coord"]="$cache_file"
                return 0
            fi
            rm -f "$cache_file"
        fi
        failed_repos+=("$repo")
    done
    
    return 1
}

android_download_dependency_with_fallback() {
    local coord="$1"
    
    local cache_file_aar="${ANDROID_DEPS_CACHE_DIR}/$(android_maven_to_path "$coord").aar"
    local cache_file_jar="${ANDROID_DEPS_CACHE_DIR}/$(android_maven_to_path "$coord").jar"
    
    if [[ "$ANDROID_NO_CACHE" != "true" ]] && [[ -f "$cache_file_aar" ]]; then
        output_debug "$(android_i18n_printf "cache_hit_coord" "$coord")"
        ANDROID_DEP_PATHS["$coord"]="$cache_file_aar"
        return 0
    fi
    
    if [[ "$ANDROID_NO_CACHE" != "true" ]] && [[ -f "$cache_file_jar" ]]; then
        output_debug "$(android_i18n_printf "cache_hit_coord" "$coord")"
        ANDROID_DEP_PATHS["$coord"]="$cache_file_jar"
        return 0
    fi
    
    if android_download_dependency "$coord" "aar"; then
        return 0
    fi
    
    if android_download_dependency "$coord" "jar"; then
        return 0
    fi
    
    output_error "$(android_i18n_get "download_failed_all_sources"): $coord"
    return 1
}

android_extract_aar() {
    local aar_file="$1"
    local output_dir="$2"
    
    if [[ ! -f "$aar_file" ]]; then
        output_error "$(android_i18n_printf "aar_not_found" "$aar_file")"
        return 1
    fi
    
    ensure_dir "$output_dir"
    
    output_debug "$(android_i18n_get "extracting"): $aar_file"
    
    if ! unzip -q -o "$aar_file" -d "$output_dir" 2>/dev/null; then
        output_error "$(android_i18n_get "extract_failed"): $aar_file"
        return 1
    fi
    
    return 0
}

android_extract_jar() {
    local jar_file="$1"
    local output_dir="$2"
    
    if [[ ! -f "$jar_file" ]]; then
        output_error "$(android_i18n_printf "jar_not_found" "$jar_file")"
        return 1
    fi
    
    ensure_dir "$output_dir"
    
    output_debug "$(android_i18n_get "extracting"): $jar_file"
    
    if ! unzip -q -o "$jar_file" -d "$output_dir" 2>/dev/null; then
        output_error "$(android_i18n_get "extract_failed"): $jar_file"
        return 1
    fi
    
    return 0
}

android_process_aar() {
    local coord="$1"
    
    local aar_file="${ANDROID_DEP_PATHS[$coord]}"
    
    if [[ -z "$aar_file" ]] || [[ ! -f "$aar_file" ]]; then
        if ! android_download_dependency "$coord" "aar"; then
            return 1
        fi
        aar_file="${ANDROID_DEP_PATHS[$coord]}"
    fi
    
    local group artifact version
    IFS='|' read -r group artifact version <<< "$(android_maven_parse_coord "$coord")"
    
    local extract_dir="${ANDROID_DEPS_DIR}/${artifact}-${version}"
    
    if [[ -d "$extract_dir" ]]; then
        output_debug "$(android_i18n_printf "already_extracted_coord" "$coord")"
        return 0
    fi
    
    android_extract_aar "$aar_file" "$extract_dir"
    
    local classes_jar="${extract_dir}/classes.jar"
    if [[ -f "$classes_jar" ]]; then
        local classes_dir="${extract_dir}/classes"
        android_extract_jar "$classes_jar" "$classes_dir"
    fi
    
    return 0
}

android_process_jar() {
    local coord="$1"
    
    local jar_file="${ANDROID_DEP_PATHS[$coord]}"
    
    if [[ -z "$jar_file" ]] || [[ ! -f "$jar_file" ]]; then
        if ! android_download_dependency "$coord" "jar"; then
            return 1
        fi
        jar_file="${ANDROID_DEP_PATHS[$coord]}"
    fi
    
    local group artifact version
    IFS='|' read -r group artifact version <<< "$(android_maven_parse_coord "$coord")"
    
    local extract_dir="${ANDROID_DEPS_DIR}/${artifact}-${version}"
    
    if [[ -d "$extract_dir" ]]; then
        output_debug "$(android_i18n_printf "already_extracted_coord" "$coord")"
        return 0
    fi
    
    android_extract_jar "$jar_file" "$extract_dir"
    
    return 0
}

android_resolve_dependency() {
    local coord="$1"
    local type="${2:-implementation}"
    local depth="${3:-0}"
    
    if arr_contains "$coord" "${ANDROID_RESOLVED_DEPS[@]}"; then
        return 0
    fi
    
    local group artifact version
    IFS=':' read -r group artifact version <<< "$coord"
    local key="${group}:${artifact}"
    
    if [[ "$group" == *"*"* ]] || [[ "$artifact" == *"*"* ]] || [[ "$version" == *"*"* ]]; then
        output_debug "$(android_i18n_printf "deps_wildcard" "$coord")"
        return 0
    fi
    
    if [[ -n "${ANDROID_DEP_RESOLVING[$key]:-}" ]]; then
        output_debug "$(android_i18n_printf "deps_circular" "$coord")"
        return 0
    fi
    
    if android_is_dep_excluded "$coord"; then
        output_debug "$(android_i18n_printf "deps_excluded" "$coord")"
        return 0
    fi
    
    ANDROID_DEP_RESOLVING["$key"]="1"
    
    local indent=""
    for ((i=0; i<depth; i++)); do
        indent+="  "
    done
    
    output_debug "${indent}$(android_i18n_get "deps_resolving"): $coord"
    
    local downloaded=false
    local pom_file=""
    
    android_download_pom "$coord" 2>/dev/null || true
    pom_file="${ANDROID_DEP_POMS[$coord]:-}"
    
    if android_download_dependency_with_fallback "$coord"; then
        local dep_file="${ANDROID_DEP_PATHS[$coord]}"
        if [[ "$dep_file" == *.aar ]]; then
            android_process_aar "$coord"
        else
            android_process_jar "$coord"
        fi
        downloaded=true
    fi
    
    if [[ "$downloaded" == "true" ]]; then
        ANDROID_RESOLVED_DEPS+=("$coord")
        
        if [[ -n "$pom_file" ]] && [[ -f "$pom_file" ]]; then
            local -a transitive_deps
            while IFS= read -r dep; do
                if [[ -n "$dep" ]] && [[ "$dep" != *'$'* ]]; then
                    transitive_deps+=("$dep")
                fi
            done < <(android_parse_pom_dependencies "$pom_file")
            
            for trans_dep in "${transitive_deps[@]}"; do
                android_resolve_dependency "$trans_dep" "implementation" $((depth + 1)) || true
            done
        fi
        
        unset "ANDROID_DEP_RESOLVING[$key]"
        return 0
    fi
    
    unset "ANDROID_DEP_RESOLVING[$key]"
    output_error "$(android_i18n_get "deps_failed"): $coord"
    return 1
}

android_analyze_dependency_tree() {
    local coord="$1"
    local depth="${2:-0}"
    
    local group artifact version
    IFS=':' read -r group artifact version <<< "$coord"
    local key="${group}:${artifact}"
    
    if [[ "$group" == *"*"* ]] || [[ "$artifact" == *"*"* ]] || [[ "$version" == *"*"* ]]; then
        return 0
    fi
    
    if [[ -n "${ANDROID_DEP_RESOLVING[$key]:-}" ]]; then
        return 0
    fi
    
    if android_is_dep_excluded "$coord"; then
        return 0
    fi
    
    if arr_contains "$coord" "${ANDROID_ALL_DEPS[@]}"; then
        return 0
    fi
    
    ANDROID_DEP_RESOLVING["$key"]="1"
    ANDROID_ALL_DEPS+=("$coord")
    
    local count=${#ANDROID_ALL_DEPS[@]}
    output_debug "[$count] $(android_i18n_get "deps_analyzing"): $coord"
    
    android_download_pom "$coord" 2>/dev/null || true
    local pom_file="${ANDROID_DEP_POMS[$coord]:-}"
    
    if [[ -n "$pom_file" ]] && [[ -f "$pom_file" ]]; then
        while IFS= read -r dep; do
            if [[ -n "$dep" ]] && [[ "$dep" != *'$'* ]]; then
                android_analyze_dependency_tree "$dep" $((depth + 1)) || true
            fi
        done < <(android_parse_pom_dependencies "$pom_file")
    fi
    
    unset "ANDROID_DEP_RESOLVING[$key]"
}

android_download_single_dep() {
    local coord="$1"
    local cache_dir="$2"
    local repos_file="$3"
    
    local group artifact version
    IFS=':' read -r group artifact version <<< "$coord"
    
    local dep_path
    dep_path=$(android_maven_to_path "$coord")
    
    local aar_file="${cache_dir}/${dep_path}.aar"
    local jar_file="${cache_dir}/${dep_path}.jar"
    
    if [[ -f "$aar_file" ]] || [[ -f "$jar_file" ]]; then
        echo "CACHED: $coord"
        return 0
    fi
    
    while IFS= read -r repo; do
        [[ -z "$repo" ]] && continue
        
        local aar_url="${repo}/${dep_path}.aar"
        local jar_url="${repo}/${dep_path}.jar"
        
        if curl -fsSL --connect-timeout 10 -o "$aar_file" "$aar_url" 2>/dev/null && [[ -s "$aar_file" ]]; then
            echo "DOWNLOADED: $coord (aar from $repo)"
            return 0
        fi
        rm -f "$aar_file"
        
        if curl -fsSL --connect-timeout 10 -o "$jar_file" "$jar_url" 2>/dev/null && [[ -s "$jar_file" ]]; then
            echo "DOWNLOADED: $coord (jar from $repo)"
            return 0
        fi
        rm -f "$jar_file"
    done < "$repos_file"
    
    echo "FAILED: $coord"
    return 1
}

android_resolve_all_dependencies() {
    output_section "$(android_i18n_get "deps_resolving")"
    
    android_deps_init
    
    ANDROID_RESOLVED_DEPS=()
    ANDROID_DEP_PATHS=()
    ANDROID_DEP_POMS=()
    ANDROID_DEP_RESOLVING=()
    ANDROID_ALL_DEPS=()
    
    output_info "$(android_i18n_get "deps_analyzing_tree")"
    
    for dep in "${ANDROID_DEPS_IMPLEMENTATION[@]}"; do
        android_analyze_dependency_tree "$dep" || true
    done
    
    for dep in "${ANDROID_DEPS_COMPILE_ONLY[@]}"; do
        android_analyze_dependency_tree "$dep" || true
    done
    
    local total_deps=${#ANDROID_ALL_DEPS[@]}
    output_info "$(android_i18n_printf "deps_tree_analyzed" "$total_deps")"
    
    if [[ $total_deps -eq 0 ]]; then
        output_success "$(android_i18n_get "deps_resolved")"
        return 0
    fi
    
    output_info "$(android_i18n_printf "deps_parallel_download" "$PARALLEL_JOBS")"
    
    local repos_file="${ANDROID_BUILD_DIR}/.repos_list"
    printf '%s\n' "${ANDROID_REPOSITORIES[@]}" > "$repos_file"
    
    local download_log="${ANDROID_BUILD_DIR}/.download_log"
    > "$download_log"
    
    local pids=()
    local running=0
    local failed=0
    
    for coord in "${ANDROID_ALL_DEPS[@]}"; do
        while [[ $running -ge $PARALLEL_JOBS ]]; do
            for i in "${!pids[@]}"; do
                if ! kill -0 "${pids[$i]}" 2>/dev/null; then
                    wait "${pids[$i]}" || ((failed++))
                    unset 'pids[$i]'
                    ((running--))
                fi
            done
            sleep 0.1
        done
        
        (
            result=$(android_download_single_dep "$coord" "$ANDROID_DEPS_CACHE_DIR" "$repos_file")
            echo "$result" >> "$download_log"
        ) &
        pids+=($!)
        ((running++))
    done
    
    for pid in "${pids[@]}"; do
        wait "$pid" || ((failed++))
    done
    
    rm -f "$repos_file"
    
    local downloaded=0
    local cached=0
    local failed_count=0
    local -a failed_deps=()
    
    while IFS= read -r line; do
        case "$line" in
            "DOWNLOADED:"*) ((downloaded++)) ;;
            "CACHED:"*) ((cached++)) ;;
            "FAILED:"*)
                ((failed_count++))
                failed_deps+=("${line#FAILED: }")
                ;;
        esac
    done < "$download_log"
    
    rm -f "$download_log"
    
    for coord in "${ANDROID_ALL_DEPS[@]}"; do
        local dep_path
        dep_path=$(android_maven_to_path "$coord")
        
        local aar_file="${ANDROID_DEPS_CACHE_DIR}/${dep_path}.aar"
        local jar_file="${ANDROID_DEPS_CACHE_DIR}/${dep_path}.jar"
        
        if [[ -f "$aar_file" ]]; then
            ANDROID_DEP_PATHS["$coord"]="$aar_file"
            android_process_aar "$coord"
            ANDROID_RESOLVED_DEPS+=("$coord")
        elif [[ -f "$jar_file" ]]; then
            ANDROID_DEP_PATHS["$coord"]="$jar_file"
            android_process_jar "$coord"
            ANDROID_RESOLVED_DEPS+=("$coord")
        fi
    done
    
    output_info "$(android_i18n_printf "deps_download_summary" "$downloaded" "$cached" "$failed_count")"
    
    if [[ $failed_count -gt 0 ]]; then
        output_warning "$(android_i18n_printf "deps_failed_count" "$failed_count")"
        for dep in "${failed_deps[@]}"; do
            output_error "  - $dep"
        done
        return 1
    fi
    
    output_success "$(android_i18n_get "deps_resolved")"
    return 0
}

android_get_classpath() {
    local cp=""
    
    local android_jar
    android_jar=$(android_get_android_jar)
    
    if [[ -n "$android_jar" ]]; then
        cp="$android_jar"
    fi
    
    for dep_dir in "${ANDROID_DEPS_DIR}"/*; do
        if [[ -d "$dep_dir" ]]; then
            if [[ -d "${dep_dir}/classes" ]]; then
                [[ -n "$cp" ]] && cp="${cp}:"
                cp="${cp}${dep_dir}/classes"
            fi
            
            if [[ -f "${dep_dir}/classes.jar" ]]; then
                [[ -n "$cp" ]] && cp="${cp}:"
                cp="${cp}${dep_dir}/classes.jar"
            fi
        fi
    done
    
    echo "$cp"
}

android_get_jar_files() {
    local -a jars=()
    
    for dep_dir in "${ANDROID_DEPS_DIR}"/*; do
        if [[ -d "$dep_dir" ]]; then
            if [[ -f "${dep_dir}/classes.jar" ]]; then
                jars+=("${dep_dir}/classes.jar")
            fi
        fi
    done
    
    echo "${jars[@]}"
}

android_get_manifest_files() {
    local -a manifests=()
    
    for dep_dir in "${ANDROID_DEPS_DIR}"/*; do
        if [[ -d "$dep_dir" ]]; then
            if [[ -f "${dep_dir}/AndroidManifest.xml" ]]; then
                manifests+=("${dep_dir}/AndroidManifest.xml")
            fi
        fi
    done
    
    echo "${manifests[@]}"
}

android_get_res_dirs() {
    local -a res_dirs=()
    
    for dep_dir in "${ANDROID_DEPS_DIR}"/*; do
        if [[ -d "$dep_dir" ]] && [[ -d "${dep_dir}/res" ]]; then
            res_dirs+=("${dep_dir}/res")
        fi
    done
    
    echo "${res_dirs[@]}"
}

android_deps_list() {
    output_section "$(android_i18n_get "resolved_deps")"
    
    if [[ ${#ANDROID_RESOLVED_DEPS[@]} -eq 0 ]]; then
        output_info "$(android_i18n_get "no_deps_resolved")"
        return 0
    fi
    
    for dep in "${ANDROID_RESOLVED_DEPS[@]}"; do
        local path="${ANDROID_DEP_PATHS[$dep]}"
        output_bullet "$dep"
        [[ -n "$path" ]] && output_bullet "  -> $path" 2
    done
}

android_deps_clean() {
    if [[ -d "$ANDROID_DEPS_DIR" ]]; then
        output_info "$(android_i18n_get "cleaning_deps_dir")"
        rm -rf "$ANDROID_DEPS_DIR"
    fi
}

fi
