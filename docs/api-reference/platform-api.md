# 平台模块 API 参考

本文档详细介绍 `lib/platform.sh` 模块提供的平台检测 API。

---

## 目录

- [模块概述](#模块概述)
- [全局变量](#全局变量)
- [平台检测](#平台检测)
- [包管理器](#包管理器)
- [权限检测](#权限检测)

---

## 模块概述

`platform.sh` 提供平台检测功能：

- 操作系统检测
- 发行版检测
- 架构检测
- 包管理器检测
- 权限检测

---

## 全局变量

```bash
declare -g PLATFORM_OS=""             # 操作系统 (linux/darwin/windows)
declare -g PLATFORM_DISTRO=""         # 发行版 (ubuntu/fedora/arch...)
declare -g PLATFORM_ARCH=""           # 架构 (x86_64/arm64...)
declare -g PLATFORM_PACKAGE_MANAGER="" # 包管理器 (apt/dnf/pacman...)
declare -g PLATFORM_IS_ROOT=false     # 是否为 root 用户
declare -g PLATFORM_HAS_SUDO=false    # 是否有 sudo 权限
```

---

## 平台检测

### platform_detect

检测平台信息。

```bash
platform_detect
```

**示例：**

```bash
platform_detect
```

### platform_is_linux

检查是否为 Linux。

```bash
platform_is_linux
```

**返回值：**

- `0` - 是 Linux
- `1` - 不是 Linux

**示例：**

```bash
if platform_is_linux; then
    echo "运行在 Linux 上"
fi
```

### platform_is_macos

检查是否为 macOS。

```bash
platform_is_macos
```

**返回值：**

- `0` - 是 macOS
- `1` - 不是 macOS

**示例：**

```bash
if platform_is_macos; then
    echo "运行在 macOS 上"
fi
```

### platform_is_windows

检查是否为 Windows。

```bash
platform_is_windows
```

**返回值：**

- `0` - 是 Windows
- `1` - 不是 Windows

**示例：**

```bash
if platform_is_windows; then
    echo "运行在 Windows 上"
fi
```

### platform_is_debian

检查是否为 Debian 系发行版。

```bash
platform_is_debian
```

**返回值：**

- `0` - 是 Debian 系
- `1` - 不是 Debian 系

**示例：**

```bash
if platform_is_debian; then
    apt install package
fi
```

### platform_is_redhat

检查是否为 RHEL 系发行版。

```bash
platform_is_redhat
```

**返回值：**

- `0` - 是 RHEL 系
- `1` - 不是 RHEL 系

**示例：**

```bash
if platform_is_redhat; then
    dnf install package
fi
```

### platform_is_arch

检查是否为 Arch 系发行版。

```bash
platform_is_arch
```

**返回值：**

- `0` - 是 Arch 系
- `1` - 不是 Arch 系

**示例：**

```bash
if platform_is_arch; then
    pacman -S package
fi
```

### platform_get_os

获取操作系统名称。

```bash
platform_get_os
```

**返回值：**

操作系统名称 (linux/darwin/windows)。

**示例：**

```bash
os=$(platform_get_os)
```

### platform_get_distro

获取发行版名称。

```bash
platform_get_distro
```

**返回值：**

发行版名称 (ubuntu/fedora/arch...)。

**示例：**

```bash
distro=$(platform_get_distro)
```

### platform_get_arch

获取系统架构。

```bash
platform_get_arch
```

**返回值：**

系统架构 (x86_64/arm64/i686...)。

**示例：**

```bash
arch=$(platform_get_arch)
```

---

## 包管理器

### platform_get_package_manager

获取包管理器名称。

```bash
platform_get_package_manager
```

**返回值：**

包管理器名称 (apt/dnf/pacman/brew/choco...)。

**示例：**

```bash
pm=$(platform_get_package_manager)
```

### platform_install_package

安装系统包。

```bash
platform_install_package <package>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| package | string | 是 | 包名 |

**示例：**

```bash
platform_install_package "openjdk-17-jdk"
```

### platform_install_packages

安装多个系统包。

```bash
platform_install_packages <packages...>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| packages | string... | 是 | 包名列表 |

**示例：**

```bash
platform_install_packages "openjdk-17-jdk" "maven" "gradle"
```

### platform_search_package

搜索系统包。

```bash
platform_search_package <query>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| query | string | 是 | 搜索关键词 |

**示例：**

```bash
platform_search_package "java"
```

### platform_update_packages

更新包列表。

```bash
platform_update_packages
```

**示例：**

```bash
platform_update_packages
```

---

## 权限检测

### platform_is_root

检查是否为 root 用户。

```bash
platform_is_root
```

**返回值：**

- `0` - 是 root
- `1` - 不是 root

**示例：**

```bash
if platform_is_root; then
    echo "以 root 运行"
fi
```

### platform_has_sudo

检查是否有 sudo 权限。

```bash
platform_has_sudo
```

**返回值：**

- `0` - 有 sudo 权限
- `1` - 无 sudo 权限

**示例：**

```bash
if platform_has_sudo; then
    sudo apt update
fi
```

### platform_run_as_root

以 root 权限执行命令。

```bash
platform_run_as_root <command...>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| command | string... | 是 | 要执行的命令 |

**示例：**

```bash
platform_run_as_root apt update
```

---

## 下一步

- [插件模块 API](plugin-api.md) - 插件 API 参考
- [跨平台支持](../advanced/cross-platform.md) - 跨平台文档
