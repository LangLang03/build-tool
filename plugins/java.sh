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

declare -gA JAVA_I18N_EN=()
declare -gA JAVA_I18N_ZH=()
declare -g JAVA_I18N_LANG="zh"

_java_init_i18n() {
    JAVA_I18N_EN=(
        ["compile_sources"]="Compile Java sources"
        ["clean_artifacts"]="Clean Java build artifacts"
        ["run_tests"]="Run Java tests"
        ["create_jar"]="Create JAR file"
        ["run_app"]="Run the main class"
        ["preparing_build"]="Preparing Java build..."
        ["build_completed"]="Java build completed successfully!"
        ["preparing_dir"]="Preparing build directory"
        ["scanning_sources"]="Scanning Java sources"
        ["found_sources"]="Found $total Java source file(s)"
        ["no_sources"]="No Java source files found"
        ["create_hint"]="Create .java files in current directory or ${src_dir}/ directory"
        ["compiling"]="Compiling Java sources"
        ["compile_failed"]="$failed file(s) failed to compile"
        ["compile_success"]="Successfully compiled $success Java file(s)"
        ["cleaning"]="Cleaning Java build"
        ["removing"]="Removing $build_dir"
        ["clean_completed"]="Clean completed"
        ["nothing_clean"]="Nothing to clean"
        ["running_tests"]="Running Java tests"
        ["build_not_found"]="Build directory not found. Run 'build build' first."
        ["no_classes"]="No compiled classes found"
        ["running_main"]="Running main class"
        ["running_cmd"]="Running: java $java_opts -cp $build_dir $main_class"
        ["tests_passed"]="Tests passed"
        ["tests_failed"]="Tests failed"
        ["creating_jar"]="Creating JAR file: $jar_output"
        ["created_executable"]="Created executable JAR file: $jar_file"
        ["created_jar"]="Created JAR file: $jar_file"
        ["main_class"]="Main-Class: $main_class"
        ["jar_failed"]="JAR creation failed"
        ["jar_completed"]="JAR creation completed"
        ["jar_size"]="Size: $(file_size_human "$jar_file")"
        ["running_app"]="Running Java application"
        ["no_main_class"]="No main class found. Set MAIN_CLASS in build.sh"
    )
    
    JAVA_I18N_ZH=(
        ["compile_sources"]="编译 Java 源码"
        ["clean_artifacts"]="清理 Java 构建产物"
        ["run_tests"]="运行 Java 测试"
        ["create_jar"]="创建 JAR 文件"
        ["run_app"]="运行主类"
        ["preparing_build"]="准备 Java 构建..."
        ["build_completed"]="Java 构建成功完成!"
        ["preparing_dir"]="准备构建目录"
        ["scanning_sources"]="扫描 Java 源码"
        ["found_sources"]="找到 $total 个 Java 源码文件"
        ["no_sources"]="未找到 Java 源码文件"
        ["create_hint"]="在当前目录或 ${src_dir}/ 目录中创建 .java 文件"
        ["compiling"]="编译 Java 源码"
        ["compile_failed"]="$failed 个文件编译失败"
        ["compile_success"]="成功编译 $success 个 Java 文件"
        ["cleaning"]="清理 Java 构建"
        ["removing"]="删除 $build_dir"
        ["clean_completed"]="清理完成"
        ["nothing_clean"]="无内容可清理"
        ["running_tests"]="运行 Java 测试"
        ["build_not_found"]="未找到构建目录。请先运行 'build build'。"
        ["no_classes"]="未找到编译后的类文件"
        ["running_main"]="运行主类"
        ["running_cmd"]="运行: java $java_opts -cp $build_dir $main_class"
        ["tests_passed"]="测试通过"
        ["tests_failed"]="测试失败"
        ["creating_jar"]="创建 JAR 文件: $jar_output"
        ["created_executable"]="已创建可执行 JAR 文件: $jar_file"
        ["created_jar"]="已创建 JAR 文件: $jar_file"
        ["main_class"]="主类: $main_class"
        ["jar_failed"]="JAR 创建失败"
        ["jar_completed"]="JAR 创建完成"
        ["jar_size"]="大小: $(file_size_human "$jar_file")"
        ["running_app"]="运行 Java 应用程序"
        ["no_main_class"]="未找到主类。请在 build.sh 中设置 MAIN_CLASS"
    )
    
    if [[ -n "$LANG" ]]; then
        if [[ "$LANG" == *"zh"* ]]; then
            JAVA_I18N_LANG="zh"
        else
            JAVA_I18N_LANG="en"
        fi
    fi
}

java_i18n_get() {
    local key="$1"
    local -n strings_ref
    
    if [[ "$JAVA_I18N_LANG" == "zh" ]]; then
        strings_ref=JAVA_I18N_ZH
    else
        strings_ref=JAVA_I18N_EN
    fi
    
    if [[ -n "${strings_ref[$key]:-}" ]]; then
        echo "${strings_ref[$key]}"
    else
        echo "$key"
    fi
}

_java_init_i18n

register_target "build" "$(java_i18n_get "compile_sources")" "java_build"
register_target "clean" "$(java_i18n_get "clean_artifacts")" "java_clean"
register_target "test" "$(java_i18n_get "run_tests")" "java_test"
register_target "jar" "$(java_i18n_get "create_jar")" "java_jar"
register_target "run" "$(java_i18n_get "run_app")" "java_run"

register_target_deps "jar" "build"
register_target_deps "test" "build"
register_target_deps "run" "build"

pre_build_hook() {
    log_info "$(java_i18n_get "preparing_build")"
}

post_build_hook() {
    log_info "$(java_i18n_get "build_completed")"
}

java_build() {
    local src_dir="${SOURCE_DIR:-src}"
    local build_dir="${BUILD_DIR:-output}/classes"
    
    step_start "$(java_i18n_get "preparing_dir")"
    ensure_dir "$build_dir"
    step_end
    
    step_start "$(java_i18n_get "scanning_sources")"
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
    output_info "$(java_i18n_get "found_sources")"
    step_end
    
    if [[ $total -eq 0 ]]; then
        output_warning "$(java_i18n_get "no_sources")"
        output_info "$(java_i18n_get "create_hint")"
        return 0
    fi
    
    step_start "$(java_i18n_get "compiling")"
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
        output_error "$(java_i18n_get "compile_failed")"
        return 1
    fi
    
    output_success "$(java_i18n_get "compile_success")"
    return 0
}

java_clean() {
    local build_dir="${BUILD_DIR:-output}"
    
    output_section "$(java_i18n_get "cleaning")"
    
    if [[ -d "$build_dir" ]]; then
        output_info "$(java_i18n_get "removing")"
        rm -rf "$build_dir"
        output_success "$(java_i18n_get "clean_completed")"
    else
        output_info "$(java_i18n_get "nothing_clean")"
    fi
    
    return 0
}

java_test() {
    local build_dir="${BUILD_DIR:-output}/classes"
    
    output_section "$(java_i18n_get "running_tests")"
    
    if [[ ! -d "$build_dir" ]]; then
        output_error "$(java_i18n_get "build_not_found")"
        return 1
    fi
    
    local -a class_files=()
    while IFS= read -r -d '' file; do
        class_files+=("$file")
    done < <(find "$build_dir" -name "*.class" -print0 2>/dev/null)
    
    if [[ ${#class_files[@]} -eq 0 ]]; then
        output_warning "$(java_i18n_get "no_classes")"
        return 0
    fi
    
    step_start "$(java_i18n_get "running_main")"
    
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
    
    output_info "$(java_i18n_get "running_cmd")"
    
    if java $java_opts -cp "$build_dir" "$main_class"; then
        step_end "true"
        output_success "$(java_i18n_get "tests_passed")"
        return 0
    else
        step_end "false"
        output_error "$(java_i18n_get "tests_failed")"
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
    
    step_start "$(java_i18n_get "creating_jar")"
    
    if [[ ! -d "$build_dir" ]]; then
        output_error "$(java_i18n_get "build_not_found")"
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
            output_info "$(java_i18n_get "created_executable")"
            output_info "$(java_i18n_get "main_class")"
        else
            output_error "$(java_i18n_get "jar_failed")"
            step_end "false"
            return 1
        fi
    else
        if jar cf "$jar_file" -C "$build_dir" .; then
            output_info "$(java_i18n_get "created_jar")"
        else
            output_error "$(java_i18n_get "jar_failed")"
            step_end "false"
            return 1
        fi
    fi
    
    output_info "$(java_i18n_get "jar_size")"
    step_end "true"
    output_success "$(java_i18n_get "jar_completed")"
    return 0
}

java_run() {
    local build_dir="${BUILD_DIR:-output}/classes"
    local main_class="${MAIN_CLASS:-}"
    
    output_section "$(java_i18n_get "running_app")"
    
    if [[ ! -d "$build_dir" ]]; then
        output_error "$(java_i18n_get "build_not_found")"
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
        output_error "$(java_i18n_get "no_main_class")"
        return 1
    fi
    
    local java_opts="${JAVA_RUN_OPTS:-}"
    
    output_info "$(java_i18n_get "running_cmd")"
    
    exec java $java_opts -cp "$build_dir" "$main_class"
}
