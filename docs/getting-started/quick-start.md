# 快速开始

本指南将帮助你在 5 分钟内创建第一个 build-tool 项目。

---

## 目录

- [前提条件](#前提条件)
- [创建项目](#创建项目)
- [项目结构](#项目结构)
- [运行构建](#运行构建)
- [下一步](#下一步)

---

## 前提条件

确保你已经完成以下步骤：

- [x] 安装 Bash 4.0 或更高版本
- [x] 安装 build-tool（参见 [安装指南](installation.md)）
- [x] （可选）安装 yq 以支持 YAML 配置

---

## 创建项目

### 步骤 1：创建项目目录

```bash
# 创建项目目录
mkdir my-first-project
cd my-first-project
```

### 步骤 2：创建配置文件

创建 `build.yaml` 文件：

```yaml
project:
  name: my-first-project
  version: 1.0.0
  description: 我的第一个 build-tool 项目

directories:
  source: src
  build: output

plugins:
  - java

java:
  jar_output: my-app.jar
  main_class: Main
  source: 17
  target: 17
```

### 步骤 3：创建源代码目录

```bash
mkdir -p src
```

### 步骤 4：创建示例代码

创建 `src/Main.java`：

```java
public class Main {
    public static void main(String[] args) {
        System.out.println("Hello, Build Tool!");
    }
}
```

---

## 项目结构

完成后的项目结构：

```
my-first-project/
├── build.yaml        # 项目配置文件
└── src/              # 源代码目录
    └── Main.java     # 示例 Java 文件
```

### 配置文件说明

| 配置项 | 值 | 说明 |
|--------|-----|------|
| `project.name` | my-first-project | 项目名称 |
| `project.version` | 1.0.0 | 项目版本 |
| `directories.source` | src | 源代码目录 |
| `directories.build` | output | 构建输出目录 |
| `plugins` | java | 使用的插件列表 |
| `java.main_class` | Main | 主类名称 |

---

## 运行构建

### 查看可用目标

```bash
build list
```

输出：

```
Available targets:
build - 编译 Java 源码
clean - 清理 Java 构建产物
jar - 创建 JAR 文件
run - 运行主类
test - 运行 Java 测试
```

### 构建项目

```bash
build build
```

输出：

```
╔══════════════════════════════════════════════════════╗
║ 构建目标: build                                       ║
╚══════════════════════════════════════════════════════╝

▶ 准备构建目录
────────────────────────────────────────────────────────────
✓ [1/3] 准备构建目录

▶ 扫描 Java 源码
────────────────────────────────────────────────────────────
ℹ 找到 1 个 Java 源码文件
✓ [2/3] 扫描 Java 源码

▶ 编译 Java 源码
────────────────────────────────────────────────────────────
    ✓ src/Main.java → output/classes/Main.class
████████████████████████████████████████ 100% (1/1)
✓ [3/3] 编译 Java 源码

✓ 成功编译 1 个 Java 文件
```

### 打包 JAR

```bash
build jar
```

输出：

```
╔══════════════════════════════════════════════════════╗
║ 构建目标: jar                                         ║
╚══════════════════════════════════════════════════════╝

▶ 创建 JAR 文件: my-app.jar
────────────────────────────────────────────────────────────
ℹ 已创建可执行 JAR 文件: output/my-app.jar
ℹ 主类: Main
ℹ 大小: 1.2KB
✓ JAR 创建完成
```

### 运行程序

```bash
build run
```

输出：

```
╔══════════════════════════════════════════════════════╗
║ 运行 Java 应用程序                                    ║
╚══════════════════════════════════════════════════════╝

ℹ 运行: java  -cp output/classes Main
Hello, Build Tool!
```

### 清理构建产物

```bash
build clean
```

输出：

```
╔══════════════════════════════════════════════════════╗
║ 清理 Java 构建                                       ║
╚══════════════════════════════════════════════════════╝

ℹ 删除 output
✓ 清理完成
```

---

## 详细输出模式

使用 `-v` 或 `--verbose` 选项查看详细输出：

```bash
build -v build
```

输出包含调试信息：

```
⚙ 加载项目配置
⚙ 项目: my-first-project v1.0.0
⚙ 已加载插件: java v1.0.0
⚙ 开始步骤: 准备构建目录
⚙ 步骤完成: 准备构建目录 (0s)
⚙ 开始步骤: 扫描 Java 源码
⚙ 找到 1 个 Java 源码文件
...
```

---

## 静默模式

使用 `-q` 或 `--quiet` 选项抑制输出：

```bash
build -q build
```

只输出错误信息，适合在 CI/CD 环境中使用。

---

## 查看配置

```bash
build config
```

输出：

```
╔══════════════════════════════════════════════════════╗
║ 构建工具配置                                          ║
╚══════════════════════════════════════════════════════╝

Project
  Config File:    /path/to/my-first-project/build.yaml
  项目:          my-first-project
  版本:          1.0.0
  项目目录:      /path/to/my-first-project

平台
  操作系统:      linux
  发行版:        ubuntu
  架构:          x86_64
  包管理器:      apt

构建设置
  详细输出:      false
  静默模式:      false
  彩色输出:      true
  并行作业:      true
  作业数:        4
  增量构建:      true

目录
  构建目录:      output
  源码目录:      src
  缓存目录:      /home/user/.cache/build-tool
```

---

## 检查环境

```bash
build check
```

检查系统环境和依赖是否满足要求。

---

## 下一步

恭喜！你已经成功创建了第一个 build-tool 项目。接下来可以：

1. **了解更多配置选项**
   
   阅读 [配置详解](../user-guide/configuration.md)

2. **学习目标系统**
   
   阅读 [目标系统](../user-guide/targets.md)

3. **探索插件系统**
   
   阅读 [插件系统](../user-guide/plugins.md)

4. **编写自定义插件**
   
   阅读 [编写插件](../advanced/writing-plugins.md)

5. **查看更多示例**
   
   阅读 [Java 项目示例](../examples/java-project.md)
