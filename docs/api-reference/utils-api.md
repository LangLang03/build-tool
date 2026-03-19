# 工具函数 API 参考

本文档详细介绍 `lib/utils.sh` 模块提供的工具函数。

---

## 目录

- [模块概述](#模块概述)
- [字符串函数](#字符串函数)
- [数组函数](#数组函数)
- [文件函数](#文件函数)
- [时间函数](#时间函数)
- [JSON 函数](#json-函数)
- [类型检查函数](#类型检查函数)
- [数学函数](#数学函数)
- [随机函数](#随机函数)
- [执行控制函数](#执行控制函数)
- [脚本信息函数](#脚本信息函数)

---

## 模块概述

`utils.sh` 提供通用的工具函数，包括：

- 字符串处理
- 数组操作
- 文件操作
- 时间处理
- JSON 解析
- 类型检查
- 数学运算
- 随机生成
- 执行控制

---

## 字符串函数

### str_trim

去除字符串首尾空白。

```bash
str_trim <string>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| string | string | 是 | 输入字符串 |

**返回值：**

去除空白后的字符串。

**示例：**

```bash
result=$(str_trim "  hello world  ")
echo "$result"  # 输出: hello world
```

### str_split

分割字符串为数组。

```bash
str_split <string> <delimiter> <array_name>
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| string | string | 是 | - | 输入字符串 |
| delimiter | string | 否 | : | 分隔符 |
| array_name | string | 是 | - | 输出数组名 |

**示例：**

```bash
str_split "a,b,c" "," my_array
echo "${my_array[@]}"  # 输出: a b c
```

### str_join

连接数组为字符串。

```bash
str_join <delimiter> <elements...>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| delimiter | string | 是 | 分隔符 |
| elements | string... | 是 | 元素列表 |

**返回值：**

连接后的字符串。

**示例：**

```bash
result=$(str_join "," "a" "b" "c")
echo "$result"  # 输出: a,b,c
```

### str_lower

转换为小写。

```bash
str_lower <string>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| string | string | 是 | 输入字符串 |

**返回值：**

小写字符串。

**示例：**

```bash
result=$(str_lower "HELLO")
echo "$result"  # 输出: hello
```

### str_upper

转换为大写。

```bash
str_upper <string>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| string | string | 是 | 输入字符串 |

**返回值：**

大写字符串。

**示例：**

```bash
result=$(str_upper "hello")
echo "$result"  # 输出: HELLO
```

### str_starts_with

检查字符串是否以指定前缀开头。

```bash
str_starts_with <string> <prefix>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| string | string | 是 | 输入字符串 |
| prefix | string | 是 | 前缀 |

**返回值：**

- `0` - 以指定前缀开头
- `1` - 不以指定前缀开头

**示例：**

```bash
if str_starts_with "hello world" "hello"; then
    echo "以 hello 开头"
fi
```

### str_ends_with

检查字符串是否以指定后缀结尾。

```bash
str_ends_with <string> <suffix>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| string | string | 是 | 输入字符串 |
| suffix | string | 是 | 后缀 |

**返回值：**

- `0` - 以指定后缀结尾
- `1` - 不以指定后缀结尾

**示例：**

```bash
if str_ends_with "hello.txt" ".txt"; then
    echo "是文本文件"
fi
```

### str_contains

检查字符串是否包含子串。

```bash
str_contains <string> <substring>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| string | string | 是 | 输入字符串 |
| substring | string | 是 | 子串 |

**返回值：**

- `0` - 包含子串
- `1` - 不包含子串

**示例：**

```bash
if str_contains "hello world" "world"; then
    echo "包含 world"
fi
```

---

## 数组函数

### arr_contains

检查数组是否包含元素。

```bash
arr_contains <needle> <elements...>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| needle | string | 是 | 要查找的元素 |
| elements | string... | 是 | 数组元素 |

**返回值：**

- `0` - 包含
- `1` - 不包含

**示例：**

```bash
if arr_contains "b" "a" "b" "c"; then
    echo "包含 b"
fi

# 或使用数组
arr=("a" "b" "c")
if arr_contains "b" "${arr[@]}"; then
    echo "包含 b"
fi
```

### arr_unique

数组去重。

```bash
arr_unique <input_array> <output_array>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| input_array | string | 是 | 输入数组名 |
| output_array | string | 是 | 输出数组名 |

**示例：**

```bash
input=("a" "b" "a" "c" "b")
arr_unique input output
echo "${output[@]}"  # 输出: a b c
```

### arr_filter

过滤数组。

```bash
arr_filter <input_array> <output_array> <filter_func>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| input_array | string | 是 | 输入数组名 |
| output_array | string | 是 | 输出数组名 |
| filter_func | string | 是 | 过滤函数名 |

**示例：**

```bash
is_even() {
    local n=$1
    [[ $((n % 2)) -eq 0 ]]
}

input=(1 2 3 4 5 6)
arr_filter input output is_even
echo "${output[@]}"  # 输出: 2 4 6
```

### arr_map

映射数组。

```bash
arr_map <input_array> <output_array> <map_func>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| input_array | string | 是 | 输入数组名 |
| output_array | string | 是 | 输出数组名 |
| map_func | string | 是 | 映射函数名 |

**示例：**

```bash
double() {
    echo $(($1 * 2))
}

input=(1 2 3)
arr_map input output double
echo "${output[@]}"  # 输出: 2 4 6
```

### arr_length

获取数组长度。

```bash
arr_length <array_name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| array_name | string | 是 | 数组名 |

**返回值：**

数组长度。

**示例：**

```bash
arr=("a" "b" "c")
len=$(arr_length arr)
echo "$len"  # 输出: 3
```

### arr_first

获取数组第一个元素。

```bash
arr_first <array_name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| array_name | string | 是 | 数组名 |

**返回值：**

第一个元素。

**示例：**

```bash
arr=("a" "b" "c")
first=$(arr_first arr)
echo "$first"  # 输出: a
```

### arr_last

获取数组最后一个元素。

```bash
arr_last <array_name>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| array_name | string | 是 | 数组名 |

**返回值：**

最后一个元素。

**示例：**

```bash
arr=("a" "b" "c")
last=$(arr_last arr)
echo "$last"  # 输出: c
```

---

## 文件函数

### ensure_dir

确保目录存在。

```bash
ensure_dir <directory>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| directory | string | 是 | 目录路径 |

**示例：**

```bash
ensure_dir "/path/to/directory"
```

### file_exists

检查文件是否存在。

```bash
file_exists <path>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| path | string | 是 | 文件路径 |

**返回值：**

- `0` - 文件存在
- `1` - 文件不存在

**示例：**

```bash
if file_exists "/path/to/file"; then
    echo "文件存在"
fi
```

### dir_exists

检查目录是否存在。

```bash
dir_exists <path>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| path | string | 是 | 目录路径 |

**返回值：**

- `0` - 目录存在
- `1` - 目录不存在

**示例：**

```bash
if dir_exists "/path/to/directory"; then
    echo "目录存在"
fi
```

### file_readable

检查文件是否可读。

```bash
file_readable <path>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| path | string | 是 | 文件路径 |

**返回值：**

- `0` - 可读
- `1` - 不可读

**示例：**

```bash
if file_readable "/path/to/file"; then
    cat "/path/to/file"
fi
```

### file_writable

检查文件是否可写。

```bash
file_writable <path>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| path | string | 是 | 文件路径 |

**返回值：**

- `0` - 可写
- `1` - 不可写

**示例：**

```bash
if file_writable "/path/to/file"; then
    echo "content" > "/path/to/file"
fi
```

### file_executable

检查文件是否可执行。

```bash
file_executable <path>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| path | string | 是 | 文件路径 |

**返回值：**

- `0` - 可执行
- `1` - 不可执行

**示例：**

```bash
if file_executable "/path/to/script"; then
    /path/to/script
fi
```

### safe_copy

安全复制文件。

```bash
safe_copy <source> <destination> [backup]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| source | string | 是 | - | 源文件路径 |
| destination | string | 是 | - | 目标文件路径 |
| backup | string | 否 | true | 是否备份已存在的文件 |

**返回值：**

- `0` - 复制成功
- `1` - 源文件不存在

**示例：**

```bash
safe_copy "source.txt" "dest.txt"
safe_copy "source.txt" "dest.txt" "false"  # 不备份
```

### safe_move

安全移动文件。

```bash
safe_move <source> <destination> [backup]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| source | string | 是 | - | 源文件路径 |
| destination | string | 是 | - | 目标文件路径 |
| backup | string | 否 | true | 是否备份已存在的文件 |

**返回值：**

- `0` - 移动成功
- `1` - 源文件不存在

**示例：**

```bash
safe_move "old.txt" "new.txt"
```

### safe_delete

安全删除文件或目录。

```bash
safe_delete <path>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| path | string | 是 | 文件或目录路径 |

**示例：**

```bash
safe_delete "/path/to/file"
safe_delete "/path/to/directory"
```

### file_size

获取文件大小（字节）。

```bash
file_size <path>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| path | string | 是 | 文件路径 |

**返回值：**

文件大小（字节）。

**示例：**

```bash
size=$(file_size "file.txt")
echo "$size bytes"
```

### file_size_human

获取人类可读的文件大小。

```bash
file_size_human <path>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| path | string | 是 | 文件路径 |

**返回值：**

人类可读的文件大小（如 1.5MB）。

**示例：**

```bash
size=$(file_size_human "file.txt")
echo "$size"  # 输出: 1.5MB
```

### file_hash

计算文件哈希。

```bash
file_hash <path> [algorithm]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| path | string | 是 | - | 文件路径 |
| algorithm | string | 否 | md5 | 哈希算法 (md5/sha1/sha256) |

**返回值：**

文件哈希值。

**示例：**

```bash
hash=$(file_hash "file.txt")
echo "$hash"

sha256=$(file_hash "file.txt" "sha256")
echo "$sha256"
```

---

## 时间函数

### format_duration

格式化持续时间。

```bash
format_duration <seconds>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| seconds | integer | 是 | 秒数 |

**返回值：**

格式化的持续时间（如 1h 30m 45s）。

**示例：**

```bash
duration=$(format_duration 5445)
echo "$duration"  # 输出: 1h 30m 45s
```

### format_timestamp

格式化时间戳。

```bash
format_timestamp [timestamp] [format]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| timestamp | integer | 否 | 当前时间 | Unix 时间戳 |
| format | string | 否 | %Y-%m-%d %H:%M:%S | 格式字符串 |

**返回值：**

格式化的时间字符串。

**示例：**

```bash
formatted=$(format_timestamp)
echo "$formatted"  # 输出: 2024-01-15 10:30:45

custom=$(format_timestamp 1678886400 "%Y/%m/%d")
echo "$custom"  # 输出: 2023/03/15
```

### current_timestamp

获取当前 Unix 时间戳。

```bash
current_timestamp
```

**返回值：**

当前 Unix 时间戳。

**示例：**

```bash
ts=$(current_timestamp)
echo "$ts"  # 输出: 1678886400
```

### current_datetime

获取当前日期时间字符串。

```bash
current_datetime
```

**返回值：**

当前日期时间字符串。

**示例：**

```bash
dt=$(current_datetime)
echo "$dt"  # 输出: 2024-01-15 10:30:45
```

---

## JSON 函数

### json_get

从 JSON 字符串获取值。

```bash
json_get <json> <key>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| json | string | 是 | JSON 字符串 |
| key | string | 是 | 键名 |

**返回值：**

键对应的值。

**示例：**

```bash
json='{"name": "John", "age": 30}'
name=$(json_get "$json" "name")
echo "$name"  # 输出: John
```

### json_set

设置 JSON 字符串中的值。

```bash
json_set <json> <key> <value>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| json | string | 是 | JSON 字符串 |
| key | string | 是 | 键名 |
| value | string | 是 | 新值 |

**返回值：**

更新后的 JSON 字符串。

**示例：**

```bash
json='{"name": "John"}'
updated=$(json_set "$json" "age" "30")
echo "$updated"  # 输出: {"name": "John", "age": "30"}
```

---

## 类型检查函数

### is_number

检查是否为数字。

```bash
is_number <value>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| value | string | 是 | 要检查的值 |

**返回值：**

- `0` - 是数字
- `1` - 不是数字

**示例：**

```bash
if is_number "123"; then
    echo "是数字"
fi
```

### is_integer

检查是否为整数。

```bash
is_integer <value>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| value | string | 是 | 要检查的值 |

**返回值：**

- `0` - 是整数
- `1` - 不是整数

**示例：**

```bash
if is_integer "-42"; then
    echo "是整数"
fi
```

### is_float

检查是否为浮点数。

```bash
is_float <value>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| value | string | 是 | 要检查的值 |

**返回值：**

- `0` - 是浮点数
- `1` - 不是浮点数

**示例：**

```bash
if is_float "3.14"; then
    echo "是浮点数"
fi
```

### is_bool

检查是否为布尔值。

```bash
is_bool <value>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| value | string | 是 | 要检查的值 |

**返回值：**

- `0` - 是布尔值
- `1` - 不是布尔值

**示例：**

```bash
if is_bool "true"; then
    echo "是布尔值"
fi
```

### to_bool

转换为布尔值。

```bash
to_bool <value>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| value | string | 是 | 要转换的值 |

**返回值：**

"true" 或 "false"。

**示例：**

```bash
result=$(to_bool "yes")
echo "$result"  # 输出: true

result=$(to_bool "0")
echo "$result"  # 输出: false
```

---

## 数学函数

### clamp

限制值在范围内。

```bash
clamp <value> <min> <max>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| value | integer | 是 | 输入值 |
| min | integer | 是 | 最小值 |
| max | integer | 是 | 最大值 |

**返回值：**

限制后的值。

**示例：**

```bash
result=$(clamp 150 0 100)
echo "$result"  # 输出: 100
```

### min

返回较小值。

```bash
min <a> <b>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| a | integer | 是 | 第一个值 |
| b | integer | 是 | 第二个值 |

**返回值：**

较小的值。

**示例：**

```bash
result=$(min 5 10)
echo "$result"  # 输出: 5
```

### max

返回较大值。

```bash
max <a> <b>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| a | integer | 是 | 第一个值 |
| b | integer | 是 | 第二个值 |

**返回值：**

较大的值。

**示例：**

```bash
result=$(max 5 10)
echo "$result"  # 输出: 10
```

### abs

返回绝对值。

```bash
abs <value>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| value | integer | 是 | 输入值 |

**返回值：**

绝对值。

**示例：**

```bash
result=$(abs -42)
echo "$result"  # 输出: 42
```

---

## 随机函数

### random_string

生成随机字符串。

```bash
random_string [length]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| length | integer | 否 | 16 | 字符串长度 |

**返回值：**

随机字符串。

**示例：**

```bash
str=$(random_string 32)
echo "$str"  # 输出: a1b2c3d4e5f6...
```

### uuid

生成 UUID。

```bash
uuid
```

**返回值：**

UUID 字符串。

**示例：**

```bash
id=$(uuid)
echo "$id"  # 输出: 550e8400-e29b-41d4-a716-446655440000
```

---

## 执行控制函数

### retry

重试执行命令。

```bash
retry <max_attempts> <delay> <command...>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| max_attempts | integer | 是 | 最大尝试次数 |
| delay | integer | 是 | 重试间隔（秒） |
| command | string... | 是 | 要执行的命令 |

**返回值：**

- `0` - 命令成功
- `1` - 所有尝试都失败

**示例：**

```bash
if retry 3 2 curl -s "https://example.com"; then
    echo "请求成功"
fi
```

### timeout_exec

带超时执行命令。

```bash
timeout_exec <timeout> <command...>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| timeout | integer | 是 | 超时时间（秒） |
| command | string... | 是 | 要执行的命令 |

**返回值：**

- `0` - 命令成功
- `124` - 超时
- 其他 - 命令返回值

**示例：**

```bash
if timeout_exec 10 sleep 5; then
    echo "命令完成"
fi
```

---

## 脚本信息函数

### get_script_dir

获取脚本所在目录。

```bash
get_script_dir
```

**返回值：**

脚本所在目录的绝对路径。

**示例：**

```bash
dir=$(get_script_dir)
echo "$dir"  # 输出: /path/to/script/directory
```

### get_script_name

获取脚本名称。

```bash
get_script_name
```

**返回值：**

脚本名称。

**示例：**

```bash
name=$(get_script_name)
echo "$name"  # 输出: build
```

---

## 下一步

- [核心 API](core-api.md) - 核心 API 参考
- [输出模块 API](output-api.md) - 输出 API 参考
- [配置模块 API](config-api.md) - 配置 API 参考
