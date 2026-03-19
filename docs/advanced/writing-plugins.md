# 编写插件

本文档详细介绍如何为 build-tool 编写自定义插件。

---

## 目录

- [插件基础](#插件基础)
- [创建插件](#创建插件)
- [插件结构](#插件结构)
- [注册目标](#注册目标)
- [注册钩子](#注册钩子)
- [国际化支持](#国际化支持)
- [错误处理](#错误处理)
- [完整插件示例](#完整插件示例)
- [插件测试](#插件测试)
- [最佳实践](#最佳实践)

---

## 插件基础

### 什么是插件？

插件是 build-tool 的扩展模块，用于：

- 支持新的编程语言
- 提供特定工具的集成
- 实现自定义构建流程
- 扩展构建工具功能

### 插件能做什么？

- 注册构建目标（如 `build`, `test`, `run`）
- 声明命令依赖（如 `javac`, `python`）
- 声明系统包依赖（如 `openjdk-17-jdk`）
- 注册构建钩子
- 提供国际化支持

---

## 创建插件

### 使用命令创建

```bash
# 在 plugins/ 目录创建插件
build plugin create my-plugin

# 在指定目录创建插件
build plugin create my-plugin custom-plugins
```

### 手动创建

创建文件 `plugins/my-plugin.sh`：

```bash
#!/usr/bin/env bash

PLUGIN_NAME="my-plugin"
PLUGIN_VERSION="1.0.0"
PLUGIN_DESCRIPTION="我的自定义插件"
PLUGIN_DEPENDENCIES=""
PLUGIN_PACKAGES_STR=""

register_target "build" "构建项目" "my_plugin_build"
register_target "clean" "清理构建产物" "my_plugin_clean"

my_plugin_build() {
    step_start "构建中..."
    output_info "执行构建..."
    step_end
    return 0
}

my_plugin_clean() {
    output_info "清理中..."
    rm -rf "${BUILD_DIR:-output}"
    return 0
}
```

---

## 插件结构

### 完整插件模板

```bash
#!/usr/bin/env bash

# ============================================
# 插件元数据
# ============================================
PLUGIN_NAME="my-plugin"
PLUGIN_VERSION="1.0.0"
PLUGIN_DESCRIPTION="插件描述"
PLUGIN_DEPENDENCIES="command1,command2"
PLUGIN_PACKAGES_STR="package1,package2"

# ============================================
# 插件变量
# ============================================
declare -g MY_PLUGIN_OPTION="${MY_PLUGIN_OPTION:-default}"

# ============================================
# 国际化支持
# ============================================
declare -gA MY_PLUGIN_I18N_EN=()
declare -gA MY_PLUGIN_I18N_ZH=()
declare -g MY_PLUGIN_I18N_LANG="zh"

_my_plugin_init_i18n() {
    MY_PLUGIN_I18N_EN=(
        ["build"]="Build project"
        ["clean"]="Clean artifacts"
    )
    
    MY_PLUGIN_I18N_ZH=(
        ["build"]="构建项目"
        ["clean"]="清理构建产物"
    )
}

my_plugin_i18n_get() {
    local key="$1"
    if [[ "$MY_PLUGIN_I18N_LANG" == "zh" ]]; then
        echo "${MY_PLUGIN_I18N_ZH[$key]:-$key}"
    else
        echo "${MY_PLUGIN_I18N_EN[$key]:-$key}"
    fi
}

# ============================================
# 钩子函数
# ============================================
pre_build_hook() {
    log_info "准备构建..."
}

post_build_hook() {
    log_info "构建完成!"
}

# ============================================
# 目标函数
# ============================================
my_plugin_build() {
    step_start "构建中..."
    
    local src_dir="${SOURCE_DIR:-src}"
    local build_dir="${BUILD_DIR:-output}"
    
    # 检查依赖
    if ! check_dependencies "command1"; then
        step_end "false"
        return 1
    fi
    
    # 创建目录
    ensure_dir "$build_dir"
    
    # 构建逻辑
    output_info "编译源码..."
    
    step_end
    return 0
}

my_plugin_clean() {
    output_info "清理构建产物..."
    rm -rf "${BUILD_DIR:-output}"
    return 0
}

my_plugin_test() {
    step_start "运行测试..."
    
    # 测试逻辑
    output_info "执行测试..."
    
    step_end
    return 0
}

my_plugin_run() {
    local build_dir="${BUILD_DIR:-output}"
    
    output_info "运行程序..."
    
    # 运行逻辑
    exec my-program
}

# ============================================
# 目标注册
# ============================================
register_target "build" "构建项目" "my_plugin_build"
register_target "clean" "清理构建产物" "my_plugin_clean"
register_target "test" "运行测试" "my_plugin_test"
register_target "run" "运行程序" "my_plugin_run"

register_target_deps "test" "build"
register_target_deps "run" "build"

# ============================================
# 钩子注册
# ============================================
register_hook "pre_build" "my-plugin" "pre_build_hook"
register_hook "post_build" "my-plugin" "post_build_hook"

# ============================================
# 初始化
# ============================================
_my_plugin_init_i18n
```

---

## 注册目标

### 基本注册

```bash
# 基本格式
register_target "目标名" "描述" "函数名"

# 示例
register_target "build" "构建项目" "my_plugin_build"
register_target "test" "运行测试" "my_plugin_test"
register_target "clean" "清理构建产物" "my_plugin_clean"
```

### 带依赖注册

```bash
# 注册目标依赖
register_target_deps "目标名" "依赖1,依赖2"

# 示例
register_target_deps "test" "build"
register_target_deps "package" "build,test"
register_target_deps "release" "build,test,package"
```

### 目标函数规范

```bash
my_plugin_build() {
    # 1. 开始步骤（可选）
    step_start "步骤描述"
    
    # 2. 获取配置
    local src_dir="${SOURCE_DIR:-src}"
    local build_dir="${BUILD_DIR:-output}"
    
    # 3. 检查依赖
    if ! check_dependencies "javac"; then
        step_end "false"
        return 1
    fi
    
    # 4. 执行构建逻辑
    ensure_dir "$build_dir"
    
    # 5. 输出进度
    output_info "编译中..."
    output_progress_start 10
    
    for file in "${files[@]}"; do
        # 处理文件
        output_progress_update
    done
    
    output_progress_end
    
    # 6. 结束步骤
    step_end
    
    # 7. 返回状态
    return 0
}
```

---

## 注册钩子

### 钩子类型

| 钩子类型 | 触发时机 | 用途 |
|----------|----------|------|
| `pre_build` | 目标执行前 | 准备工作 |
| `post_build` | 目标执行后（成功） | 清理、通知 |
| `on_error` | 目标执行后（失败） | 错误处理 |
| `on_clean` | 执行 clean 命令时 | 自定义清理 |

### 注册钩子

```bash
# 格式
register_hook "钩子类型" "插件名" "钩子函数"

# 示例
register_hook "pre_build" "my-plugin" "my_pre_build_hook"
register_hook "post_build" "my-plugin" "my_post_build_hook"
register_hook "on_error" "my-plugin" "my_on_error_hook"
register_hook "on_clean" "my-plugin" "my_on_clean_hook"
```

### 钩子函数示例

```bash
my_pre_build_hook() {
    log_info "准备构建..."
    
    # 检查环境
    if ! command_exists "javac"; then
        output_error "未找到 javac"
        return 1
    fi
    
    # 创建目录
    ensure_dir "$BUILD_DIR"
}

my_post_build_hook() {
    log_info "构建完成!"
    
    # 清理临时文件
    rm -rf /tmp/build-*
}

my_on_error_hook() {
    log_error "构建失败!"
    
    # 记录错误
    echo "[$(date)] Build failed" >> build-errors.log
}

my_on_clean_hook() {
    log_info "清理中..."
    rm -rf "$BUILD_DIR"
    rm -rf .cache
}
```

---

## 国际化支持

### 定义国际化字符串

```bash
# 声明变量
declare -gA MY_PLUGIN_I18N_EN=()
declare -gA MY_PLUGIN_I18N_ZH=()
declare -g MY_PLUGIN_I18N_LANG="zh"

# 初始化字符串
_my_plugin_init_i18n() {
    MY_PLUGIN_I18N_EN=(
        ["build"]="Build project"
        ["clean"]="Clean artifacts"
        ["compiling"]="Compiling sources"
        ["no_sources"]="No source files found"
        ["compile_success"]="Successfully compiled %d files"
        ["compile_failed"]="%d files failed to compile"
    )
    
    MY_PLUGIN_I18N_ZH=(
        ["build"]="构建项目"
        ["clean"]="清理构建产物"
        ["compiling"]="编译源码中"
        ["no_sources"]="未找到源码文件"
        ["compile_success"]="成功编译 %d 个文件"
        ["compile_failed"]="%d 个文件编译失败"
    )
    
    # 根据系统语言设置
    if [[ -n "$LANG" ]] && [[ "$LANG" == *"zh"* ]]; then
        MY_PLUGIN_I18N_LANG="zh"
    else
        MY_PLUGIN_I18N_LANG="en"
    fi
}

# 获取国际化字符串
my_plugin_i18n_get() {
    local key="$1"
    if [[ "$MY_PLUGIN_I18N_LANG" == "zh" ]]; then
        echo "${MY_PLUGIN_I18N_ZH[$key]:-$key}"
    else
        echo "${MY_PLUGIN_I18N_EN[$key]:-$key}"
    fi
}
```

### 使用国际化

```bash
my_plugin_build() {
    step_start "$(my_plugin_i18n_get "compiling")"
    
    # 检查源文件
    if [[ ${#sources[@]} -eq 0 ]]; then
        output_warning "$(my_plugin_i18n_get "no_sources")"
        step_end
        return 0
    fi
    
    # 编译
    local success=0
    local failed=0
    
    for src in "${sources[@]}"; do
        if compile "$src"; then
            ((success++))
        else
            ((failed++))
        fi
    done
    
    # 输出结果
    if [[ $failed -gt 0 ]]; then
        output_error "$(printf "$(my_plugin_i18n_get "compile_failed")" $failed)"
        step_end "false"
        return 1
    else
        output_success "$(printf "$(my_plugin_i18n_get "compile_success")" $success)"
        step_end
        return 0
    fi
}
```

---

## 错误处理

### 检查依赖

```bash
my_plugin_build() {
    # 检查命令依赖
    if ! check_dependencies "javac" "jar"; then
        output_error "缺少必需的工具"
        output_info "安装: build install openjdk-17-jdk"
        return 1
    fi
    
    # 继续构建...
}
```

### 处理文件错误

```bash
my_plugin_build() {
    for src in "${sources[@]}"; do
        # 检查文件是否存在
        if [[ ! -f "$src" ]]; then
            output_error "文件不存在: $src"
            continue
        fi
        
        # 检查文件是否可读
        if [[ ! -r "$src" ]]; then
            output_error "无法读取文件: $src"
            continue
        fi
        
        # 处理文件...
    done
}
```

### 使用 try-catch 模式

```bash
my_plugin_build() {
    local errors=0
    
    # 尝试执行多个步骤
    {
        step_start "步骤 1"
        # 步骤 1 逻辑
        step_end
    } || {
        output_error "步骤 1 失败"
        ((errors++))
    }
    
    {
        step_start "步骤 2"
        # 步骤 2 逻辑
        step_end
    } || {
        output_error "步骤 2 失败"
        ((errors++))
    }
    
    # 返回结果
    if [[ $errors -gt 0 ]]; then
        return 1
    fi
    return 0
}
```

---

## 完整插件示例

### Python 插件示例

```bash
#!/usr/bin/env bash

PLUGIN_NAME="python"
PLUGIN_VERSION="1.0.0"
PLUGIN_DESCRIPTION="Python 构建插件"
PLUGIN_DEPENDENCIES="python3,pip"
PLUGIN_PACKAGES_STR="python3,python3-pip"

declare -g PYTHON_MAIN="${PYTHON_MAIN:-main.py}"
declare -g PYTHON_VENV="${PYTHON_VENV:-venv}"
declare -g PYTHON_REQUIREMENTS="${PYTHON_REQUIREMENTS:-requirements.txt}"

declare -gA PYTHON_I18N_EN=()
declare -gA PYTHON_I18N_ZH=()
declare -g PYTHON_I18N_LANG="zh"

_python_init_i18n() {
    PYTHON_I18N_EN=(
        ["build"]="Build Python project"
        ["clean"]="Clean build artifacts"
        ["test"]="Run tests"
        ["run"]="Run application"
        ["venv_create"]="Creating virtual environment"
        ["venv_activate"]="Activating virtual environment"
        ["install_deps"]="Installing dependencies"
        ["no_requirements"]="No requirements.txt found"
        ["running"]="Running"
    )
    
    PYTHON_I18N_ZH=(
        ["build"]="构建 Python 项目"
        ["clean"]="清理构建产物"
        ["test"]="运行测试"
        ["run"]="运行应用程序"
        ["venv_create"]="创建虚拟环境"
        ["venv_activate"]="激活虚拟环境"
        ["install_deps"]="安装依赖"
        ["no_requirements"]="未找到 requirements.txt"
        ["running"]="运行中"
    )
    
    if [[ -n "$LANG" ]] && [[ "$LANG" == *"zh"* ]]; then
        PYTHON_I18N_LANG="zh"
    else
        PYTHON_I18N_LANG="en"
    fi
}

python_i18n_get() {
    local key="$1"
    if [[ "$PYTHON_I18N_LANG" == "zh" ]]; then
        echo "${PYTHON_I18N_ZH[$key]:-$key}"
    else
        echo "${PYTHON_I18N_EN[$key]:-$key}"
    fi
}

pre_build_hook() {
    log_info "$(python_i18n_get "venv_create")"
    
    if [[ ! -d "$PYTHON_VENV" ]]; then
        python3 -m venv "$PYTHON_VENV"
    fi
    
    log_info "$(python_i18n_get "install_deps")"
    
    if [[ -f "$PYTHON_REQUIREMENTS" ]]; then
        source "$PYTHON_VENV/bin/activate"
        pip install -r "$PYTHON_REQUIREMENTS"
        deactivate
    else
        output_warning "$(python_i18n_get "no_requirements")"
    fi
}

python_build() {
    step_start "$(python_i18n_get "build")"
    
    # Python 是解释型语言，主要是检查语法
    local src_dir="${SOURCE_DIR:-src}"
    local errors=0
    
    while IFS= read -r -d '' file; do
        if ! python3 -m py_compile "$file" 2>&1; then
            output_error "语法错误: $file"
            ((errors++))
        fi
    done < <(find "$src_dir" -name "*.py" -print0 2>/dev/null)
    
    step_end
    
    if [[ $errors -gt 0 ]]; then
        return 1
    fi
    return 0
}

python_clean() {
    output_info "$(python_i18n_get "clean")"
    
    rm -rf "$PYTHON_VENV"
    rm -rf "${BUILD_DIR:-output}"
    rm -rf __pycache__
    rm -rf .pytest_cache
    rm -rf .mypy_cache
    rm -rf "*.egg-info"
    rm -rf dist
    rm -rf build
    
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
    find . -type f -name "*.pyc" -delete 2>/dev/null
    
    return 0
}

python_test() {
    step_start "$(python_i18n_get "test")"
    
    source "$PYTHON_VENV/bin/activate"
    
    if command_exists pytest; then
        pytest
    else
        python3 -m unittest discover
    fi
    
    local result=$?
    deactivate
    
    step_end
    return $result
}

python_run() {
    output_info "$(python_i18n_get "run")"
    
    source "$PYTHON_VENV/bin/activate"
    exec python3 "$PYTHON_MAIN"
}

register_target "build" "$(python_i18n_get "build")" "python_build"
register_target "clean" "$(python_i18n_get "clean")" "python_clean"
register_target "test" "$(python_i18n_get "test")" "python_test"
register_target "run" "$(python_i18n_get "run")" "python_run"

register_target_deps "test" "build"
register_target_deps "run" "build"

register_hook "pre_build" "python" "pre_build_hook"

_python_init_i18n
```

---

## 插件测试

### 手动测试

```bash
# 验证插件语法
bash -n plugins/my-plugin.sh

# 加载插件测试
source plugins/my-plugin.sh

# 测试目标函数
my_plugin_build
```

### 使用验证命令

```bash
# 验证插件
build plugin validate my-plugin
```

### 测试脚本

创建 `tests/test-my-plugin.sh`：

```bash
#!/usr/bin/env bash

source "plugins/my-plugin.sh"

test_build() {
    # 设置测试环境
    SOURCE_DIR="test-fixtures/src"
    BUILD_DIR="test-fixtures/output"
    
    # 执行构建
    if my_plugin_build; then
        echo "✓ build 测试通过"
    else
        echo "✗ build 测试失败"
        return 1
    fi
    
    # 验证输出
    if [[ -d "$BUILD_DIR" ]]; then
        echo "✓ 输出目录已创建"
    else
        echo "✗ 输出目录未创建"
        return 1
    fi
    
    # 清理
    rm -rf "$BUILD_DIR"
}

test_clean() {
    mkdir -p "$BUILD_DIR"
    
    if my_plugin_clean; then
        echo "✓ clean 测试通过"
    else
        echo "✗ clean 测试失败"
        return 1
    fi
}

# 运行测试
test_build
test_clean
```

---

## 最佳实践

### 1. 命名规范

```bash
# 推荐：使用插件名作为前缀
PLUGIN_NAME="python"
register_target "build" "..." "python_build"
register_target "test" "..." "python_test"

# 不推荐：使用通用名称
register_target "build" "..." "build"  # 可能冲突
```

### 2. 错误处理

```bash
# 推荐：检查并报告错误
my_plugin_build() {
    if ! check_dependencies "python3"; then
        output_error "缺少 Python 3"
        return 1
    fi
    
    # 构建逻辑...
}

# 不推荐：忽略错误
my_plugin_build() {
    python3 compile.py  # 不检查结果
}
```

### 3. 使用步骤 API

```bash
# 推荐：使用步骤 API
my_plugin_build() {
    step_start "编译源码"
    # 编译逻辑
    step_end
    return 0
}

# 不推荐：直接输出
my_plugin_build() {
    echo "编译源码..."  # 不使用 API
}
```

### 4. 配置可覆盖

```bash
# 推荐：使用变量并支持覆盖
declare -g MY_OPTION="${MY_OPTION:-default}"

# 不推荐：硬编码
MY_OPTION="default"  # 无法覆盖
```

### 5. 文档注释

```bash
# 推荐：添加注释
# 构建项目
# 编译所有源文件到输出目录
# 使用增量构建优化性能
my_plugin_build() {
    # ...
}
```

---

## 下一步

- [插件系统](../user-guide/plugins.md) - 了解插件系统
- [钩子系统](../user-guide/hooks.md) - 了解钩子
- [目标系统](../user-guide/targets.md) - 了解目标
- [插件模块 API](../api-reference/plugin-api.md) - 插件 API 参考
