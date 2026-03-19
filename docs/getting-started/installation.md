# 安装指南

本文档详细介绍 build-tool 的安装方法、系统要求和验证步骤。

---

## 目录

- [系统要求](#系统要求)
- [安装方式](#安装方式)
- [验证安装](#验证安装)
- [升级](#升级)
- [卸载](#卸载)

---

## 系统要求

### 必需组件

| 组件 | 要求 | 说明 |
|------|------|------|
| **Bash** | 4.0+ | 需要关联数组（associative arrays）支持 |
| **基础工具** | - | cat, mkdir, rm, cp, mv |

### 检查 Bash 版本

```bash
# 查看 Bash 版本
bash --version

# 输出示例
# GNU bash, version 5.1.16(1)-release (x86_64-pc-linux-gnu)
```

如果版本低于 4.0，请先升级 Bash。

### 各平台升级 Bash

#### Linux

```bash
# Debian/Ubuntu
sudo apt update && sudo apt install bash

# RHEL/CentOS/Fedora
sudo dnf install bash

# Arch Linux
sudo pacman -S bash

# Alpine
apk add bash
```

#### macOS

macOS 默认的 Bash 版本较旧（3.2），需要通过 Homebrew 安装新版本：

```bash
# 安装 Homebrew（如果未安装）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装 Bash
brew install bash

# 将新 Bash 添加到 /etc/shells
echo '/usr/local/bin/bash' | sudo tee -a /etc/shells

# 更改默认 Shell
chsh -s /usr/local/bin/bash
```

#### Windows (WSL)

WSL 默认包含较新的 Bash：

```bash
# 更新 WSL
wsl --update

# 在 WSL 内更新 Bash
sudo apt update && sudo apt install bash
```

### 可选依赖

| 依赖 | 用途 | 安装命令 |
|------|------|----------|
| **yq** | YAML 配置文件支持 | `brew install yq` / `sudo apt install yq` |
| **jq** | JSON 处理 | `brew install jq` / `sudo apt install jq` |
| **md5sum** | 文件哈希（缓存） | 通常已内置 |
| **sha256sum** | 文件哈希（缓存） | 通常已内置 |

### 平台支持矩阵

| 平台 | 支持状态 | 说明 |
|------|----------|------|
| **Linux** | ✅ 完全支持 | 所有主流发行版 |
| **macOS** | ✅ 完全支持 | 需要 Bash 4+（见上文） |
| **Windows (WSL)** | ✅ 完全支持 | 推荐在 Windows 上使用的方式 |
| **Windows (Git Bash)** | ⚠️ 部分支持 | 路径处理可能有问题 |
| **Windows (Cygwin)** | ⚠️ 部分支持 | 需要测试 |
| **FreeBSD** | ⚠️ 部分支持 | 需要测试 |
| **OpenBSD** | ⚠️ 部分支持 | 需要测试 |
| **NetBSD** | ⚠️ 部分支持 | 需要测试 |

---

## 安装方式

### 方式一：从源码安装（推荐）

```bash
# 1. 克隆仓库
git clone https://github.com/your-repo/build-tool.git

# 2. 进入目录
cd build-tool

# 3. 添加执行权限
chmod +x build

# 4. 验证安装
./build version
```

### 方式二：下载压缩包

```bash
# 1. 下载最新版本
curl -L https://github.com/your-repo/build-tool/archive/refs/heads/main.tar.gz -o build-tool.tar.gz

# 2. 解压
tar -xzf build-tool.tar.gz

# 3. 进入目录
cd build-tool-main

# 4. 添加执行权限
chmod +x build

# 5. 验证安装
./build version
```

### 方式三：添加到 PATH

为了在任何目录都能使用 `build` 命令，可以将其添加到 PATH：

#### 方法 A：创建符号链接

```bash
# 假设 build-tool 位于 /opt/build-tool
sudo ln -s /opt/build-tool/build /usr/local/bin/build
```

#### 方法 B：修改 PATH 环境变量

在 `~/.bashrc` 或 `~/.bash_profile` 中添加：

```bash
# 添加 build-tool 到 PATH
export PATH="/path/to/build-tool:$PATH"
```

然后重新加载配置：

```bash
source ~/.bashrc
```

#### 方法 C：创建别名

在 `~/.bashrc` 中添加：

```bash
alias build='/path/to/build-tool/build'
```

---

## 验证安装

### 检查版本

```bash
./build version
```

预期输出：

```
build-tool v1.0.0
平台: linux (ubuntu)
架构: x86_64
包管理器: apt
```

### 检查环境

```bash
./build check
```

预期输出：

```
╔══════════════════════════════════════════════════════╗
║ 环境检查                                              ║
╚══════════════════════════════════════════════════════╝

系统
  操作系统:        linux
  发行版:          ubuntu
  架构:            x86_64
  Root权限:        false
  Sudo权限:        true

包管理器
✓ 找到包管理器: apt

必需工具
✓ bash 可用
✓ cat 可用
✓ mkdir 可用
✓ rm 可用
✓ cp 可用
✓ mv 可用

可选工具
✓ yq 可用 (推荐)

插件
✓ 找到 1 个插件
  • java

摘要
✓ 所有检查通过
```

### 检查帮助

```bash
./build help
```

---

## 升级

### 从源码升级

```bash
# 进入 build-tool 目录
cd /path/to/build-tool

# 拉取最新代码
git pull origin main

# 验证新版本
./build version
```

### 手动升级

1. 删除旧版本
2. 按照 [安装方式](#安装方式) 重新安装

---

## 卸载

### 删除文件

```bash
# 删除 build-tool 目录
rm -rf /path/to/build-tool

# 如果创建了符号链接
sudo rm /usr/local/bin/build
```

### 清理配置

```bash
# 删除用户配置和缓存
rm -rf ~/.build-tool
rm -rf ~/.cache/build-tool
```

### 移除 PATH 配置

编辑 `~/.bashrc` 或 `~/.bash_profile`，删除以下内容：

```bash
# 删除这行
export PATH="/path/to/build-tool:$PATH"

# 或删除别名
alias build='/path/to/build-tool/build'
```

重新加载配置：

```bash
source ~/.bashrc
```

---

## 常见安装问题

### 问题：Bash 版本过低

**症状：**

```
./build: line 10: declare: -gA: invalid option
```

**解决方案：**

升级 Bash 到 4.0 或更高版本。参见 [各平台升级 Bash](#各平台升级-bash)。

### 问题：权限被拒绝

**症状：**

```
bash: ./build: Permission denied
```

**解决方案：**

```bash
chmod +x build
```

### 问题：找不到 yq

**症状：**

```
⚠ yq not found, skipping YAML config
```

**解决方案：**

```bash
# 使用 build-tool 安装 yq
./build install yq

# 或手动安装
# macOS
brew install yq

# Linux
sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
sudo chmod +x /usr/bin/yq
```

### 问题：Windows 路径问题

**症状：**

在 Git Bash 中路径解析错误。

**解决方案：**

推荐使用 WSL：

```bash
# 安装 WSL
wsl --install

# 在 WSL 中安装 build-tool
```

---

## 下一步

安装完成后，请继续阅读：

- [快速开始](quick-start.md) - 创建你的第一个项目
- [配置详解](../user-guide/configuration.md) - 了解配置选项
