#!/usr/bin/env bash

PLUGIN_NAME="java"
PLUGIN_VERSION="1.0.0"
PLUGIN_DESCRIPTION="Java compilation plugin"
PLUGIN_DEPENDENCIES="javac jar"

declare -g JAR_OUTPUT="${JAR_OUTPUT:-}"
declare -g MAIN_CLASS="${MAIN_CLASS:-}"
declare -g JAVA_SOURCE="${JAVA_SOURCE:-}"
declare -g JAVA_TARGET="${JAVA_TARGET:-}"
declare -g JAVA_OPTS="${JAVA_OPTS:-}"
declare -g JAVA_RUN_OPTS="${JAVA_RUN_OPTS:-}"

register_target "build" "Compile Java sources" "java_build"
register_target "clean" "Clean Java build artifacts" "java_clean"
register_target "test" "Run Java tests" "java_test"
register_target "jar" "Create JAR file" "java_jar"
register_target "run" "Run the main class" "java_run"

register_target_deps "jar" "build"
register_target_deps "test" "build"
register_target_deps "run" "build"

pre_build_hook() {
    log_info "Preparing Java build..."
}

post_build_hook() {
    log_info "Java build completed successfully!"
}

java_build() {
    local src_dir="${SOURCE_DIR:-src}"
    local build_dir="${BUILD_DIR:-output}/classes"
    
    step_start "Preparing build directory"
    ensure_dir "$build_dir"
    step_end
    
    step_start "Scanning Java sources"
    local -a sources=()
    
    if [[ -d "$src_dir" ]]; then
        while IFS= read -r -d '' file; do
            sources+=("$file")
        done < <(find "$src_dir" -name "*.java" -print0 2>/dev/null)
    fi
    
    while IFS= read -r -d '' file; do
        sources+=("$file")
    done < <(find . -maxdepth 1 -name "*.java" -print0 2>/dev/null)
    
    local total=${#sources[@]}
    output_info "Found $total Java source file(s)"
    step_end
    
    if [[ $total -eq 0 ]]; then
        output_warning "No Java source files found"
        output_info "Create .java files in current directory or ${src_dir}/ directory"
        return 0
    fi
    
    step_start "Compiling Java sources"
    output_progress_start $total
    
    local java_opts="${JAVA_OPTS:-}"
    local java_source="${JAVA_SOURCE:-}"
    local java_target="${JAVA_TARGET:-}"
    
    local javac_opts=""
    [[ -n "$java_source" ]] && javac_opts+=" -source $java_source"
    [[ -n "$java_target" ]] && javac_opts+=" -target $java_target"
    [[ -n "$java_opts" ]] && javac_opts+=" $java_opts"
    
    local success=0
    local failed=0
    
    for src in "${sources[@]}"; do
        local basename
        basename=$(basename "$src" .java)
        local dest="$build_dir/${basename}.class"
        
        local cache_key
        cache_key=$(cache_incremental_key "$src" "$dest")
        
        if cache_is_enabled && ! cache_needs_rebuild "$src" "$dest"; then
            output_file_status "$src" "$dest" "cached"
            cache_mark_built "$src" "$dest"
            ((success++))
            output_progress_update
            continue
        fi
        
        if javac $javac_opts -d "$build_dir" "$src" 2>&1; then
            output_file_status "$src" "$dest" "success"
            cache_mark_built "$src" "$dest"
            ((success++))
        else
            output_file_status "$src" "$dest" "error"
            ((failed++))
        fi
        
        output_progress_update
    done
    
    output_progress_end
    step_end
    
    if [[ $failed -gt 0 ]]; then
        output_error "$failed file(s) failed to compile"
        return 1
    fi
    
    output_success "Successfully compiled $success Java file(s)"
    return 0
}

java_clean() {
    local build_dir="${BUILD_DIR:-output}"
    
    output_section "Cleaning Java build"
    
    if [[ -d "$build_dir" ]]; then
        output_info "Removing $build_dir"
        rm -rf "$build_dir"
        output_success "Clean completed"
    else
        output_info "Nothing to clean"
    fi
    
    return 0
}

java_test() {
    local build_dir="${BUILD_DIR:-output}/classes"
    
    output_section "Running Java tests"
    
    if [[ ! -d "$build_dir" ]]; then
        output_error "Build directory not found. Run 'build build' first."
        return 1
    fi
    
    local -a class_files=()
    while IFS= read -r -d '' file; do
        class_files+=("$file")
    done < <(find "$build_dir" -name "*.class" -print0 2>/dev/null)
    
    if [[ ${#class_files[@]} -eq 0 ]]; then
        output_warning "No compiled classes found"
        return 0
    fi
    
    step_start "Running main class"
    
    local main_class="${MAIN_CLASS:-}"
    
    if [[ -z "$main_class" ]]; then
        for class_file in "${class_files[@]}"; do
            local basename
            basename=$(basename "$class_file" .class)
            local relative="${class_file#$build_dir/}"
            local class_path="${relative%.class}"
            class_path="${class_path//\//.}"
            
            if javap -p "$class_file" 2>/dev/null | grep -q "public static void main"; then
                main_class="$class_path"
                break
            fi
        done
    fi
    
    if [[ -z "$main_class" ]]; then
        main_class=$(basename "${class_files[0]}" .class)
    fi
    
    local java_opts="${JAVA_RUN_OPTS:-}"
    
    output_info "Running: java $java_opts -cp $build_dir $main_class"
    
    if java $java_opts -cp "$build_dir" "$main_class"; then
        step_end "true"
        output_success "Tests passed"
        return 0
    else
        step_end "false"
        output_error "Tests failed"
        return 1
    fi
}

java_jar() {
    local build_dir="${BUILD_DIR:-output}/classes"
    local jar_name="${PROJECT_NAME:-app}"
    local jar_version="${PROJECT_VERSION:-}"
    local jar_output="${JAR_OUTPUT:-}"
    
    if [[ -z "$jar_output" ]]; then
        if [[ -n "$jar_version" ]]; then
            jar_output="${jar_name}-${jar_version}.jar"
        else
            jar_output="${jar_name}.jar"
        fi
    fi
    
    local jar_file="${BUILD_DIR:-output}/${jar_output}"
    
    step_start "Creating JAR file: $jar_output"
    
    if [[ ! -d "$build_dir" ]]; then
        output_error "Build directory not found. Run 'build build' first."
        step_end "false"
        return 1
    fi
    
    ensure_dir "$(dirname "$jar_file")"
    
    local manifest="${BUILD_DIR:-output}/MANIFEST.MF"
    local main_class="${MAIN_CLASS:-}"
    
    if [[ -n "$main_class" ]]; then
        echo "Manifest-Version: 1.0" > "$manifest"
        echo "Main-Class: $main_class" >> "$manifest"
        echo "" >> "$manifest"
        
        if jar cfm "$jar_file" "$manifest" -C "$build_dir" .; then
            output_info "Created executable JAR file: $jar_file"
            output_info "Main-Class: $main_class"
        else
            output_error "JAR creation failed"
            step_end "false"
            return 1
        fi
    else
        if jar cf "$jar_file" -C "$build_dir" .; then
            output_info "Created JAR file: $jar_file"
        else
            output_error "JAR creation failed"
            step_end "false"
            return 1
        fi
    fi
    
    output_info "Size: $(file_size_human "$jar_file")"
    step_end "true"
    output_success "JAR creation completed"
    return 0
}

java_run() {
    local build_dir="${BUILD_DIR:-output}/classes"
    local main_class="${MAIN_CLASS:-}"
    
    output_section "Running Java application"
    
    if [[ ! -d "$build_dir" ]]; then
        output_error "Build directory not found. Run 'build build' first."
        return 1
    fi
    
    if [[ -z "$main_class" ]]; then
        local -a class_files=()
        while IFS= read -r -d '' file; do
            class_files+=("$file")
        done < <(find "$build_dir" -name "*.class" -print0 2>/dev/null)
        
        for class_file in "${class_files[@]}"; do
            local relative="${class_file#$build_dir/}"
            local class_path="${relative%.class}"
            class_path="${class_path//\//.}"
            
            if javap -p "$class_file" 2>/dev/null | grep -q "public static void main"; then
                main_class="$class_path"
                break
            fi
        done
    fi
    
    if [[ -z "$main_class" ]]; then
        output_error "No main class found. Set MAIN_CLASS in build.sh"
        return 1
    fi
    
    local java_opts="${JAVA_RUN_OPTS:-}"
    
    output_info "Running: java $java_opts -cp $build_dir $main_class"
    
    exec java $java_opts -cp "$build_dir" "$main_class"
}
