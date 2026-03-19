# 目标系统

本文档详细介绍 build-tool 的目标（Target）系统，包括目标概念、依赖关系、执行顺序和自定义目标。

---

## 目录

- [目标概念](#目标概念)
- [内置目标](#内置目标)
- [目标依赖](#目标依赖)
- [执行顺序](#执行顺序)
- [自定义目标](#自定义目标)
- [目标 API](#目标-api)

---

## 目标概念

**目标（Target）** 是 build-tool 的核心概念，代表一个可执行的构建任务。每个目标都有：

- **名称**：目标的唯一标识符
- **描述**：目标的说明文字
- **实现函数**：执行目标逻辑的函数
- **依赖**：执行前需要先完成的其他目标

### 目标类型

| 类型 | 来源 | 说明 |
|------|------|------|
| **内置目标** | 核心系统 | clean, list, check, config 等 |
| **插件目标** | 插件定义 | 由插件注册，如 java 的 build, jar, run |
| **自定义目标** | 项目配置 | 在 build.yaml 中定义 |

---

## 内置目标

### 系统命令

| 命令 | 说明 |
|------|------|
| `list` / `targets` | 列出所有可用目标 |
| `clean` | 清理构建产物 |
| `check` | 检查环境和依赖 |
| `config` | 显示当前配置 |
| `help` | 显示帮助信息 |
| `version` | 显示版本信息 |

### 包管理命令

| 命令 | 说明 |
|------|------|
| `install <packages>` | 安装系统包 |
| `update` | 更新包列表 |
| `search <query>` | 搜索包 |

### 插件命令

| 命令 | 说明 |
|------|------|
| `plugin list` | 列出所有插件 |
| `plugin create <name>` | 创建新插件 |
| `plugin validate <name>` | 验证插件 |
| `plugin deps <name>` | 查看插件依赖 |
| `plugin install-deps <name>` | 安装插件依赖 |

### 缓存命令

| 命令 | 说明 |
|------|------|
| `cache stats` | 查看缓存统计 |
| `cache clear` | 清空缓存 |
| `cache enable` | 启用缓存 |
| `cache disable` | 禁用缓存 |
| `cache cleanup` | 清理过期缓存 |

---

## 目标依赖

目标可以声明依赖关系，build-tool 会自动按正确顺序执行。

### 依赖声明

在插件中声明依赖：

```bash
# 注册目标时声明依赖
register_target "jar" "创建 JAR 文件" "java_jar"
register_target_deps "jar" "build"

# 多个依赖
register_target_deps "release" "build,test,package"
```

在 YAML 配置中声明：

```yaml
targets:
  build:
    script: scripts/build.sh
    deps: []
  
  test:
    script: scripts/test.sh
    deps: [build]
  
  package:
    script: scripts/package.sh
    deps: [build, test]
  
  release:
    script: scripts/release.sh
    deps: [package]
```

### 依赖图示例

```
                    ┌─────────┐
                    │ release │
                    └────┬────┘
                         │
                    ┌────┴────┐
                    │ package │
                    └────┬────┘
                         │
              ┌──────────┴──────────┐
              │                     │
         ┌────┴────┐           ┌────┴────┐
         │   test  │           │  build  │
         └─────────┘           └─────────┘
```

执行 `build release` 时，会按顺序执行：`build → test → package → release`

---

## 执行顺序

### 拓扑排序

build-tool 使用拓扑排序算法确定目标执行顺序：

1. 解析所有目标的依赖关系
2. 检测循环依赖（如果存在则报错）
3. 按依赖关系排序目标
4. 按顺序执行目标

### 执行流程

```
┌─────────────────────────────────────────────────────────────┐
│                      用户执行命令                             │
│                   build release                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    解析目标依赖                               │
│              release → package → test, build                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    拓扑排序                                  │
│            [build, test, package, release]                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    执行 pre_build 钩子                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    执行目标                                  │
│  ┌─────────┐   ┌─────────┐   ┌──────────┐   ┌─────────┐    │
│  │  build  │ → │  test   │ → │ package  │ → │ release │    │
│  └─────────┘   └─────────┘   └──────────┘   └─────────┘    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    执行 post_build 钩子                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    输出构建摘要                               │
│              ✓ 成功: 4  ✗ 失败: 0  ○ 跳过: 0                 │
└─────────────────────────────────────────────────────────────┘
```

### 循环依赖检测

如果存在循环依赖，build-tool 会检测并报错：

```
✗ 检测到循环依赖
目标 A 依赖 B，B 依赖 C，C 依赖 A
```

---

## 自定义目标

### 在 YAML 中定义

```yaml
targets:
  build:
    script: scripts/build.sh
    description: 构建项目
    deps: []
  
  test:
    script: scripts/test.sh
    description: 运行测试
    deps: [build]
  
  lint:
    script: scripts/lint.sh
    description: 代码检查
    deps: []
  
  package:
    script: scripts/package.sh
    description: 打包
    deps: [build, test]
  
  release:
    script: scripts/release.sh
    description: 发布
    deps: [package]
```

### 在 Shell 脚本中定义

创建 `build.sh`：

```bash
#!/usr/bin/env bash

PROJECT_NAME="my-project"
PROJECT_VERSION="1.0.0"
SOURCE_DIR="src"
BUILD_DIR="output"

# 定义构建函数
my_build() {
    step_start "构建项目"
    
    ensure_dir "$BUILD_DIR"
    
    # 构建逻辑
    echo "Building $PROJECT_NAME..."
    
    step_end
    return 0
}

my_clean() {
    output_info "清理构建产物..."
    rm -rf "$BUILD_DIR"
    return 0
}

my_test() {
    step_start "运行测试"
    
    # 测试逻辑
    echo "Running tests..."
    
    step_end
    return 0
}

# 注册目标
register_target "build" "构建项目" "my_build"
register_target "clean" "清理构建产物" "my_clean"
register_target "test" "运行测试" "my_test"

# 注册依赖
register_target_deps "test" "build"
```

### 目标脚本示例

`scripts/build.sh`：

```bash
#!/usr/bin/env bash

step_start "编译源码"

local src_dir="${SOURCE_DIR:-src}"
local build_dir="${BUILD_DIR:-output}"

ensure_dir "$build_dir"

# 查找源文件
local -a sources=()
while IFS= read -r -d '' file; do
    sources+=("$file")
done < <(find "$src_dir" -name "*.java" -print0 2>/dev/null)

local total=${#sources[@]}
output_info "找到 $total 个源文件"

# 编译
for src in "${sources[@]}"; do
    output_file_status "$src" "$build_dir" "processing"
    # 编译逻辑...
done

step_end
return 0
```

---

## 目标 API

### 注册目标

```bash
# 基本注册
register_target "name" "description" "function_name"

# 完整注册
register_target "name" "description" "function_name" "plugin_name"
```

**参数说明：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| name | string | 是 | 目标名称 |
| description | string | 否 | 目标描述 |
| function_name | string | 否 | 实现函数名（默认为 `name_build`） |
| plugin_name | string | 否 | 所属插件名（默认为 core） |

### 注册依赖

```bash
# 单个依赖
register_target_deps "target" "dependency"

# 多个依赖（逗号分隔）
register_target_deps "target" "dep1,dep2,dep3"
```

### 检查目标

```bash
# 检查目标是否存在
if target_exists "build"; then
    echo "build 目标存在"
fi

# 获取目标描述
desc=$(get_target_desc "build")

# 获取目标依赖
deps=$(get_target_deps "build")

# 获取目标函数
func=$(get_target_func "build")
```

### 执行目标

```bash
# 执行单个目标
execute_target "build"

# 执行目标及其依赖
execute_target_with_deps "release"
```

### 列出目标

```bash
# 列出所有目标（简洁格式）
list_targets "false"

# 列出所有目标（详细格式）
list_targets "true"
```

### 获取构建顺序

```bash
# 获取目标的执行顺序
order=$(get_build_order "release")
echo "$order"  # 输出: build test package release
```

---

## 目标执行状态

在执行过程中，目标可能有以下状态：

| 状态 | 图标 | 说明 |
|------|------|------|
| running | ◐ | 正在执行 |
| success | ✓ | 执行成功 |
| error | ✗ | 执行失败 |
| skipped | ○ | 已跳过（之前已执行） |

### 跳过已执行目标

如果目标已经执行过，不会重复执行：

```bash
# 第一次执行
build build    # 执行 build 目标

# 再次执行
build build    # 跳过（已执行）

# 执行依赖目标
build test     # 只执行 test（build 已跳过）
```

---

## 目标与钩子

目标执行前后会触发相应的钩子：

```bash
# 执行 build 目标时的钩子顺序
pre_build_hook     # 构建前
  └── build 目标执行
post_build_hook    # 构建后（成功）
on_error_hook      # 构建后（失败）
```

详见 [钩子系统](hooks.md)。

---

## 最佳实践

### 1. 目标命名规范

```bash
# 推荐：使用动词
build, test, clean, package, deploy, run

# 不推荐：使用名词
builder, tester, cleaner
```

### 2. 合理设置依赖

```bash
# 推荐：最小化依赖
register_target_deps "jar" "build"

# 不推荐：过度依赖
register_target_deps "jar" "build,test,lint,validate"
```

### 3. 目标职责单一

```bash
# 推荐：每个目标做一件事
register_target "compile" "编译源码" "compile_src"
register_target "test" "运行测试" "run_tests"
register_target "package" "打包" "create_package"

# 不推荐：一个目标做多件事
register_target "all" "编译、测试、打包" "do_all"
```

### 4. 使用步骤 API

```bash
my_build() {
    step_start "准备构建目录"
    ensure_dir "$BUILD_DIR"
    step_end
    
    step_start "编译源码"
    # 编译逻辑
    step_end
    
    step_start "复制资源"
    # 复制逻辑
    step_end
    
    return 0
}
```

---

## 下一步

- [插件系统](plugins.md) - 了解插件如何注册目标
- [钩子系统](hooks.md) - 了解目标执行前后的钩子
- [核心 API](../api-reference/core-api.md) - 目标 API 参考
