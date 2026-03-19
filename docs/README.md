# Build Tool

<div align="center">

**通用构建工具 - 简洁、灵活、跨平台**

一个用纯 Bash 编写的模块化构建系统，支持插件扩展、增量构建和跨平台运行。

[快速开始](#快速开始) · [文档](docs/getting-started/quick-start.md) · [API 参考](docs/api-reference/core-api.md)

</div>

---

## 特性

- **🔧 模块化架构** - 核心功能按模块拆分，职责清晰，易于扩展
- **🔌 插件系统** - 通过插件支持不同语言和构建场景
- **⚡ 增量构建** - 基于文件哈希的智能缓存，只重新构建变更的部分
- **🚀 并行构建** - 支持多任务并行执行，加速构建过程
- **🌍 跨平台** - 支持 Linux、macOS、Windows (WSL/Git Bash)
- **📦 包管理器集成** - 自动检测并使用系统包管理器
- **🌐 国际化** - 内置中英文双语支持
- **🎨 美观输出** - 彩色终端输出、进度条、表格等丰富 UI

---

## 快速开始

### 安装

```bash
# 克隆仓库
git clone https://github.com/your-repo/build-tool.git
cd build-tool

# 添加到 PATH（可选）
export PATH="$PWD:$PATH"
```

### 基本使用

```bash
# 查看帮助
./build help

# 构建项目
./build build

# 运行测试
./build test

# 清理构建产物
./build clean

# 查看配置
./build config
```

### 创建项目

1. 创建 `build.yaml` 配置文件：

```yaml
project:
  name: my-project
  version: 1.0.0

directories:
  source: src
  build: output

plugins:
  - java

targets:
  build: scripts/build.sh
  test: scripts/test.sh
```

2. 创建源码目录：

```bash
mkdir -p src
```

3. 运行构建：

```bash
./build build
```

---

## 系统要求

| 要求 | 说明 |
|------|------|
| Bash | 4.0 或更高版本（关联数组支持） |
| 基础工具 | cat, mkdir, rm, cp, mv |
| 可选依赖 | yq (YAML 配置), jq (JSON 处理) |

### 平台支持

| 平台 | 状态 | 说明 |
|------|------|------|
| Linux | ✅ 完全支持 | 所有发行版 |
| macOS | ✅ 完全支持 | 需要 Bash 4+ |
| Windows (WSL) | ✅ 完全支持 | 推荐方式 |
| Windows (Git Bash) | ⚠️ 部分支持 | 路径可能有问题 |
| BSD | ⚠️ 部分支持 | 需要测试 |

---

## 命令参考

### 基本命令

```bash
build <target>        # 执行指定构建目标
build list            # 列出所有可用目标
build clean           # 清理构建产物
build check           # 检查环境和依赖
build config          # 显示当前配置
build help            # 显示帮助信息
build version         # 显示版本信息
```

### 包管理命令

```bash
build install <packages...>   # 安装系统包
build update                  # 更新包列表
build search <query>          # 搜索包
```

### 插件命令

```bash
build plugin list                    # 列出所有插件
build plugin create <name>           # 创建新插件
build plugin validate <name>         # 验证插件
build plugin deps <name>             # 查看插件依赖
build plugin install-deps <name>     # 安装插件依赖
build plugin packages <name>         # 查看插件系统包
build plugin install-pkgs <name>     # 安装插件系统包
```

### 缓存命令

```bash
build cache stats      # 查看缓存统计
build cache clear      # 清空缓存
build cache enable     # 启用缓存
build cache disable    # 禁用缓存
build cache cleanup    # 清理过期缓存
```

### 选项

```bash
-v, --verbose         详细输出模式
-q, --quiet           静默模式
--no-color            禁用彩色输出
--no-unicode          禁用 Unicode 符号
-c, --config <file>   指定配置文件
-j, --jobs <n>        并行作业数
--no-cache            禁用构建缓存
--log-file <file>     日志输出文件
```

---

## 项目结构

```
build-tool/
├── build              # 主入口脚本
├── build.yaml         # 示例项目配置
├── config/
│   └── default.conf   # 默认配置
├── lib/
│   ├── cache.sh       # 缓存模块
│   ├── config.sh      # 配置管理
│   ├── core.sh        # 核心构建逻辑
│   ├── i18n.sh        # 国际化支持
│   ├── log.sh         # 日志模块
│   ├── output.sh      # 输出格式化
│   ├── platform.sh    # 平台检测
│   ├── plugin.sh      # 插件系统
│   ├── utils.sh       # 工具函数
│   └── yaml.sh        # YAML 解析
├── plugins/
│   └── java.sh        # Java 插件示例
├── scripts/
│   ├── build.sh       # 构建脚本
│   ├── dev.sh         # 开发脚本
│   └── release.sh     # 发布脚本
└── docs/              # 文档目录
```

---

## 配置

### YAML 配置 (build.yaml)

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

### INI 配置 (config/default.conf)

```ini
[build]
source_dir = "src"
build_dir = "build"
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

### 环境变量

所有配置项都可以通过环境变量覆盖，前缀为 `BUILD_`：

```bash
export BUILD_VERBOSE=true
export BUILD_JOBS=8
export BUILD_CACHE_DIR="/tmp/build-cache"
```

---

## 插件开发

### 创建插件

```bash
build plugin create my-plugin
```

### 插件模板

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
    
    local src_dir="${SOURCE_DIR:-src}"
    local build_dir="${BUILD_DIR:-output}"
    
    ensure_dir "$build_dir"
    
    step_end
    return 0
}

my_plugin_clean() {
    rm -rf "${BUILD_DIR:-output}"
    return 0
}
```

---

## 文档

- [安装指南](docs/getting-started/installation.md)
- [快速开始](docs/getting-started/quick-start.md)
- [配置详解](docs/user-guide/configuration.md)
- [目标系统](docs/user-guide/targets.md)
- [插件系统](docs/user-guide/plugins.md)
- [缓存管理](docs/user-guide/cache.md)
- [钩子系统](docs/user-guide/hooks.md)
- [编写插件](docs/advanced/writing-plugins.md)
- [跨平台支持](docs/advanced/cross-platform.md)
- [最佳实践](docs/advanced/best-practices.md)

### API 参考

- [核心 API](docs/api-reference/core-api.md)
- [工具函数 API](docs/api-reference/utils-api.md)
- [输出模块 API](docs/api-reference/output-api.md)
- [日志模块 API](docs/api-reference/log-api.md)
- [配置模块 API](docs/api-reference/config-api.md)
- [缓存模块 API](docs/api-reference/cache-api.md)
- [插件模块 API](docs/api-reference/plugin-api.md)
- [平台模块 API](docs/api-reference/platform-api.md)
- [YAML 模块 API](docs/api-reference/yaml-api.md)
- [国际化 API](docs/api-reference/i18n-api.md)

---

## 示例

查看 [examples](docs/examples/) 目录获取更多示例：

- [Java 项目示例](docs/examples/java-project.md)
- [自定义目标示例](docs/examples/custom-targets.md)

---

## 内部原理

- [架构设计](docs/internals/architecture.md)

---

## 故障排除

- [常见问题](docs/troubleshooting/common-issues.md)

---

## 贡献

欢迎贡献代码、报告问题或提出建议！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

---

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

---

<div align="center">

**Build Tool** - 让构建变得简单

</div>
