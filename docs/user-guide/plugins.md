# 插件系统

本文档详细介绍 build-tool 的插件系统，包括插件概念、发现机制、加载顺序和插件命令。

---

## 目录

- [插件概念](#插件概念)
- [插件发现机制](#插件发现机制)
- [插件加载顺序](#插件加载顺序)
- [内置插件](#内置插件)
- [插件命令](#插件命令)
- [插件元数据](#插件元数据)
- [插件依赖管理](#插件依赖管理)
- [插件 API](#插件-api)

---

## 插件概念

**插件（Plugin）** 是 build-tool 的扩展机制，用于支持不同的编程语言和构建场景。每个插件可以：

- 注册构建目标（如 `build`, `test`, `run`）
- 声明命令依赖（如 `javac`, `jar`）
- 声明系统包依赖（如 `openjdk-17-jdk`）
- 注册构建钩子（如 `pre_build`, `post_build`）
- 提供国际化支持

### 插件结构

```
plugins/
├── java.sh           # Java 插件
├── python.sh         # Python 插件
├── node.sh           # Node.js 插件
├── go.sh             # Go 插件
└── custom.sh         # 自定义插件
```

---

## 插件发现机制

build-tool 会自动在以下目录搜索插件：

### 搜索目录

| 优先级 | 目录 | 说明 |
|--------|------|------|
| 1 | `./plugins/` | 项目插件目录 |
| 2 | `./.build/plugins/` | 项目隐藏插件目录 |
| 3 | `$PROJECT_DIR/plugins/` | 项目目录下的插件 |
| 4 | `~/.build-tool/plugins/` | 用户全局插件目录 |
| 5 | `$SCRIPT_DIR/plugins/` | build-tool 内置插件目录 |

### 插件文件命名

插件文件支持以下命名格式：

- `<name>.sh` - 标准格式
- `<name>.plugin.sh` - 显式插件格式
- `<name>.bash` - Bash 脚本格式

### 发现过程

```
┌─────────────────────────────────────────────────────────────┐
│                    插件发现流程                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  遍历所有插件目录                                            │
│  ./plugins/, ~/.build-tool/plugins/, ...                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  匹配插件文件                                                │
│  *.sh, *.plugin.sh, *.bash                                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  提取插件名称                                                │
│  java.sh → java                                             │
│  python.plugin.sh → python                                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  注册到插件列表                                              │
│  PLUGINS["java"] = "/path/to/java.sh"                       │
└─────────────────────────────────────────────────────────────┘
```

---

## 插件加载顺序

### 自动加载

build-tool 在启动时会自动加载所有发现的插件：

```bash
# 初始化插件系统
plugin_init

# 发现插件
plugin_discover

# 加载所有插件
plugin_load_all
```

### 手动加载

在配置文件中指定要加载的插件：

```yaml
plugins:
  - java
  - python
  - custom
```

### 加载优先级

同名插件的加载优先级（高优先级覆盖低优先级）：

1. 项目插件目录 (`./plugins/`)
2. 项目隐藏插件目录 (`./.build/plugins/`)
3. 用户全局插件目录 (`~/.build-tool/plugins/`)
4. 内置插件目录 (`$SCRIPT_DIR/plugins/`)

---

## 内置插件

### Java 插件

```bash
PLUGIN_NAME="java"
PLUGIN_VERSION="1.0.0"
PLUGIN_DESCRIPTION="Java compilation plugin"
PLUGIN_DEPENDENCIES="javac,jar"
PLUGIN_PACKAGES_STR="openjdk-11-jdk,openjdk-17-jdk"
```

**提供的目标：**

| 目标 | 说明 | 依赖 |
|------|------|------|
| `build` | 编译 Java 源码 | - |
| `clean` | 清理构建产物 | - |
| `test` | 运行测试 | build |
| `jar` | 创建 JAR 文件 | build |
| `run` | 运行主类 | build |

**配置选项：**

| 配置项 | 说明 |
|--------|------|
| `JAR_OUTPUT` | JAR 输出文件名 |
| `MAIN_CLASS` | 主类名称 |
| `JAVA_SOURCE` | Java 源码版本 |
| `JAVA_TARGET` | Java 目标版本 |
| `JAVA_OPTS` | 编译选项 |
| `JAVA_RUN_OPTS` | 运行选项 |

---

## 插件命令

### 列出插件

```bash
build plugin list
build plugin ls
```

输出：

```
╔══════════════════════════════════════════════════════╗
║ 插件                                                  ║
╚══════════════════════════════════════════════════════╝

java            v1.0.0
  • Java compilation plugin
  • 依赖: javac, jar
  • 系统包: openjdk-11-jdk, openjdk-17-jdk
```

### 创建插件

```bash
build plugin create <name> [directory]
```

示例：

```bash
# 在 plugins/ 目录创建插件
build plugin create my-plugin

# 在指定目录创建插件
build plugin create my-plugin custom-plugins
```

创建的插件模板：

```bash
#!/usr/bin/env bash

PLUGIN_NAME="my-plugin"
PLUGIN_VERSION="1.0.0"
PLUGIN_DESCRIPTION="Plugin description"
PLUGIN_DEPENDENCIES=""
PLUGIN_PACKAGES_STR=""

register_target "build" "Build the project" "my_plugin_build"
register_target "clean" "Clean build artifacts" "my_plugin_clean"

pre_build_hook() {
    log_info "Preparing to build..."
}

post_build_hook() {
    log_info "Build completed!"
}

my_plugin_build() {
    step_start "Building..."
    
    output_info "Building..."
    
    step_end
    return 0
}

my_plugin_clean() {
    output_info "Cleaning..."
    rm -rf build/
    return 0
}
```

### 验证插件

```bash
# 验证所有插件
build plugin validate

# 验证指定插件
build plugin validate java
```

输出：

```
✓ 插件 java 有效
```

### 查看插件依赖

```bash
# 查看所有插件依赖
build plugin deps

# 查看指定插件依赖
build plugin deps java
```

输出：

```
java: javac, jar
```

### 安装插件依赖

```bash
# 安装所有插件的命令依赖
build plugin install-deps

# 安装指定插件的命令依赖
build plugin install-deps java
```

### 查看插件系统包

```bash
# 查看所有插件的系统包
build plugin packages

# 查看指定插件的系统包
build plugin packages java
```

输出：

```
java: openjdk-11-jdk, openjdk-17-jdk
```

### 安装插件系统包

```bash
# 安装所有插件的系统包
build plugin install-pkgs

# 安装指定插件的系统包
build plugin install-pkgs java
```

---

## 插件元数据

每个插件必须声明以下元数据：

```bash
PLUGIN_NAME="plugin-name"           # 插件名称（必需）
PLUGIN_VERSION="1.0.0"              # 插件版本（可选，默认 1.0.0）
PLUGIN_DESCRIPTION="Description"    # 插件描述（可选）
PLUGIN_DEPENDENCIES="cmd1,cmd2"     # 命令依赖（可选）
PLUGIN_PACKAGES_STR="pkg1,pkg2"     # 系统包依赖（可选）
```

### 元数据说明

| 元数据 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `PLUGIN_NAME` | string | 是 | 插件唯一标识符 |
| `PLUGIN_VERSION` | string | 否 | 版本号，遵循语义化版本 |
| `PLUGIN_DESCRIPTION` | string | 否 | 插件功能描述 |
| `PLUGIN_DEPENDENCIES` | string | 否 | 依赖的命令，逗号分隔 |
| `PLUGIN_PACKAGES_STR` | string | 否 | 依赖的系统包，逗号分隔 |

---

## 插件依赖管理

### 命令依赖

声明插件需要的命令工具：

```bash
PLUGIN_DEPENDENCIES="javac,jar,gradle"
```

检查依赖：

```bash
# 检查插件依赖是否满足
plugin_check_dependencies "java"

# 安装缺失的依赖
plugin_install_dependencies "java"
```

### 系统包依赖

声明插件需要的系统包：

```bash
PLUGIN_PACKAGES_STR="openjdk-17-jdk,maven"
```

安装系统包：

```bash
# 查看插件系统包
plugin_get_packages "java"

# 检查插件是否有系统包
plugin_has_packages "java"

# 安装插件系统包
plugin_install_packages "java"

# 安装所有插件的系统包
plugin_install_all_packages
```

---

## 插件 API

### 插件管理

```bash
# 添加插件搜索目录
plugin_add_dir "/path/to/plugins"

# 发现插件
plugin_discover

# 加载插件
plugin_load "java"

# 强制重新加载插件
plugin_reload "java"

# 卸载插件
plugin_unload "java"

# 检查插件是否已加载
plugin_is_loaded "java"
```

### 插件信息

```bash
# 获取插件版本
version=$(plugin_get_version "java")

# 获取插件描述
desc=$(plugin_get_description "java")

# 获取插件依赖
deps=$(plugin_get_dependencies "java")

# 获取插件系统包
pkgs=$(plugin_get_packages "java")

# 检查插件是否有系统包
if plugin_has_packages "java"; then
    echo "Java 插件需要安装系统包"
fi
```

### 插件列表

```bash
# 列出插件（简洁格式）
plugin_list "false"

# 列出插件（详细格式）
plugin_list "true"
```

### 手动加载插件

```bash
# 从指定路径加载插件
source_plugin "java"

# 从绝对路径加载插件
source_plugin "/path/to/custom-plugin.sh"
```

---

## 插件与目标

插件通过 `register_target` 注册构建目标：

```bash
# 注册目标
register_target "build" "编译源码" "java_build"
register_target "test" "运行测试" "java_test"
register_target "jar" "创建 JAR" "java_jar"
register_target "run" "运行程序" "java_run"
register_target "clean" "清理产物" "java_clean"

# 注册依赖
register_target_deps "jar" "build"
register_target_deps "test" "build"
register_target_deps "run" "build"
```

详见 [目标系统](targets.md)。

---

## 插件与钩子

插件可以注册构建钩子：

```bash
# 注册钩子
register_hook "pre_build" "java" "java_pre_build"
register_hook "post_build" "java" "java_post_build"
register_hook "on_error" "java" "java_on_error"

# 钩子函数
java_pre_build() {
    log_info "准备 Java 构建..."
}

java_post_build() {
    log_info "Java 构建完成!"
}

java_on_error() {
    log_error "Java 构建失败!"
}
```

详见 [钩子系统](hooks.md)。

---

## 插件国际化

插件可以提供自己的国际化支持：

```bash
# 定义国际化字符串
declare -gA PLUGIN_I18N_EN=()
declare -gA PLUGIN_I18N_ZH=()
declare -g PLUGIN_I18N_LANG="zh"

_plugin_init_i18n() {
    PLUGIN_I18N_EN=(
        ["build"]="Build project"
        ["clean"]="Clean artifacts"
    )
    
    PLUGIN_I18N_ZH=(
        ["build"]="构建项目"
        ["clean"]="清理构建产物"
    )
}

plugin_i18n_get() {
    local key="$1"
    if [[ "$PLUGIN_I18N_LANG" == "zh" ]]; then
        echo "${PLUGIN_I18N_ZH[$key]:-$key}"
    else
        echo "${PLUGIN_I18N_EN[$key]:-$key}"
    fi
}
```

---

## 最佳实践

### 1. 插件命名

```bash
# 推荐：使用语言或工具名称
java.sh, python.sh, node.sh, go.sh

# 不推荐：使用通用名称
build.sh, compile.sh, run.sh
```

### 2. 目标命名

```bash
# 推荐：使用插件名前缀
register_target "build" "..." "java_build"
register_target "clean" "..." "java_clean"

# 不推荐：使用通用函数名
register_target "build" "..." "build"  # 可能冲突
```

### 3. 依赖声明

```bash
# 推荐：明确声明所有依赖
PLUGIN_DEPENDENCIES="javac,jar,gradle"

# 不推荐：省略依赖
PLUGIN_DEPENDENCIES=""  # 用户不知道需要什么
```

### 4. 错误处理

```bash
my_plugin_build() {
    step_start "构建中..."
    
    # 检查依赖
    if ! check_dependencies "javac" "jar"; then
        step_end "false"
        return 1
    fi
    
    # 构建逻辑
    if ! javac ...; then
        output_error "编译失败"
        step_end "false"
        return 1
    fi
    
    step_end
    return 0
}
```

---

## 下一步

- [编写插件](../advanced/writing-plugins.md) - 学习如何编写自定义插件
- [钩子系统](hooks.md) - 了解插件钩子
- [目标系统](targets.md) - 了解目标注册
- [插件模块 API](../api-reference/plugin-api.md) - 插件 API 参考
