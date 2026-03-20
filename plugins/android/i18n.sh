#!/usr/bin/env bash

if [[ -z "${_ANDROID_I18N_LOADED:-}" ]]; then
_ANDROID_I18N_LOADED=1

declare -gA ANDROID_I18N_EN=()
declare -gA ANDROID_I18N_ZH=()
declare -g ANDROID_I18N_LANG="zh"

_android_init_i18n() {
    ANDROID_I18N_EN=(
        ["plugin_name"]="Android Build Plugin"
        ["plugin_desc"]="Complete Android build system without Gradle"
        
        ["check_environment"]="Checking Android build environment"
        ["sdk_not_found"]="Android SDK not found"
        ["sdk_found"]="Android SDK found"
        ["sdk_invalid"]="Android SDK path is invalid"
        ["sdk_validating"]="Validating Android SDK"
        
        ["java_not_found"]="Java not found. Please install JDK 11 or later"
        ["java_found"]="Java found"
        ["java_version_check"]="Checking Java version"
        ["java_version_incompatible"]="Java version incompatible. Required: 11+, Found: %s"
        ["javac_not_found"]="javac not found. Please install JDK (not JRE)"
        ["java_home_not_set"]="JAVA_HOME is not set"
        ["java_home_detected"]="JAVA_HOME detected"
        
        ["build_tools_not_found"]="Build tools not found"
        ["build_tools_found"]="Build tools found"
        ["platform_not_found"]="Platform not found"
        ["platform_found"]="Platform found"
        ["cmdline_tools_not_found"]="Android command-line tools not found"
        ["cmdline_tools_found"]="Android command-line tools found"
        
        ["downloading_cmdline_tools"]="Downloading Android command-line tools"
        ["download_failed"]="Download failed"
        ["download_success"]="Download completed"
        ["extracting_cmdline_tools"]="Extracting command-line tools"
        ["extract_failed"]="Extraction failed"
        
        ["installing_sdk_component"]="Installing SDK component"
        ["install_failed"]="Installation failed"
        ["install_success"]="Installation completed"
        ["accepting_licenses"]="Accepting SDK licenses"
        
        ["setting_up_env"]="Setting up environment variables"
        ["env_added_to"]="Environment variables added to"
        ["please_source"]="Please run: source %s"
        
        ["creating_sdk_dir"]="Creating SDK directory"
        ["sdk_dir_created"]="SDK directory created"
        
        ["check_passed"]="All environment checks passed"
        ["check_failed"]="Environment check failed"
        ["missing_components"]="Missing required components"
        
        ["setup_required"]="Android SDK setup required"
        ["setup_prompt"]="Do you want to install Android SDK?"
        ["setup_skipped"]="Setup skipped"
        ["setup_complete"]="Android SDK setup complete"
        
        ["build_start"]="Starting Android build"
        ["build_complete"]="Android build completed successfully"
        ["build_failed"]="Android build failed"
        
        ["clean_start"]="Cleaning Android build"
        ["clean_complete"]="Clean completed"
        ["nothing_to_clean"]="Nothing to clean"
        
        ["deps_resolving"]="Resolving dependencies"
        ["deps_downloading"]="Downloading dependencies"
        ["deps_resolved"]="Dependencies resolved"
        ["deps_failed"]="Failed to resolve dependencies"
        
        ["resources_compiling"]="Compiling resources"
        ["resources_compiled"]="Resources compiled"
        ["resources_failed"]="Resource compilation failed"
        
        ["java_compiling"]="Compiling Java sources"
        ["kotlin_compiling"]="Compiling Kotlin sources"
        ["compile_complete"]="Compilation completed"
        ["compile_failed"]="Compilation failed"
        
        ["dex_converting"]="Converting to DEX"
        ["dex_complete"]="DEX conversion completed"
        ["dex_failed"]="DEX conversion failed"
        
        ["packaging"]="Packaging APK"
        ["package_complete"]="APK packaged"
        ["package_failed"]="Packaging failed"
        
        ["signing"]="Signing APK"
        ["sign_complete"]="APK signed"
        ["sign_failed"]="Signing failed"
        
        ["installing"]="Installing to device"
        ["install_complete"]="Installation complete"
        ["install_failed"]="Installation failed"
        
        ["no_device"]="No device connected"
        ["multiple_devices"]="Multiple devices connected"
        ["device_connected"]="Device connected"
        
        ["emulator_starting"]="Starting emulator"
        ["emulator_started"]="Emulator started"
        ["emulator_failed"]="Failed to start emulator"
        ["no_avd"]="No AVD found"
        
        ["unsupported_platform"]="Unsupported platform: %s"
        ["missing_config"]="Missing required configuration: %s"
        ["invalid_config"]="Invalid configuration: %s"
        
        ["downloading"]="Downloading"
        ["extracting"]="Extracting"
        ["copying"]="Copying"
        ["creating"]="Creating"
        
        ["yes"]="Yes"
        ["no"]="No"
        ["ok"]="OK"
        ["cancel"]="Cancel"
        ["skip"]="Skip"
        ["retry"]="Retry"
        ["abort"]="Abort"
    )
    
    ANDROID_I18N_ZH=(
        ["plugin_name"]="Android 构建插件"
        ["plugin_desc"]="完整的 Android 构建系统，无需 Gradle"
        
        ["check_environment"]="检查 Android 构建环境"
        ["sdk_not_found"]="未找到 Android SDK"
        ["sdk_found"]="已找到 Android SDK"
        ["sdk_invalid"]="Android SDK 路径无效"
        ["sdk_validating"]="验证 Android SDK"
        
        ["java_not_found"]="未找到 Java。请安装 JDK 11 或更高版本"
        ["java_found"]="已找到 Java"
        ["java_version_check"]="检查 Java 版本"
        ["java_version_incompatible"]="Java 版本不兼容。要求: 11+, 当前: %s"
        ["javac_not_found"]="未找到 javac。请安装 JDK（不是 JRE）"
        ["java_home_not_set"]="JAVA_HOME 未设置"
        ["java_home_detected"]="已检测到 JAVA_HOME"
        
        ["build_tools_not_found"]="未找到 Build tools"
        ["build_tools_found"]="已找到 Build tools"
        ["platform_not_found"]="未找到 Platform"
        ["platform_found"]="已找到 Platform"
        ["cmdline_tools_not_found"]="未找到 Android 命令行工具"
        ["cmdline_tools_found"]="已找到 Android 命令行工具"
        
        ["downloading_cmdline_tools"]="正在下载 Android 命令行工具"
        ["download_failed"]="下载失败"
        ["download_success"]="下载完成"
        ["extracting_cmdline_tools"]="正在解压命令行工具"
        ["extract_failed"]="解压失败"
        
        ["installing_sdk_component"]="正在安装 SDK 组件"
        ["install_failed"]="安装失败"
        ["install_success"]="安装完成"
        ["accepting_licenses"]="正在接受 SDK 许可"
        
        ["setting_up_env"]="正在设置环境变量"
        ["env_added_to"]="环境变量已添加到"
        ["please_source"]="请运行: source %s"
        
        ["creating_sdk_dir"]="正在创建 SDK 目录"
        ["sdk_dir_created"]="SDK 目录已创建"
        
        ["check_passed"]="所有环境检查通过"
        ["check_failed"]="环境检查失败"
        ["missing_components"]="缺少必需组件"
        
        ["setup_required"]="需要设置 Android SDK"
        ["setup_prompt"]="是否安装 Android SDK？"
        ["setup_skipped"]="已跳过设置"
        ["setup_complete"]="Android SDK 设置完成"
        
        ["build_start"]="开始 Android 构建"
        ["build_complete"]="Android 构建成功完成"
        ["build_failed"]="Android 构建失败"
        
        ["clean_start"]="正在清理 Android 构建"
        ["clean_complete"]="清理完成"
        ["nothing_to_clean"]="无内容可清理"
        
        ["deps_resolving"]="正在解析依赖"
        ["deps_downloading"]="正在下载依赖"
        ["deps_resolved"]="依赖解析完成"
        ["deps_failed"]="依赖解析失败"
        
        ["resources_compiling"]="正在编译资源"
        ["resources_compiled"]="资源编译完成"
        ["resources_failed"]="资源编译失败"
        
        ["java_compiling"]="正在编译 Java 源码"
        ["kotlin_compiling"]="正在编译 Kotlin 源码"
        ["compile_complete"]="编译完成"
        ["compile_failed"]="编译失败"
        
        ["dex_converting"]="正在转换为 DEX"
        ["dex_complete"]="DEX 转换完成"
        ["dex_failed"]="DEX 转换失败"
        
        ["packaging"]="正在打包 APK"
        ["package_complete"]="APK 打包完成"
        ["package_failed"]="打包失败"
        
        ["signing"]="正在签名 APK"
        ["sign_complete"]="APK 签名完成"
        ["sign_failed"]="签名失败"
        
        ["installing"]="正在安装到设备"
        ["install_complete"]="安装完成"
        ["install_failed"]="安装失败"
        
        ["no_device"]="未连接设备"
        ["multiple_devices"]="已连接多个设备"
        ["device_connected"]="设备已连接"
        
        ["emulator_starting"]="正在启动模拟器"
        ["emulator_started"]="模拟器已启动"
        ["emulator_failed"]="模拟器启动失败"
        ["no_avd"]="未找到 AVD"
        
        ["unsupported_platform"]="不支持的平台: %s"
        ["missing_config"]="缺少必需配置: %s"
        ["invalid_config"]="无效配置: %s"
        
        ["downloading"]="正在下载"
        ["extracting"]="正在解压"
        ["copying"]="正在复制"
        ["creating"]="正在创建"
        
        ["yes"]="是"
        ["no"]="否"
        ["ok"]="确定"
        ["cancel"]="取消"
        ["skip"]="跳过"
        ["retry"]="重试"
        ["abort"]="中止"
    )
    
    if [[ -n "${LANG:-}" ]]; then
        if [[ "$LANG" == *"zh"* ]]; then
            ANDROID_I18N_LANG="zh"
        else
            ANDROID_I18N_LANG="en"
        fi
    fi
}

android_i18n_get() {
    local key="$1"
    local -n strings_ref
    
    if [[ "$ANDROID_I18N_LANG" == "zh" ]]; then
        strings_ref=ANDROID_I18N_ZH
    else
        strings_ref=ANDROID_I18N_EN
    fi
    
    if [[ -n "${strings_ref[$key]:-}" ]]; then
        echo "${strings_ref[$key]}"
    else
        echo "$key"
    fi
}

android_i18n_printf() {
    local key="$1"
    shift
    local msg
    msg=$(android_i18n_get "$key")
    printf "$msg" "$@"
}

_android_init_i18n

fi
