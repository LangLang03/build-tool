# 国际化 API 参考

本文档详细介绍 `lib/i18n.sh` 模块提供的国际化 API。

---

## 目录

- [模块概述](#模块概述)
- [全局变量](#全局变量)
- [语言设置](#语言设置)
- [翻译函数](#翻译函数)
- [插件国际化](#插件国际化)

---

## 模块概述

`i18n.sh` 提供国际化支持：

- 多语言支持
- 自动语言检测
- 插件国际化扩展

---

## 全局变量

```bash
declare -g I18N_LANG="zh"             # 当前语言
declare -gA I18N_STRINGS=()           # 翻译字符串
declare -gA I18N_EN=()                # 英文字符串
declare -gA I18N_ZH=()                # 中文字符串
```

---

## 语言设置

### i18n_init

初始化国际化系统。

```bash
i18n_init
```

**说明：**

自动检测系统语言并设置。

**示例：**

```bash
i18n_init
```

### i18n_set_lang

设置语言。

```bash
i18n_set_lang <lang>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| lang | string | 是 | 语言代码 (en/zh) |

**示例：**

```bash
i18n_set_lang "en"
i18n_set_lang "zh"
```

### i18n_get_lang

获取当前语言。

```bash
i18n_get_lang
```

**返回值：**

当前语言代码。

**示例：**

```bash
lang=$(i18n_get_lang)
echo "当前语言: $lang"
```

### i18n_detect_lang

检测系统语言。

```bash
i18n_detect_lang
```

**返回值：**

检测到的语言代码。

**示例：**

```bash
lang=$(i18n_detect_lang)
```

---

## 翻译函数

### i18n_get

获取翻译字符串。

```bash
i18n_get <key>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| key | string | 是 | 字符串键 |

**返回值：**

翻译后的字符串。

**示例：**

```bash
msg=$(i18n_get "build.success")
echo "$msg"
```

### i18n_printf

格式化翻译字符串。

```bash
i18n_printf <key> <args...>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| key | string | 是 | 字符串键 |
| args | any | 否 | 格式化参数 |

**返回值：**

格式化后的字符串。

**示例：**

```bash
# 定义: "file.compiled": "成功编译 %d 个文件"
msg=$(i18n_printf "file.compiled" 10)
echo "$msg"  # 输出: 成功编译 10 个文件
```

### i18n_register

注册翻译字符串。

```bash
i18n_register <lang> <key> <value>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| lang | string | 是 | 语言代码 |
| key | string | 是 | 字符串键 |
| value | string | 是 | 翻译值 |

**示例：**

```bash
i18n_register "en" "build.success" "Build successful"
i18n_register "zh" "build.success" "构建成功"
```

### i18n_register_batch

批量注册翻译字符串。

```bash
i18n_register_batch <lang> <array_name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| lang | string | 是 | 语言代码 |
| array_name | string | 是 | 关联数组名 |

**示例：**

```bash
declare -A en_strings=(
    ["build.success"]="Build successful"
    ["build.failed"]="Build failed"
    ["file.compiled"]="Compiled %d files"
)

declare -A zh_strings=(
    ["build.success"]="构建成功"
    ["build.failed"]="构建失败"
    ["file.compiled"]="已编译 %d 个文件"
)

i18n_register_batch "en" en_strings
i18n_register_batch "zh" zh_strings
```

---

## 插件国际化

### i18n_plugin_prefix

获取插件国际化前缀。

```bash
i18n_plugin_prefix <plugin_name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| plugin_name | string | 是 | 插件名称 |

**返回值：**

插件前缀字符串。

**示例：**

```bash
prefix=$(i18n_plugin_prefix "java")
# 返回: plugin.java.
```

### i18n_plugin_get

获取插件翻译字符串。

```bash
i18n_plugin_get <plugin_name> <key>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| plugin_name | string | 是 | 插件名称 |
| key | string | 是 | 字符串键 |

**返回值：**

翻译后的字符串。

**示例：**

```bash
msg=$(i18n_plugin_get "java" "compile.success")
```

---

## 内置翻译键

### 通用键

| 键 | 英文 | 中文 |
|-----|------|------|
| `success` | Success | 成功 |
| `failed` | Failed | 失败 |
| `error` | Error | 错误 |
| `warning` | Warning | 警告 |
| `info` | Info | 信息 |

### 构建键

| 键 | 英文 | 中文 |
|-----|------|------|
| `build.start` | Starting build | 开始构建 |
| `build.success` | Build successful | 构建成功 |
| `build.failed` | Build failed | 构建失败 |
| `build.complete` | Build complete | 构建完成 |

### 文件键

| 键 | 英文 | 中文 |
|-----|------|------|
| `file.not_found` | File not found | 文件不存在 |
| `file.created` | File created | 文件已创建 |
| `file.deleted` | File deleted | 文件已删除 |
| `file.compiled` | Compiled %d files | 已编译 %d 个文件 |

---

## 下一步

- [插件模块 API](plugin-api.md) - 插件 API 参考
- [编写插件](../advanced/writing-plugins.md) - 插件国际化章节
