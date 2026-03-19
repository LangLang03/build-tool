# 日志模块 API 参考

本文档详细介绍 `lib/log.sh` 模块提供的日志 API。

---

## 目录

- [模块概述](#模块概述)
- [全局变量](#全局变量)
- [日志函数](#日志函数)
- [日志级别](#日志级别)
- [日志文件](#日志文件)
- [日志配置](#日志配置)

---

## 模块概述

`log.sh` 提供日志记录功能：

- 多级别日志（DEBUG/INFO/WARN/ERROR）
- 日志文件输出
- 日志轮转
- 日志格式化

---

## 全局变量

```bash
declare -g LOG_LEVEL="INFO"           # 日志级别
declare -g LOG_FILE=""                # 日志文件路径
declare -g LOG_MAX_SIZE=10485760      # 最大文件大小（10MB）
declare -g LOG_MAX_FILES=5            # 保留文件数
declare -g LOG_TO_FILE=false          # 是否输出到文件
declare -g LOG_TO_STDOUT=true         # 是否输出到标准输出
```

---

## 日志函数

### log_debug

记录调试日志。

```bash
log_debug <message>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| message | string | 是 | 日志消息 |

**示例：**

```bash
log_debug "变量值: $var"
```

### log_info

记录信息日志。

```bash
log_info <message>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| message | string | 是 | 日志消息 |

**示例：**

```bash
log_info "构建开始"
```

### log_warn

记录警告日志。

```bash
log_warn <message>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| message | string | 是 | 日志消息 |

**示例：**

```bash
log_warn "配置文件不存在，使用默认值"
```

### log_error

记录错误日志。

```bash
log_error <message>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| message | string | 是 | 日志消息 |

**示例：**

```bash
log_error "编译失败"
```

### log_fatal

记录致命错误日志并退出。

```bash
log_fatal <message> [exit_code]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| message | string | 是 | - | 日志消息 |
| exit_code | integer | 否 | 1 | 退出码 |

**示例：**

```bash
log_fatal "无法继续执行" 2
```

---

## 日志级别

### 级别定义

| 级别 | 值 | 说明 |
|------|-----|------|
| DEBUG | 0 | 调试信息 |
| INFO | 1 | 一般信息 |
| WARN | 2 | 警告信息 |
| ERROR | 3 | 错误信息 |
| NONE | 4 | 禁用日志 |

### set_log_level

设置日志级别。

```bash
set_log_level <level>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| level | string | 是 | 日志级别 (DEBUG/INFO/WARN/ERROR/NONE) |

**示例：**

```bash
set_log_level "DEBUG"
```

### get_log_level

获取当前日志级别。

```bash
get_log_level
```

**返回值：**

当前日志级别字符串。

**示例：**

```bash
level=$(get_log_level)
echo "当前日志级别: $level"
```

---

## 日志文件

### set_log_file

设置日志文件。

```bash
set_log_file <file>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| file | string | 是 | 日志文件路径 |

**示例：**

```bash
set_log_file "build.log"
```

### log_rotate

轮转日志文件。

```bash
log_rotate
```

**说明：**

当日志文件超过最大大小时，自动轮转。

**示例：**

```bash
log_rotate
```

### log_flush

刷新日志缓冲区。

```bash
log_flush
```

**示例：**

```bash
log_flush
```

---

## 日志配置

### log_set_max_size

设置日志文件最大大小。

```bash
log_set_max_size <size>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| size | integer | 是 | 最大大小（字节） |

**示例：**

```bash
log_set_max_size 20971520  # 20MB
```

### log_set_max_files

设置保留日志文件数。

```bash
log_set_max_files <count>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| count | integer | 是 | 文件数 |

**示例：**

```bash
log_set_max_files 10
```

---

## 下一步

- [输出模块 API](output-api.md) - 输出 API 参考
- [配置模块 API](config-api.md) - 配置 API 参考
