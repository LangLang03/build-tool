# 输出模块 API 参考

本文档详细介绍 `lib/output.sh` 模块提供的输出格式化 API。

***

## 目录

- [模块概述](#模块概述)
- [全局变量](#全局变量)
- [基本输出](#基本输出)
- [格式化输出](#格式化输出)
- [进度显示](#进度显示)
- [表格输出](#表格输出)
- [树形输出](#树形输出)
- [配置函数](#配置函数)

***

## 模块概述

`output.sh` 提供丰富的终端输出格式化功能：

- 彩色输出
- Unicode 符号
- 进度条
- 表格
- 树形结构
- 步骤状态
- 文件状态

***

## 全局变量

```bash
declare -g OUTPUT_USE_COLOR=true      # 是否使用彩色
declare -g OUTPUT_USE_UNICODE=true    # 是否使用 Unicode
declare -g OUTPUT_VERBOSE=false       # 是否详细输出
declare -g OUTPUT_QUIET=false         # 是否静默模式
declare -g OUTPUT_TIMESTAMP=false     # 是否显示时间戳
```

### 颜色变量

```bash
COLOR_RESET=""      # 重置
COLOR_BOLD=""       # 粗体
COLOR_DIM=""        # 暗淡
COLOR_RED=""        # 红色
COLOR_GREEN=""      # 绿色
COLOR_YELLOW=""     # 黄色
COLOR_BLUE=""       # 蓝色
COLOR_MAGENTA=""    # 品红
COLOR_CYAN=""       # 青色
COLOR_WHITE=""      # 白色
```

***

## 基本输出

### output\_print

打印普通消息。

```bash
output_print <message>
```

**参数：**

| 参数      | 类型     | 必需 | 说明   |
| ------- | ------ | -- | ---- |
| message | string | 是  | 消息内容 |

**示例：**

```bash
output_print "Hello, World!"
```

### output\_info

打印信息消息。

```bash
output_info <message>
```

**参数：**

| 参数      | 类型     | 必需 | 说明   |
| ------- | ------ | -- | ---- |
| message | string | 是  | 消息内容 |

**图标：** ℹ

**示例：**

```bash
output_info "正在处理..."
```

### output\_success

打印成功消息。

```bash
output_success <message>
```

**参数：**

| 参数      | 类型     | 必需 | 说明   |
| ------- | ------ | -- | ---- |
| message | string | 是  | 消息内容 |

**图标：** ✓

**示例：**

```bash
output_success "构建完成"
```

### output\_warning

打印警告消息。

```bash
output_warning <message>
```

**参数：**

| 参数      | 类型     | 必需 | 说明   |
| ------- | ------ | -- | ---- |
| message | string | 是  | 消息内容 |

**图标：** ⚠

**示例：**

```bash
output_warning "配置文件不存在"
```

### output\_error

打印错误消息。

```bash
output_error <message>
```

**参数：**

| 参数      | 类型     | 必需 | 说明   |
| ------- | ------ | -- | ---- |
| message | string | 是  | 消息内容 |

**图标：** ✗

**输出到：** stderr

**示例：**

```bash
output_error "编译失败"
```

### output\_debug

打印调试消息（仅在详细模式下显示）。

```bash
output_debug <message>
```

**参数：**

| 参数      | 类型     | 必需 | 说明   |
| ------- | ------ | -- | ---- |
| message | string | 是  | 消息内容 |

**图标：** ⚙

**示例：**

```bash
output_debug "变量值: $var"
```

***

## 格式化输出

### output\_header

打印标题头。

```bash
output_header <title> [width]
```

**参数：**

| 参数    | 类型      | 必需 | 默认值 | 说明   |
| ----- | ------- | -- | --- | ---- |
| title | string  | 是  | -   | 标题文本 |
| width | integer | 否  | 60  | 宽度   |

**示例：**

```bash
output_header "构建工具配置" 50
```

输出：

```
╔══════════════════════════════════════════════════════╗
║ 构建工具配置                                          ║
╚══════════════════════════════════════════════════════╝
```

### output\_section

打印章节标题。

```bash
output_section <title>
```

**参数：**

| 参数    | 类型     | 必需 | 说明   |
| ----- | ------ | -- | ---- |
| title | string | 是  | 章节标题 |

**示例：**

```bash
output_section "系统信息"
```

输出：

```
▶ 系统信息
────────────────────────────────────────────────────────────
```

### output\_subsection

打印子章节标题。

```bash
output_subsection <title>
```

**参数：**

| 参数    | 类型     | 必需 | 说明    |
| ----- | ------ | -- | ----- |
| title | string | 是  | 子章节标题 |

**示例：**

```bash
output_subsection "环境变量"
```

### output\_bullet

打印项目符号列表项。

```bash
output_bullet <message> [level]
```

**参数：**

| 参数      | 类型      | 必需 | 默认值 | 说明         |
| ------- | ------- | -- | --- | ---------- |
| message | string  | 是  | -   | 消息内容       |
| level   | integer | 否  | 1   | 缩进级别 (1-4) |

**示例：**

```bash
output_bullet "项目 1"
output_bullet "子项目" 2
output_bullet "子子项目" 3
```

输出：

```
  • 项目 1
    ◦ 子项目
      ▪ 子子项目
```

### output\_key\_value

打印键值对。

```bash
output_key_value <key> <value> [width]
```

**参数：**

| 参数    | 类型      | 必需 | 默认值 | 说明  |
| ----- | ------- | -- | --- | --- |
| key   | string  | 是  | -   | 键名  |
| value | string  | 是  | -   | 值   |
| width | integer | 否  | 20  | 键宽度 |

**示例：**

```bash
output_key_value "项目名称" "my-project" 15
output_key_value "版本" "1.0.0" 15
```

输出：

```
  项目名称:       my-project
  版本:           1.0.0
```

### output\_divider

打印分隔线。

```bash
output_divider [char] [width]
```

**参数：**

| 参数    | 类型      | 必需 | 默认值 | 说明   |
| ----- | ------- | -- | --- | ---- |
| char  | string  | 否  | -   | 分隔字符 |
| width | integer | 否  | 60  | 宽度   |

**示例：**

```bash
output_divider
output_divider "=" 40
```

***

## 进度显示

### output\_progress\_start

开始进度条。

```bash
output_progress_start <total>
```

**参数：**

| 参数    | 类型      | 必需 | 说明 |
| ----- | ------- | -- | -- |
| total | integer | 是  | 总数 |

**示例：**

```bash
output_progress_start 100
```

### output\_progress\_update

更新进度条。

```bash
output_progress_update [increment]
```

**参数：**

| 参数        | 类型      | 必需 | 默认值 | 说明 |
| --------- | ------- | -- | --- | -- |
| increment | integer | 否  | 1   | 增量 |

**示例：**

```bash
output_progress_update 1
```

### output\_progress\_end

结束进度条。

```bash
output_progress_end
```

**示例：**

```bash
output_progress_end
```

### 完整进度条示例

```bash
output_progress_start 10

for i in {1..10}; do
    # 执行任务
    sleep 0.1
    output_progress_update
done

output_progress_end
```

输出：

```
  [████████████████████████████████████████] 100% (10/10)
```

***

## 步骤状态

### output\_step\_start

开始步骤计数。

```bash
output_step_start <total>
```

**参数：**

| 参数    | 类型      | 必需 | 说明   |
| ----- | ------- | -- | ---- |
| total | integer | 是  | 总步骤数 |

**示例：**

```bash
output_step_start 5
```

### output\_step

输出步骤状态。

```bash
output_step <name> <status>
```

**参数：**

| 参数     | 类型     | 必需 | 说明                                 |
| ------ | ------ | -- | ---------------------------------- |
| name   | string | 是  | 步骤名称                               |
| status | string | 是  | 状态 (running/success/error/skipped) |

**状态图标：**

| 状态      | 图标 | 颜色 |
| ------- | -- | -- |
| running | ◐  | 黄色 |
| success | ✓  | 绿色 |
| error   | ✗  | 红色 |
| skipped | ○  | 暗淡 |

**示例：**

```bash
output_step_start 3

output_step "编译源码" "running"
# 执行编译
output_step "编译源码" "success"

output_step "运行测试" "running"
# 执行测试
output_step "运行测试" "success"

output_step "打包" "running"
# 执行打包
output_step "打包" "error"
```

输出：

```
  ✓ [1/3] 编译源码
  ✓ [2/3] 运行测试
  ✗ [3/3] 打包
```

### output\_step\_end

结束步骤计数。

```bash
output_step_end
```

***

## 文件状态

### output\_file\_status

输出文件处理状态。

```bash
output_file_status <source> <destination> <status>
```

**参数：**

| 参数          | 类型     | 必需 | 说明                                           |
| ----------- | ------ | -- | -------------------------------------------- |
| source      | string | 是  | 源文件路径                                        |
| destination | string | 是  | 目标文件路径                                       |
| status      | string | 是  | 状态 (processing/success/error/skipped/cached) |

**状态图标：**

| 状态         | 图标 | 颜色 |
| ---------- | -- | -- |
| processing | →  | 蓝色 |
| success    | ✓  | 绿色 |
| error      | ✗  | 红色 |
| skipped    | ○  | 暗淡 |
| cached     | ≡  | 青色 |

**示例：**

```bash
output_file_status "src/Main.java" "output/Main.class" "success"
output_file_status "src/Util.java" "output/Util.class" "cached"
```

输出：

```
    ✓ src/Main.java → output/Main.class
    ≡ src/Util.java → output/Util.class
```

***

## 表格输出

### output\_table

输出表格。

```bash
output_table <headers_array> <rows_array>
```

**参数：**

| 参数             | 类型     | 必需 | 说明             |
| -------------- | ------ | -- | -------------- |
| headers\_array | string | 是  | 表头数组名          |
| rows\_array    | string | 是  | 行数据数组名（Tab 分隔） |

**示例：**

```bash
headers=("名称" "版本" "描述")
rows=(
    "java${TAB}1.0.0${TAB}Java 插件"
    "python${TAB}1.0.0${TAB}Python 插件"
    "node${TAB}1.0.0${TAB}Node.js 插件"
)

output_table headers rows
```

输出：

```
 ┌──────────┬─────────┬───────────────┐
 │ 名称     │ 版本    │ 描述          │
 ├──────────┼─────────┼───────────────┤
 │ java     │ 1.0.0   │ Java 插件     │
 │ python   │ 1.0.0   │ Python 插件   │
 │ node     │ 1.0.0   │ Node.js 插件  │
 └──────────┴─────────┴───────────────┘
```

***

## 树形输出

### output\_tree

输出树形结构。

```bash
output_tree <items_array> [prefix] [is_last]
```

**参数：**

| 参数           | 类型     | 必需 | 默认值   | 说明     |
| ------------ | ------ | -- | ----- | ------ |
| items\_array | string | 是  | -     | 项目数组名  |
| prefix       | string | 否  | ""    | 前缀     |
| is\_last     | string | 否  | false | 是否最后一项 |

**示例：**

```bash
items=(
    "项目根目录"
    "src:Main.java,Util.java"
    "lib:gson.jar,jackson.jar"
    "output:classes,libs"
)

output_tree items
```

输出：

```
├── 项目根目录
├── src
│   ├── Main.java
│   └── Util.java
├── lib
│   ├── gson.jar
│   └── jackson.jar
└── output
    ├── classes
    └── libs
```

***

## 摘要输出

### output\_summary

输出构建摘要。

```bash
output_summary <title> <success> <failed> <skipped> <duration>
```

**参数：**

| 参数       | 类型      | 必需 | 说明   |
| -------- | ------- | -- | ---- |
| title    | string  | 是  | 标题   |
| success  | integer | 是  | 成功数  |
| failed   | integer | 是  | 失败数  |
| skipped  | integer | 是  | 跳过数  |
| duration | string  | 是  | 持续时间 |

**示例：**

```bash
output_summary "构建摘要" 10 0 2 "5s"
```

输出：

```
═══════════════════════════════════════════════════════════════ 构建摘要 ═════

  ✓ 成功:  10
  ✗ 失败:   0
  ○ 跳过:   2
  Σ 总计:   12

  持续时间: 5s

构建成功完成。
```

***

## Spinner 动画

### output\_spinner\_start

开始 Spinner 动画。

```bash
output_spinner_start <message>
```

**参数：**

| 参数      | 类型     | 必需 | 说明   |
| ------- | ------ | -- | ---- |
| message | string | 是  | 消息内容 |

**示例：**

```bash
output_spinner_start "正在处理..."
```

### output\_spinner\_update

更新 Spinner 消息。

```bash
output_spinner_update <message>
```

**示例：**

```bash
output_spinner_update "正在编译..."
```

### output\_spinner\_stop

停止 Spinner 动画。

```bash
output_spinner_stop <message> <status>
```

**参数：**

| 参数      | 类型     | 必需 | 说明                 |
| ------- | ------ | -- | ------------------ |
| message | string | 是  | 结束消息               |
| status  | string | 是  | 状态 (success/error) |

**示例：**

```bash
output_spinner_stop "处理完成" "success"
```

***

## 配置函数

### output\_set\_color

设置是否使用彩色。

```bash
output_set_color <enable>
```

**参数：**

| 参数     | 类型     | 必需 | 说明         |
| ------ | ------ | -- | ---------- |
| enable | string | 是  | true/false |

**示例：**

```bash
output_set_color false
```

### output\_set\_unicode

设置是否使用 Unicode。

```bash
output_set_unicode <enable>
```

**参数：**

| 参数     | 类型     | 必需 | 说明         |
| ------ | ------ | -- | ---------- |
| enable | string | 是  | true/false |

**示例：**

```bash
output_set_unicode false
```

### output\_set\_verbose

启用详细输出。

```bash
output_set_verbose
```

**示例：**

```bash
output_set_verbose
```

### output\_set\_quiet

启用静默模式。

```bash
output_set_quiet
```

**示例：**

```bash
output_set_quiet
```

### output\_set\_timestamp

启用时间戳。

```bash
output_set_timestamp
```

**示例：**

```bash
output_set_timestamp
```

***

## 下一步

- [核心 API](core-api.md) - 核心 API 参考
- [工具函数 API](utils-api.md) - 工具函数参考
- [日志模块 API](log-api.md) - 日志 API 参考

