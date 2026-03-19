# 插件模块 API 参考

本文档详细介绍 `lib/plugin.sh` 模块提供的插件 API。

---

## 目录

- [模块概述](#模块概述)
- [全局变量](#全局变量)
- [插件管理](#插件管理)
- [插件信息](#插件信息)
- [插件依赖](#插件依赖)
- [钩子管理](#钩子管理)

---

## 模块概述

`plugin.sh` 提供插件管理功能：

- 插件发现和加载
- 插件依赖管理
- 钩子注册和执行
- 插件验证

---

## 全局变量

```bash
declare -gA PLUGINS=()                # 插件路径映射
declare -gA PLUGIN_META=()            # 插件元数据
declare -gA PLUGIN_DEPS=()            # 插件依赖
declare -gA PLUGIN_PACKAGES=()        # 插件系统包
declare -ga PLUGIN_DIRS=()            # 插件搜索目录
declare -ga LOADED_PLUGINS=()         # 已加载插件列表
```

---

## 插件管理

### plugin_init

初始化插件系统。

```bash
plugin_init
```

**示例：**

```bash
plugin_init
```

### plugin_add_dir

添加插件搜索目录。

```bash
plugin_add_dir <directory>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| directory | string | 是 | 目录路径 |

**示例：**

```bash
plugin_add_dir "/custom/plugins"
```

### plugin_discover

发现所有插件。

```bash
plugin_discover
```

**示例：**

```bash
plugin_discover
```

### plugin_load

加载指定插件。

```bash
plugin_load <name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| name | string | 是 | 插件名称 |

**返回值：**

- `0` - 加载成功
- `1` - 加载失败

**示例：**

```bash
plugin_load "java"
```

### plugin_load_all

加载所有发现的插件。

```bash
plugin_load_all
```

**示例：**

```bash
plugin_load_all
```

### plugin_reload

重新加载插件。

```bash
plugin_reload <name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| name | string | 是 | 插件名称 |

**示例：**

```bash
plugin_reload "java"
```

### plugin_unload

卸载插件。

```bash
plugin_unload <name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| name | string | 是 | 插件名称 |

**示例：**

```bash
plugin_unload "java"
```

### plugin_is_loaded

检查插件是否已加载。

```bash
plugin_is_loaded <name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| name | string | 是 | 插件名称 |

**返回值：**

- `0` - 已加载
- `1` - 未加载

**示例：**

```bash
if plugin_is_loaded "java"; then
    echo "Java 插件已加载"
fi
```

### plugin_list

列出所有插件。

```bash
plugin_list [verbose]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| verbose | string | 否 | false | 是否详细输出 |

**示例：**

```bash
plugin_list "false"
plugin_list "true"
```

---

## 插件信息

### plugin_get_version

获取插件版本。

```bash
plugin_get_version <name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| name | string | 是 | 插件名称 |

**返回值：**

插件版本字符串。

**示例：**

```bash
version=$(plugin_get_version "java")
```

### plugin_get_description

获取插件描述。

```bash
plugin_get_description <name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| name | string | 是 | 插件名称 |

**返回值：**

插件描述字符串。

**示例：**

```bash
desc=$(plugin_get_description "java")
```

### plugin_get_dependencies

获取插件命令依赖。

```bash
plugin_get_dependencies <name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| name | string | 是 | 插件名称 |

**返回值：**

依赖列表（逗号分隔）。

**示例：**

```bash
deps=$(plugin_get_dependencies "java")
```

### plugin_get_packages

获取插件系统包依赖。

```bash
plugin_get_packages <name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| name | string | 是 | 插件名称 |

**返回值：**

系统包列表（逗号分隔）。

**示例：**

```bash
pkgs=$(plugin_get_packages "java")
```

### plugin_has_packages

检查插件是否有系统包依赖。

```bash
plugin_has_packages <name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| name | string | 是 | 插件名称 |

**返回值：**

- `0` - 有系统包依赖
- `1` - 无系统包依赖

**示例：**

```bash
if plugin_has_packages "java"; then
    echo "Java 插件需要安装系统包"
fi
```

---

## 插件依赖

### plugin_check_dependencies

检查插件依赖是否满足。

```bash
plugin_check_dependencies <name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| name | string | 是 | 插件名称 |

**返回值：**

- `0` - 依赖满足
- `1` - 依赖缺失

**示例：**

```bash
if ! plugin_check_dependencies "java"; then
    echo "缺少依赖"
fi
```

### plugin_install_dependencies

安装插件依赖。

```bash
plugin_install_dependencies <name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| name | string | 是 | 插件名称 |

**示例：**

```bash
plugin_install_dependencies "java"
```

### plugin_install_packages

安装插件系统包。

```bash
plugin_install_packages <name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| name | string | 是 | 插件名称 |

**示例：**

```bash
plugin_install_packages "java"
```

### plugin_install_all_packages

安装所有插件的系统包。

```bash
plugin_install_all_packages
```

**示例：**

```bash
plugin_install_all_packages
```

---

## 钩子管理

### register_hook

注册钩子函数。

```bash
register_hook <hook_type> <plugin_name> <hook_func>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| hook_type | string | 是 | 钩子类型 |
| plugin_name | string | 是 | 插件名称 |
| hook_func | string | 是 | 钩子函数名 |

**示例：**

```bash
register_hook "pre_build" "java" "java_pre_build"
register_hook "post_build" "java" "java_post_build"
```

### run_hooks

执行指定类型的所有钩子。

```bash
run_hooks <hook_type> [args...]
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| hook_type | string | 是 | 钩子类型 |
| args | any | 否 | 钩子参数 |

**返回值：**

- `0` - 所有钩子执行成功
- `1` - 有钩子执行失败

**示例：**

```bash
run_hooks "pre_build" "build"
run_hooks "post_build"
```

### run_pre_build_hooks

执行 pre_build 钩子。

```bash
run_pre_build_hooks [target]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| target | string | 否 | "" | 目标名称 |

**示例：**

```bash
run_pre_build_hooks "build"
```

### run_post_build_hooks

执行 post_build 钩子。

```bash
run_post_build_hooks [target]
```

**示例：**

```bash
run_post_build_hooks "build"
```

### run_error_hooks

执行错误钩子。

```bash
run_error_hooks [target]
```

**示例：**

```bash
run_error_hooks "build"
```

### run_clean_hooks

执行清理钩子。

```bash
run_clean_hooks
```

**示例：**

```bash
run_clean_hooks
```

---

## 下一步

- [核心 API](core-api.md) - 核心 API 参考
- [目标系统](../user-guide/targets.md) - 目标系统文档
- [钩子系统](../user-guide/hooks.md) - 钩子系统文档
