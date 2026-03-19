# 配置模块 API 参考

本文档详细介绍 `lib/config.sh` 模块提供的配置 API。

---

## 目录

- [模块概述](#模块概述)
- [全局变量](#全局变量)
- [读取配置](#读取配置)
- [设置配置](#设置配置)
- [检查配置](#检查配置)
- [配置文件](#配置文件)
- [配置模板](#配置模板)

---

## 模块概述

`config.sh` 提供配置管理功能：

- 多格式配置文件支持（YAML/INI/Shell）
- 配置优先级管理
- 环境变量覆盖
- 配置模板处理

---

## 全局变量

```bash
declare -gA CONFIG=()                 # 配置存储
declare -gA CONFIG_DEFAULTS=()        # 默认值
declare -g CONFIG_FILE=""             # 当前配置文件
declare -g CONFIG_DIR=""              # 配置目录
```

---

## 读取配置

### config_get

获取配置值。

```bash
config_get <key> [default]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| key | string | 是 | - | 配置键名 |
| default | string | 否 | "" | 默认值 |

**返回值：**

配置值或默认值。

**示例：**

```bash
value=$(config_get "VERBOSE")
value=$(config_get "JOBS" "4")
```

### config_get_bool

获取布尔配置值。

```bash
config_get_bool <key> [default]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| key | string | 是 | - | 配置键名 |
| default | string | 否 | false | 默认值 |

**返回值：**

- `0` - 值为 true
- `1` - 值为 false

**示例：**

```bash
if config_get_bool "VERBOSE"; then
    echo "详细模式已启用"
fi
```

### config_get_int

获取整数配置值。

```bash
config_get_int <key> [default]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| key | string | 是 | - | 配置键名 |
| default | integer | 否 | 0 | 默认值 |

**返回值：**

整数值。

**示例：**

```bash
jobs=$(config_get_int "JOBS" "4")
```

### config_get_array

获取数组配置值。

```bash
config_get_array <key> <delimiter> <array_name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| key | string | 是 | 配置键名 |
| delimiter | string | 是 | 分隔符 |
| array_name | string | 是 | 输出数组名 |

**示例：**

```bash
config_get_array "PLUGINS" "," plugins_array
echo "${plugins_array[@]}"
```

---

## 设置配置

### config_set

设置配置值。

```bash
config_set <key> <value>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| key | string | 是 | 配置键名 |
| value | string | 是 | 配置值 |

**示例：**

```bash
config_set "VERBOSE" "true"
config_set "JOBS" "8"
```

### config_set_array

设置数组配置值。

```bash
config_set_array <key> <delimiter> <values...>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| key | string | 是 | 配置键名 |
| delimiter | string | 是 | 分隔符 |
| values | string... | 是 | 数组值 |

**示例：**

```bash
config_set_array "PLUGINS" "," "java" "python" "node"
```

### config_unset

删除配置项。

```bash
config_unset <key>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| key | string | 是 | 配置键名 |

**示例：**

```bash
config_unset "VERBOSE"
```

---

## 检查配置

### config_has

检查配置是否存在。

```bash
config_has <key>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| key | string | 是 | 配置键名 |

**返回值：**

- `0` - 配置存在
- `1` - 配置不存在

**示例：**

```bash
if config_has "PROJECT_NAME"; then
    echo "项目名称已设置"
fi
```

### config_validate

验证必需配置项。

```bash
config_validate <keys...>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| keys | string... | 是 | 配置键名列表 |

**返回值：**

- `0` - 所有配置都存在
- `1` - 有配置缺失

**示例：**

```bash
if ! config_validate "PROJECT_NAME" "PROJECT_VERSION"; then
    echo "缺少必需配置"
    exit 1
fi
```

### config_list

列出配置项。

```bash
config_list [prefix]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| prefix | string | 否 | "" | 键前缀过滤 |

**示例：**

```bash
config_list           # 列出所有配置
config_list "BUILD"   # 列出 BUILD 前缀的配置
```

---

## 配置文件

### config_load_file

加载配置文件。

```bash
config_load_file <file>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| file | string | 是 | 配置文件路径 |

**返回值：**

- `0` - 加载成功
- `1` - 文件不存在或格式错误

**示例：**

```bash
config_load_file "build.yaml"
config_load_file "config/default.conf"
```

### config_save_file

保存配置到文件。

```bash
config_save_file <file> [format]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| file | string | 是 | - | 配置文件路径 |
| format | string | 否 | yaml | 输出格式 (yaml/ini) |

**示例：**

```bash
config_save_file "output.yaml" "yaml"
```

### config_find_file

查找配置文件。

```bash
config_find_file [directory]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| directory | string | 否 | 当前目录 | 搜索目录 |

**返回值：**

找到的配置文件路径。

**示例：**

```bash
config_file=$(config_find_file)
```

---

## 配置模板

### config_template

处理配置模板。

```bash
config_template <template>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| template | string | 是 | 模板字符串 |

**返回值：**

处理后的字符串。

**示例：**

```bash
result=$(config_template '${project.name}-${project.version}')
echo "$result"  # 输出: my-project-1.0.0
```

---

## 下一步

- [核心 API](core-api.md) - 核心 API 参考
- [缓存模块 API](cache-api.md) - 缓存 API 参考
