# 配置详解

本文档详细介绍 build-tool 的配置系统，包括配置文件格式、配置项说明和配置优先级。

---

## 目录

- [配置文件格式](#配置文件格式)
- [配置文件位置](#配置文件位置)
- [配置项完整列表](#配置项完整列表)
- [配置优先级](#配置优先级)
- [环境变量](#环境变量)
- [配置模板语法](#配置模板语法)
- [配置 API](#配置-api)

---

## 配置文件格式

build-tool 支持多种配置文件格式：

### YAML 格式 (推荐)

文件名：`build.yaml` 或 `build.yml`

```yaml
project:
  name: my-project
  version: 1.0.0
  description: 项目描述

directories:
  source: src
  build: output
  resources: resources

plugins:
  - java
  - custom

java:
  jar_output: app-${project.version}.jar
  main_class: Main
  source: 17
  target: 17
  opts: -Xlint:all
  run_opts: -Xmx256m

targets:
  build: scripts/build.sh
  test: scripts/test.sh
  release: scripts/release.sh

hooks:
  pre_build: scripts/hooks/pre_build.sh
  post_build: scripts/hooks/post_build.sh
```

### INI 格式

文件名：`build.conf` 或 `.build`

```ini
[build]
source_dir = "src"
build_dir = "output"
parallel = true
jobs = 4
incremental = true

[output]
verbose = false
quiet = false
color = true
unicode = true
timestamp = false

[log]
level = "INFO"
file = ""
max_size = 10485760
max_files = 5

[cache]
enabled = true
max_size = 1073741824
max_age = 604800
hash_algorithm = "md5"

[plugin]
auto_load = true
dirs = "plugins,~/.build-tool/plugins"
```

### Shell 格式

文件名：`build.sh`

```bash
#!/usr/bin/env bash

PROJECT_NAME="my-project"
PROJECT_VERSION="1.0.0"
SOURCE_DIR="src"
BUILD_DIR="output"

# 自定义构建函数
my_build() {
    echo "Building..."
}

# 注册目标
register_target "build" "构建项目" "my_build"
```

---

## 配置文件位置

build-tool 按以下顺序查找配置文件：

### 项目配置文件

1. `./build.yaml`
2. `./build.yml`
3. `./build.sh`
4. `./build.conf`
5. `./.build`

### 全局配置文件

1. `./config/default.conf`
2. `~/.build-tool/config.conf`
3. `/etc/build-tool/config.conf`

### 环境文件

1. `./.env`

---

## 配置项完整列表

### 项目配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `project.name` | string | 目录名 | 项目名称 |
| `project.version` | string | 1.0.0 | 项目版本 |
| `project.description` | string | - | 项目描述 |

### 目录配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `directories.source` | string | src | 源代码目录 |
| `directories.build` | string | output | 构建输出目录 |
| `directories.resources` | string | resources | 资源文件目录 |

### 构建配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `BUILD.SOURCE_DIR` | string | src | 源代码目录 |
| `BUILD.BUILD_DIR` | string | output | 构建输出目录 |
| `BUILD.PARALLEL` | boolean | true | 启用并行构建 |
| `BUILD.JOBS` | integer | 4 | 并行作业数 |
| `BUILD.INCREMENTAL` | boolean | true | 启用增量构建 |

### 输出配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `OUTPUT.VERBOSE` | boolean | false | 详细输出模式 |
| `OUTPUT.QUIET` | boolean | false | 静默模式 |
| `OUTPUT.COLOR` | boolean | true | 彩色输出 |
| `OUTPUT.UNICODE` | boolean | true | Unicode 符号 |
| `OUTPUT.TIMESTAMP` | boolean | false | 显示时间戳 |

### 日志配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `LOG.LEVEL` | string | INFO | 日志级别 (DEBUG/INFO/WARN/ERROR/NONE) |
| `LOG.FILE` | string | - | 日志文件路径 |
| `LOG.MAX_SIZE` | integer | 10485760 | 日志文件最大大小（字节） |
| `LOG.MAX_FILES` | integer | 5 | 保留的日志文件数量 |

### 缓存配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `CACHE.ENABLED` | boolean | true | 启用缓存 |
| `CACHE.MAX_SIZE` | integer | 1073741824 | 缓存最大大小（字节，默认 1GB） |
| `CACHE.MAX_AGE` | integer | 604800 | 缓存最大有效期（秒，默认 7 天） |
| `CACHE.HASH_ALGORITHM` | string | md5 | 哈希算法 (md5/sha1/sha256) |

### 插件配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `PLUGIN.AUTO_LOAD` | boolean | true | 自动加载插件 |
| `PLUGIN.DIRS` | string | plugins,~/.build-tool/plugins | 插件搜索目录 |

---

## 配置优先级

配置按以下优先级从高到低加载：

```
命令行参数 > 环境变量 > 项目配置文件 > 全局配置文件 > 默认值
```

### 示例

假设有以下配置：

1. **默认值**：`JOBS = 4`
2. **全局配置** (`~/.build-tool/config.conf`)：`JOBS = 2`
3. **项目配置** (`build.yaml`)：`jobs: 8`
4. **环境变量**：`BUILD_JOBS=16`
5. **命令行参数**：`--jobs 32`

最终生效的值是 **32**（命令行参数优先级最高）。

---

## 环境变量

所有配置项都可以通过环境变量覆盖。环境变量命名规则：

- 前缀：`BUILD_`
- 格式：`BUILD_<配置项大写>`

### 示例

```bash
# 设置详细输出
export BUILD_VERBOSE=true

# 设置并行作业数
export BUILD_JOBS=8

# 设置构建目录
export BUILD_BUILD_DIR=/tmp/build

# 设置日志级别
export BUILD_LOG_LEVEL=DEBUG

# 设置缓存目录
export BUILD_CACHE_DIR=/tmp/cache
```

### 在 .env 文件中配置

创建 `.env` 文件：

```bash
BUILD_VERBOSE=true
BUILD_JOBS=8
BUILD_LOG_FILE=build.log
```

---

## 配置模板语法

在配置文件中可以使用变量引用：

### 语法格式

```yaml
# ${变量名}
jar_output: app-${project.version}.jar
```

### 可用变量

| 变量 | 说明 |
|------|------|
| `${project.name}` | 项目名称 |
| `${project.version}` | 项目版本 |
| `${directories.source}` | 源码目录 |
| `${directories.build}` | 构建目录 |

### 示例

```yaml
project:
  name: my-app
  version: 2.0.0

directories:
  source: src
  build: dist

java:
  # 输出: my-app-2.0.0.jar
  jar_output: ${project.name}-${project.version}.jar
```

---

## 配置 API

在插件和脚本中可以使用配置 API：

### 读取配置

```bash
# 获取配置值
value=$(config_get "VERBOSE")

# 获取配置值（带默认值）
value=$(config_get "JOBS" "4")

# 获取布尔值
if config_get_bool "VERBOSE"; then
    echo "详细模式已启用"
fi

# 获取整数值
jobs=$(config_get_int "JOBS" "4")

# 获取数组
config_get_array "PLUGINS" "," plugins_array
```

### 设置配置

```bash
# 设置配置值
config_set "VERBOSE" "true"

# 设置数组
config_set_array "PLUGINS" "," "java" "python" "node"
```

### 检查配置

```bash
# 检查配置是否存在
if config_has "PROJECT_NAME"; then
    echo "项目名称已设置"
fi

# 验证必需配置
if ! config_validate "PROJECT_NAME" "PROJECT_VERSION"; then
    echo "缺少必需配置"
    exit 1
fi
```

### 列出配置

```bash
# 列出所有配置
config_list

# 列出指定前缀的配置
config_list "BUILD"

# 列出默认值
config_list_defaults
```

### 配置模板处理

```bash
# 处理配置模板
template='${project.name}-${project.version}'
result=$(config_template "$template")
echo "$result"  # 输出: my-project-1.0.0
```

---

## 命令行选项

配置可以通过命令行选项覆盖：

### 基本选项

```bash
# 详细输出
build -v build
build --verbose build

# 静默模式
build -q build
build --quiet build

# 禁用彩色输出
build --no-color build

# 禁用 Unicode 符号
build --no-unicode build
```

### 构建选项

```bash
# 指定配置文件
build -c custom.yaml build
build --config custom.yaml build

# 设置并行作业数
build -j 8 build
build --jobs 8 build

# 禁用缓存
build --no-cache build

# 指定日志文件
build --log-file build.log build
```

### 使用 -- 传递参数

```bash
# 传递自定义参数
build build -- --my-option value
```

---

## 配置示例

### Java 项目配置

```yaml
project:
  name: my-java-app
  version: 1.0.0

directories:
  source: src/main/java
  build: target/classes
  resources: src/main/resources

plugins:
  - java

java:
  jar_output: ${project.name}-${project.version}.jar
  main_class: com.example.Main
  source: 17
  target: 17
  opts: -Xlint:all -Werror
  run_opts: -Xmx512m -Dspring.profiles.active=dev

targets:
  build: scripts/build.sh
  test: scripts/test.sh
  package: scripts/package.sh

hooks:
  pre_build: scripts/hooks/pre_build.sh
  post_build: scripts/hooks/post_build.sh
```

### 多模块项目配置

```yaml
project:
  name: multi-module-project
  version: 1.0.0

directories:
  source: modules
  build: dist

plugins:
  - java
  - node
  - python

targets:
  build-all: scripts/build-all.sh
  test-all: scripts/test-all.sh
  package: scripts/package.sh
```

### CI/CD 环境配置

```bash
# .env.ci
BUILD_VERBOSE=true
BUILD_QUIET=false
BUILD_JOBS=4
BUILD_INCREMENTAL=false
BUILD_LOG_FILE=ci-build.log
BUILD_CACHE_DIR=/tmp/build-cache
```

---

## 下一步

- [目标系统](targets.md) - 了解构建目标
- [插件系统](plugins.md) - 了解插件配置
- [缓存管理](cache.md) - 了解缓存配置
- [配置模块 API](../api-reference/config-api.md) - 配置 API 参考
