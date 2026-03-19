# YAML 模块 API 参考

本文档详细介绍 `lib/yaml.sh` 模块提供的 YAML 解析 API。

---

## 目录

- [模块概述](#模块概述)
- [YAML 解析](#yaml-解析)
- [YAML 生成](#yaml-生成)
- [YAML 验证](#yaml-验证)

---

## 模块概述

`yaml.sh` 提供 YAML 文件处理功能：

- YAML 文件解析
- YAML 内容生成
- YAML 格式验证

---

## YAML 解析

### yaml_parse_file

解析 YAML 文件。

```bash
yaml_parse_file <file> [prefix]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| file | string | 是 | - | YAML 文件路径 |
| prefix | string | 否 | YAML_ | 变量前缀 |

**返回值：**

- `0` - 解析成功
- `1` - 文件不存在或格式错误

**示例：**

```bash
yaml_parse_file "build.yaml"
echo "$YAML_PROJECT_NAME"
echo "$YAML_PROJECT_VERSION"
```

### yaml_parse_string

解析 YAML 字符串。

```bash
yaml_parse_string <yaml_string> [prefix]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| yaml_string | string | 是 | - | YAML 字符串 |
| prefix | string | 否 | YAML_ | 变量前缀 |

**示例：**

```bash
yaml='
project:
  name: my-project
  version: 1.0.0
'
yaml_parse_string "$yaml"
echo "$YAML_PROJECT_NAME"  # 输出: my-project
```

### yaml_get

获取 YAML 值。

```bash
yaml_get <key>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| key | string | 是 | 键名（点分隔） |

**返回值：**

键对应的值。

**示例：**

```bash
name=$(yaml_get "project.name")
version=$(yaml_get "project.version")
```

### yaml_get_array

获取 YAML 数组。

```bash
yaml_get_array <key> <array_name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| key | string | 是 | 键名 |
| array_name | string | 是 | 输出数组名 |

**示例：**

```bash
yaml_get_array "plugins" plugins_array
echo "${plugins_array[@]}"
```

---

## YAML 生成

### yaml_generate

生成 YAML 字符串。

```bash
yaml_generate <associative_array>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| associative_array | string | 是 | 关联数组名 |

**返回值：**

YAML 字符串。

**示例：**

```bash
declare -A config=(
    ["project.name"]="my-project"
    ["project.version"]="1.0.0"
)
yaml_str=$(yaml_generate config)
echo "$yaml_str"
```

### yaml_write_file

写入 YAML 文件。

```bash
yaml_write_file <file> <associative_array>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| file | string | 是 | 文件路径 |
| associative_array | string | 是 | 关联数组名 |

**示例：**

```bash
declare -A config=(
    ["project.name"]="my-project"
    ["project.version"]="1.0.0"
)
yaml_write_file "output.yaml" config
```

---

## YAML 验证

### yaml_validate_file

验证 YAML 文件格式。

```bash
yaml_validate_file <file>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| file | string | 是 | YAML 文件路径 |

**返回值：**

- `0` - 格式正确
- `1` - 格式错误

**示例：**

```bash
if yaml_validate_file "build.yaml"; then
    echo "YAML 格式正确"
fi
```

### yaml_validate_string

验证 YAML 字符串格式。

```bash
yaml_validate_string <yaml_string>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| yaml_string | string | 是 | YAML 字符串 |

**返回值：**

- `0` - 格式正确
- `1` - 格式错误

**示例：**

```bash
if yaml_validate_string "$yaml_content"; then
    echo "YAML 格式正确"
fi
```

---

## 下一步

- [配置模块 API](config-api.md) - 配置 API 参考
- [配置详解](../user-guide/configuration.md) - 配置文档
