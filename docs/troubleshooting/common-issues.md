# 常见问题

本文档列出 build-tool 的常见问题及解决方案。

***

## 目录

- [安装问题](#安装问题)
- [配置问题](#配置问题)
- [构建问题](#构建问题)
- [插件问题](#插件问题)
- [缓存问题](#缓存问题)
- [跨平台问题](#跨平台问题)
- [其他问题](#其他问题)

***

## 安装问题

### Q: Bash 版本过低怎么办？

**症状：**

```
./build: line 10: declare: -gA: invalid option
```

**原因：** Bash 版本低于 4.0，不支持关联数组。

**解决方案：**

升级 Bash 到 4.0 或更高版本：

```bash
# macOS
brew install bash

# Ubuntu/Debian
sudo apt update && sudo apt install bash

# CentOS/RHEL
sudo dnf install bash
```

### Q: 权限被拒绝？

**症状：**

```
bash: ./build: Permission denied
```

**解决方案：**

```bash
chmod +x build
```

### Q: 找不到 yq？

**症状：**

```
⚠ yq not found, skipping YAML config
```

**解决方案：**

安装 yq：

```bash
# macOS
brew install yq

# Linux
sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
sudo chmod +x /usr/bin/yq
```

***

## 配置问题

### Q: 配置文件不生效？

**可能原因：**

1. 配置文件命名错误
2. 配置文件格式错误
3. 配置优先级问题

**解决方案：**

1. 确认配置文件名称正确：
   - `build.yaml` 或 `build.yml`（YAML 格式）
   - `build.conf` 或 `.build`（INI 格式）
2. 验证配置文件格式：
   ```bash
   # YAML 格式验证
   yq build.yaml

   # 查看当前配置
   ./build config
   ```
3. 检查配置优先级：
   ```
   命令行参数 > 环境变量 > 项目配置文件 > 全局配置文件 > 默认值
   ```

### Q: 配置模板变量不替换？

**症状：**

```yaml
jar_output: ${project.name}-${project.version}.jar
# 输出: ${project.name}-${project.version}.jar（未替换）
```

**解决方案：**

确保变量名正确：

```yaml
# 正确
java:
  jar_output: ${project.name}-${project.version}.jar

# 错误（拼写错误）
java:
  jar_output: ${project.nmae}-${project.vesion}.jar
```

***

## 构建问题

### Q: 构建失败但没有错误信息？

**解决方案：**

使用详细模式查看更多信息：

```bash
./build -v build
```

### Q: 循环依赖错误？

**症状：**

```
✗ 检测到循环依赖
目标 A 依赖 B，B 依赖 C，C 依赖 A
```

**解决方案：**

检查并修复目标依赖关系：

```yaml
# 错误：循环依赖
targets:
  A:
    deps: [B]
  B:
    deps: [C]
  C:
    deps: [A]

# 正确：移除循环
targets:
  A:
    deps: []
  B:
    deps: [A]
  C:
    deps: [B]
```

### Q: 并行构建失败？

**症状：**

并行构建时出现随机错误。

**解决方案：**

1. 减少并行作业数：
   ```bash
   ./build -j 2 build
   ```
2. 禁用并行构建：
   ```bash
   export BUILD_PARALLEL=false
   ./build build
   ```

### Q: 增量构建不工作？

**症状：**

每次都重新编译所有文件。

**解决方案：**

1. 确认增量构建已启用：
   ```bash
   ./build config | grep incremental
   ```
2. 检查缓存状态：
   ```bash
   ./build cache stats
   ```
3. 确认文件时间戳正确：
   ```bash
   ls -la src/
   ```

***

## 插件问题

### Q: 插件未被发现？

**症状：**

```
⚠ No plugins found
```

**解决方案：**

1. 确认插件目录正确：
   ```bash
   ls -la plugins/
   ```
2. 确认插件文件命名正确：
   - `<name>.sh`
   - `<name>.plugin.sh`
3. 确认插件有执行权限：
   ```bash
   chmod +x plugins/*.sh
   ```

### Q: 插件加载失败？

**症状：**

```
✗ Failed to load plugin: java
```

**解决方案：**

1. 验证插件语法：
   ```bash
   bash -n plugins/java.sh
   ```
2. 检查插件依赖：
   ```bash
   ./build plugin deps java
   ```
3. 安装缺失依赖：
   ```bash
   ./build plugin install-deps java
   ```

### Q: 插件目标冲突？

**症状：**

多个插件注册了同名目标。

**解决方案：**

1. 查看目标来源：
   ```bash
   ./build list
   ```
2. 使用完整目标名：
   ```bash
   ./build java:build
   ```

***

## 缓存问题

### Q: 缓存占用空间过大？

**解决方案：**

1. 查看缓存大小：
   ```bash
   ./build cache stats
   ```
2. 清理过期缓存：
   ```bash
   ./build cache cleanup
   ```
3. 清空缓存：
   ```bash
   ./build cache clear
   ```
4. 设置缓存大小限制：
   ```bash
   export BUILD_CACHE_MAX_SIZE=536870912  # 512MB
   ```

### Q: 缓存损坏？

**症状：**

构建结果不正确或缓存读取失败。

**解决方案：**

```bash
# 清空缓存
./build cache clear

# 重新构建
./build build
```

***

## 跨平台问题

### Q: Windows 路径问题？

**症状：**

在 Git Bash 中路径解析错误。

**解决方案：**

推荐使用 WSL：

```bash
# 安装 WSL
wsl --install

# 在 WSL 中使用 build-tool
```

### Q: macOS 命令不兼容？

**症状：**

某些 Linux 命令在 macOS 上不可用。

**解决方案：**

安装 GNU 工具：

```bash
# 安装 coreutils
brew install coreutils

# 使用 g 前缀的命令
gstat  # 代替 stat
gdate  # 代替 date
```

### Q: 包管理器未检测到？

**症状：**

```
⚠ No package manager found
```

**解决方案：**

1. 确认包管理器已安装：
   ```bash
   # Debian/Ubuntu
   which apt

   # RHEL/CentOS
   which dnf

   # macOS
   which brew
   ```
2. 手动指定包管理器：
   ```bash
   export BUILD_PACKAGE_MANAGER=apt
   ```

***

## 其他问题

### Q: 如何查看调试信息？

**解决方案：**

```bash
# 详细模式
./build -v build

# 调试模式
BUILD_DEBUG=true ./build build
```

### Q: 如何重置所有配置？

**解决方案：**

```bash
# 删除用户配置
rm -rf ~/.build-tool

# 删除缓存
rm -rf ~/.cache/build-tool

# 删除项目缓存
rm -rf .cache
```

### Q: 如何报告问题？

**解决方案：**

1. 收集诊断信息：
   ```bash
   ./build version
   ./build check
   ./build config
   ./build -v build 2>&1 | tee build.log
   ```
2. 在 GitHub Issues 中报告：
   - 描述问题
   - 附上诊断信息
   - 说明复现步骤

***

## 下一步

- [安装指南](../getting-started/installation.md) - 安装指南
- [配置详解](../user-guide/configuration.md) - 配置文档

