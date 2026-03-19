# 核心 API 参考

本文档详细介绍 `lib/core.sh` 模块提供的 API。

---

## 目录

- [模块概述](#模块概述)
- [全局变量](#全局变量)
- [目标管理](#目标管理)
- [依赖解析](#依赖解析)
- [目标执行](#目标执行)
- [步骤管理](#步骤管理)
- [并行构建](#并行构建)
- [构建生命周期](#构建生命周期)
- [工具函数](#工具函数)

---

## 模块概述

`core.sh` 是 build-tool 的核心模块，提供：

- 构建目标管理
- 依赖解析（拓扑排序）
- 目标执行引擎
- 步骤管理
- 并行构建支持
- 构建生命周期管理

---

## 全局变量

### 目标相关

```bash
declare -gA BUILD_TARGETS=()        # 目标名称映射
declare -gA BUILD_TARGET_DEPS=()    # 目标依赖映射
declare -gA BUILD_TARGET_DESC=()    # 目标描述映射
declare -gA BUILD_TARGET_FUNC=()    # 目标函数映射
declare -gA BUILD_TARGET_PLUGIN=()  # 目标所属插件
declare -ga BUILD_EXECUTED_TARGETS=() # 已执行的目标列表
declare -g BUILD_CURRENT_TARGET=""  # 当前执行的目标
```

### 构建状态

```bash
declare -g BUILD_START_TIME=0       # 构建开始时间
declare -g BUILD_END_TIME=0         # 构建结束时间
declare -g BUILD_SUCCESS_COUNT=0    # 成功目标数
declare -g BUILD_FAIL_COUNT=0       # 失败目标数
declare -g BUILD_SKIP_COUNT=0       # 跳过目标数
declare -g BUILD_RUNNING=false      # 是否正在构建
declare -g BUILD_INTERRUPTED=false  # 是否被中断
```

### 步骤相关

```bash
declare -gA STEP_INFO=()            # 步骤信息
declare -g CURRENT_STEP=""          # 当前步骤名称
declare -g STEP_START_TIME=0        # 步骤开始时间
```

### 并行相关

```bash
declare -g PARALLEL_ENABLED=true    # 是否启用并行
declare -g PARALLEL_JOBS=4          # 并行作业数
declare -g PARALLEL_PIDS=()         # 并行进程 PID 列表
declare -gA PARALLEL_RESULTS=()     # 并行结果映射
```

---

## 目标管理

### register_target

注册构建目标。

```bash
register_target <name> [description] [function] [plugin]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| name | string | 是 | - | 目标名称 |
| description | string | 否 | "无描述" | 目标描述 |
| function | string | 否 | `${name}_build` | 目标函数名 |
| plugin | string | 否 | core | 所属插件名 |

**示例：**

```bash
# 基本注册
register_target "build"

# 完整注册
register_target "build" "构建项目" "java_build" "java"

# 简洁注册
register_target "clean" "清理构建产物"
```

### register_target_deps

注册目标依赖。

```bash
register_target_deps <name> <deps>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| name | string | 是 | 目标名称 |
| deps | string | 是 | 依赖列表（逗号分隔） |

**示例：**

```bash
# 单个依赖
register_target_deps "test" "build"

# 多个依赖
register_target_deps "release" "build,test,package"
```

### target_exists

检查目标是否存在。

```bash
target_exists <name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| name | string | 是 | 目标名称 |

**返回值：**

- `0` - 目标存在
- `1` - 目标不存在

**示例：**

```bash
if target_exists "build"; then
    echo "build 目标存在"
fi
```

### get_target_func

获取目标函数名。

```bash
get_target_func <name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| name | string | 是 | 目标名称 |

**返回值：**

目标函数名（字符串）。

**示例：**

```bash
func=$(get_target_func "build")
echo "$func"  # 输出: java_build
```

### get_target_deps

获取目标依赖列表。

```bash
get_target_deps <name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| name | string | 是 | 目标名称 |

**返回值：**

依赖列表（逗号分隔的字符串）。

**示例：**

```bash
deps=$(get_target_deps "release")
echo "$deps"  # 输出: build,test,package
```

### get_target_desc

获取目标描述。

```bash
get_target_desc <name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| name | string | 是 | 目标名称 |

**返回值：**

目标描述（字符串）。

**示例：**

```bash
desc=$(get_target_desc "build")
echo "$desc"  # 输出: 构建项目
```

### list_targets

列出所有目标。

```bash
list_targets [verbose]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| verbose | string | 否 | false | 是否详细输出 |

**示例：**

```bash
# 简洁格式
list_targets "false"

# 详细格式
list_targets "true"
```

---

## 依赖解析

### resolve_deps

解析目标依赖（递归）。

```bash
resolve_deps <target> <resolved_var> <visiting_var>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| target | string | 是 | 目标名称 |
| resolved_var | string | 是 | 已解析变量名 |
| visiting_var | string | 是 | 正在访问变量名 |

**返回值：**

- `0` - 解析成功
- `1` - 存在循环依赖

**示例：**

```bash
declare -gA _RESOLVED=()
declare -gA _VISITING=()

if resolve_deps "release" "_RESOLVED" "_VISITING"; then
    echo "依赖解析成功"
fi
```

### get_build_order

获取构建执行顺序。

```bash
get_build_order <target>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| target | string | 是 | 目标名称 |

**返回值：**

构建顺序（空格分隔的目标列表）。

**示例：**

```bash
order=$(get_build_order "release")
echo "$order"  # 输出: build test package release
```

---

## 目标执行

### execute_target

执行单个目标。

```bash
execute_target <target>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| target | string | 是 | 目标名称 |

**返回值：**

- `0` - 执行成功
- `1` - 执行失败

**示例：**

```bash
if execute_target "build"; then
    echo "构建成功"
else
    echo "构建失败"
fi
```

### execute_target_with_deps

执行目标及其依赖。

```bash
execute_target_with_deps <target>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| target | string | 是 | 目标名称 |

**返回值：**

- `0` - 执行成功
- `1` - 执行失败

**示例：**

```bash
if execute_target_with_deps "release"; then
    echo "发布成功"
fi
```

---

## 步骤管理

### step_start

开始一个步骤。

```bash
step_start <name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| name | string | 是 | 步骤名称 |

**示例：**

```bash
step_start "编译源码"
# 执行编译逻辑
step_end
```

### step_end

结束当前步骤。

```bash
step_end [success]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| success | string | 否 | true | 是否成功 |

**示例：**

```bash
step_start "编译源码"

if compile_sources; then
    step_end "true"
else
    step_end "false"
fi
```

### step_skip

跳过一个步骤。

```bash
step_skip <name> [reason]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| name | string | 是 | - | 步骤名称 |
| reason | string | 否 | "无原因" | 跳过原因 |

**示例：**

```bash
step_skip "编译源码" "无变更"
```

---

## 并行构建

### parallel_init

初始化并行构建。

```bash
parallel_init [jobs]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| jobs | integer | 否 | CPU 核心数 | 并行作业数 |

**示例：**

```bash
parallel_init 8
```

### parallel_run

并行执行函数。

```bash
parallel_run <func> [args...]
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| func | string | 是 | 函数名 |
| args | any | 否 | 函数参数 |

**示例：**

```bash
compile_file() {
    local file="$1"
    # 编译逻辑
}

for file in "${sources[@]}"; do
    parallel_run compile_file "$file"
done

parallel_wait_all
```

### parallel_wait_one

等待一个并行任务完成。

```bash
parallel_wait_one
```

**返回值：**

- `0` - 任务成功
- `1` - 任务失败

**示例：**

```bash
parallel_wait_one
```

### parallel_wait_all

等待所有并行任务完成。

```bash
parallel_wait_all
```

**返回值：**

- `0` - 所有任务成功
- `n` - 失败任务数

**示例：**

```bash
parallel_wait_all
```

---

## 构建生命周期

### build_init

初始化构建。

```bash
build_init
```

**说明：**

- 记录开始时间
- 重置计数器
- 设置中断处理

**示例：**

```bash
build_init
# 执行构建
build_finalize
```

### build_cleanup

清理构建资源。

```bash
build_cleanup
```

**说明：**

- 清理并行进程
- 重置状态

**示例：**

```bash
build_cleanup
```

### build_interrupt

处理构建中断。

```bash
build_interrupt
```

**说明：**

- 设置中断标志
- 输出中断信息
- 清理资源
- 退出程序

### build_summary

输出构建摘要。

```bash
build_summary
```

**示例：**

```bash
build_summary
# 输出:
# ═════════════════════════════════════════════════════════════
# 构建摘要
# ═════════════════════════════════════════════════════════════
# 
#   ✓ 成功:  4
#   ✗ 失败:   0
#   ○ 跳过:  2
#   Σ 总计:    6
# 
#   持续时间: 5s
# 
# 构建成功完成。
```

### build_result

获取构建结果。

```bash
build_result
```

**返回值：**

- `0` - 构建成功
- `1` - 构建失败

**示例：**

```bash
build_finalize
result=$?
if [[ $result -eq 0 ]]; then
    echo "构建成功"
fi
```

### build_finalize

完成构建。

```bash
build_finalize
```

**说明：**

- 清理资源
- 输出摘要
- 返回结果

**示例：**

```bash
build_init
execute_target_with_deps "build"
build_finalize
```

---

## 工具函数

### compile_file

编译单个文件。

```bash
compile_file <src> <dest> [action]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| src | string | 是 | - | 源文件路径 |
| dest | string | 是 | - | 目标文件路径 |
| action | string | 否 | "编译中" | 操作描述 |

**返回值：**

- `0` - 成功
- `1` - 源文件不存在

**示例：**

```bash
if compile_file "src/Main.java" "output/Main.class"; then
    # 执行编译
fi
```

### file_needs_rebuild

检查文件是否需要重新构建。

```bash
file_needs_rebuild <src> <dest>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| src | string | 是 | 源文件路径 |
| dest | string | 是 | 目标文件路径 |

**返回值：**

- `0` - 需要重新构建
- `1` - 不需要重新构建

**示例：**

```bash
if file_needs_rebuild "$src" "$dest"; then
    # 重新编译
fi
```

### clean_target

清理目标。

```bash
clean_target <target> [dirs]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| target | string | 是 | - | 目标名称 |
| dirs | string | 否 | "build" | 要清理的目录（逗号分隔） |

**示例：**

```bash
clean_target "build" "output,cache"
```

### check_dependencies

检查命令依赖。

```bash
check_dependencies <commands...>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| commands | string... | 是 | 命令列表 |

**返回值：**

- `0` - 所有命令都存在
- `1` - 有命令缺失

**示例：**

```bash
if ! check_dependencies "javac" "jar"; then
    output_error "缺少必需工具"
    return 1
fi
```

### ensure_dependencies

确保依赖存在（自动安装）。

```bash
ensure_dependencies <commands...>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| commands | string... | 是 | 命令列表 |

**示例：**

```bash
ensure_dependencies "javac" "jar"
```

### run_hook

运行钩子函数。

```bash
run_hook <hook_name> [args...]
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| hook_name | string | 是 | 钩子名称 |
| args | any | 否 | 钩子参数 |

**返回值：**

- `0` - 钩子执行成功或不存在
- `1` - 钩子执行失败

**示例：**

```bash
run_hook "pre_build" "build"
```

---

## 使用示例

### 完整构建流程

```bash
#!/usr/bin/env bash

source "${LIB_DIR}/core.sh"

# 注册目标
register_target "build" "构建项目" "my_build"
register_target "test" "运行测试" "my_test"
register_target "clean" "清理" "my_clean"

register_target_deps "test" "build"

# 定义目标函数
my_build() {
    step_start "编译源码"
    
    local src_dir="${SOURCE_DIR:-src}"
    local build_dir="${BUILD_DIR:-output}"
    
    ensure_dir "$build_dir"
    
    # 编译逻辑...
    
    step_end
    return 0
}

my_test() {
    step_start "运行测试"
    
    # 测试逻辑...
    
    step_end
    return 0
}

my_clean() {
    rm -rf "${BUILD_DIR:-output}"
    return 0
}

# 执行构建
build_init
run_pre_build_hooks "build"

if execute_target_with_deps "test"; then
    run_post_build_hooks "test"
    build_finalize
else
    run_error_hooks "test"
    build_cleanup
    exit 1
fi
```

---

## 下一步

- [工具函数 API](utils-api.md) - 工具函数参考
- [输出模块 API](output-api.md) - 输出 API 参考
- [插件模块 API](plugin-api.md) - 插件 API 参考
