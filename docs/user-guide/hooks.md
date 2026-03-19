# 钩子系统

本文档详细介绍 build-tool 的钩子（Hook）系统，包括钩子类型、注册方式和执行顺序。

---

## 目录

- [钩子概念](#钩子概念)
- [钩子类型](#钩子类型)
- [注册钩子](#注册钩子)
- [钩子执行顺序](#钩子执行顺序)
- [钩子最佳实践](#钩子最佳实践)

---

## 钩子概念

**钩子（Hook）** 是在构建过程的关键节点执行的回调函数，用于：

- 在构建前后执行自定义逻辑
- 处理构建错误
- 清理资源
- 发送通知

### 钩子与目标的区别

| 特性 | 钩子 | 目标 |
|------|------|------|
| 触发方式 | 自动触发 | 手动执行 |
| 执行时机 | 固定节点 | 用户指定 |
| 主要用途 | 辅助逻辑 | 核心构建 |
| 是否可单独执行 | 否 | 是 |

---

## 钩子类型

### 构建钩子

| 钩子类型 | 触发时机 | 用途 |
|----------|----------|------|
| `pre_build` | 目标执行前 | 准备工作、环境检查 |
| `post_build` | 目标执行后（成功） | 清理、通知 |
| `on_error` | 目标执行后（失败） | 错误处理、回滚 |

### 步骤钩子

| 钩子类型 | 触发时机 | 用途 |
|----------|----------|------|
| `pre_step` | 每个步骤执行前 | 步骤准备 |
| `post_step` | 每个步骤执行后 | 步骤清理 |

### 清理钩子

| 钩子类型 | 触发时机 | 用途 |
|----------|----------|------|
| `on_clean` | 执行 clean 命令时 | 自定义清理逻辑 |

---

## 注册钩子

### 在插件中注册

```bash
#!/usr/bin/env bash

PLUGIN_NAME="my-plugin"

# 注册钩子
register_hook "pre_build" "my-plugin" "my_pre_build"
register_hook "post_build" "my-plugin" "my_post_build"
register_hook "on_error" "my-plugin" "my_on_error"

# 钩子函数
my_pre_build() {
    log_info "准备构建..."
    # 检查环境
    # 创建临时文件
    # 设置变量
}

my_post_build() {
    log_info "构建完成!"
    # 清理临时文件
    # 发送通知
}

my_on_error() {
    log_error "构建失败!"
    # 回滚操作
    # 发送告警
}
```

### 在 YAML 配置中注册

```yaml
hooks:
  pre_build: scripts/hooks/pre_build.sh
  post_build: scripts/hooks/post_build.sh
```

`scripts/hooks/pre_build.sh`：

```bash
#!/usr/bin/env bash

echo "执行构建前钩子..."

# 检查依赖
if ! command -v javac &>/dev/null; then
    output_error "未找到 javac，请安装 JDK"
    exit 1
fi

# 创建必要目录
ensure_dir "$BUILD_DIR"

# 设置环境变量
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
```

### 在 Shell 脚本中注册

```bash
#!/usr/bin/env bash

# 定义钩子函数
pre_build_hook() {
    log_info "开始构建..."
}

post_build_hook() {
    log_info "构建结束!"
}

# 钩子函数会自动被调用（如果存在）
```

---

## 钩子执行顺序

### 单目标执行流程

```
┌─────────────────────────────────────────────────────────────┐
│                    build build                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  执行 pre_build 钩子（按插件注册顺序）                        │
│  java_pre_build → custom_pre_build → ...                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  执行 build 目标                                            │
│  java_build()                                               │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    │ 成功              │ 失败
                    ▼                   ▼
        ┌──────────────────┐   ┌──────────────────┐
        │  post_build 钩子  │   │  on_error 钩子   │
        └──────────────────┘   └──────────────────┘
```

### 多目标执行流程

```
┌─────────────────────────────────────────────────────────────┐
│                    build release                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  pre_build 钩子                                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  执行 build 目标                                            │
│    └── pre_step → post_step                                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  执行 test 目标                                             │
│    └── pre_step → post_step                                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  执行 package 目标                                          │
│    └── pre_step → post_step                                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  执行 release 目标                                          │
│    └── pre_step → post_step                                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  post_build 钩子                                            │
└─────────────────────────────────────────────────────────────┘
```

### 钩子执行顺序规则

1. **pre_build 钩子**：按插件加载顺序执行
2. **目标执行**：按依赖拓扑顺序执行
3. **post_build 钩子**：按插件加载顺序执行
4. **on_error 钩子**：任意目标失败时执行

---

## 钩子最佳实践

### 1. pre_build 钩子 - 准备工作

```bash
pre_build_hook() {
    # 检查环境
    if ! command -v javac &>/dev/null; then
        output_error "未找到 javac"
        return 1
    fi
    
    # 创建目录
    ensure_dir "$BUILD_DIR"
    ensure_dir "$BUILD_DIR/classes"
    ensure_dir "$BUILD_DIR/libs"
    
    # 设置环境
    export CLASSPATH="$BUILD_DIR/classes"
    
    # 生成版本信息
    echo "version=$PROJECT_VERSION" > "$BUILD_DIR/version.properties"
}
```

### 2. post_build 钩子 - 清理和通知

```bash
post_build_hook() {
    # 清理临时文件
    rm -rf /tmp/build-*
    
    # 生成构建报告
    cat > "$BUILD_DIR/build-report.txt" << EOF
项目: $PROJECT_NAME
版本: $PROJECT_VERSION
构建时间: $(date)
构建目录: $BUILD_DIR
EOF
    
    # 发送通知（可选）
    if command -v notify-send &>/dev/null; then
        notify-send "构建完成" "$PROJECT_NAME v$PROJECT_VERSION"
    fi
}
```

### 3. on_error 钩子 - 错误处理

```bash
on_error_hook() {
    local target="$1"
    
    # 记录错误日志
    echo "[$(date)] 构建失败: $target" >> build-errors.log
    
    # 清理部分构建产物
    rm -rf "$BUILD_DIR/classes"
    
    # 发送告警
    if command -v curl &>/dev/null; then
        curl -X POST "https://hooks.example.com/alert" \
            -d "project=$PROJECT_NAME&error=Build failed at $target"
    fi
}
```

### 4. on_clean 钩子 - 自定义清理

```bash
on_clean_hook() {
    # 清理标准目录
    rm -rf "$BUILD_DIR"
    
    # 清理额外目录
    rm -rf .cache
    rm -rf .tmp
    
    # 清理日志
    rm -f build.log
    rm -f build-errors.log
    
    output_success "清理完成"
}
```

### 5. 步骤钩子 - 进度跟踪

```bash
pre_step_hook() {
    local step_name="$1"
    log_debug "开始步骤: $step_name"
}

post_step_hook() {
    local step_name="$1"
    local success="$2"
    
    if [[ "$success" == "true" ]]; then
        log_debug "步骤完成: $step_name"
    else
        log_debug "步骤失败: $step_name"
    fi
}
```

---

## 钩子 API

### 注册钩子

```bash
# 注册钩子
register_hook "hook_type" "plugin_name" "hook_function"

# 示例
register_hook "pre_build" "java" "java_pre_build"
register_hook "post_build" "java" "java_post_build"
register_hook "on_error" "java" "java_on_error"
register_hook "on_clean" "java" "java_on_clean"
```

### 执行钩子

```bash
# 执行指定类型的所有钩子
run_hooks "pre_build"
run_hooks "post_build"
run_hooks "on_error"
run_hooks "on_clean"

# 执行钩子并传递参数
run_hooks "pre_build" "arg1" "arg2"
```

### 便捷函数

```bash
# 执行 pre_build 钩子
run_pre_build_hooks

# 执行 post_build 钩子
run_post_build_hooks

# 执行错误钩子
run_error_hooks

# 执行清理钩子
run_clean_hooks
```

---

## 钩子与错误处理

### 钩子失败处理

如果钩子执行失败：

- **pre_build 钩子失败**：阻止目标执行
- **post_build 钩子失败**：记录警告，不影响构建结果
- **on_error 钩子失败**：记录警告

### 示例

```bash
pre_build_hook() {
    # 检查必需条件
    if [[ ! -f "$SOURCE_DIR/Main.java" ]]; then
        output_error "未找到主类源文件"
        return 1  # 返回非零阻止构建
    fi
    
    return 0
}
```

---

## 钩子使用场景

### 1. 环境检查

```bash
pre_build_hook() {
    # 检查 Java 版本
    local java_version
    java_version=$(javac -version 2>&1 | cut -d' ' -f2)
    
    if [[ "${java_version%%.*}" -lt 17 ]]; then
        output_error "需要 Java 17 或更高版本，当前版本: $java_version"
        return 1
    fi
}
```

### 2. 代码生成

```bash
pre_build_hook() {
    # 生成版本类
    cat > "$SOURCE_DIR/Version.java" << EOF
public class Version {
    public static final String VERSION = "$PROJECT_VERSION";
    public static final String BUILD_TIME = "$(date -Iseconds)";
}
EOF
}
```

### 3. 依赖下载

```bash
pre_build_hook() {
    # 下载依赖
    local libs_dir="$BUILD_DIR/libs"
    ensure_dir "$libs_dir"
    
    if [[ ! -f "$libs_dir/gson.jar" ]]; then
        output_info "下载 Gson 库..."
        curl -L "https://repo1.maven.org/maven2/com/google/code/gson/gson/2.10.1/gson-2.10.1.jar" \
            -o "$libs_dir/gson.jar"
    fi
}
```

### 4. 构建报告

```bash
post_build_hook() {
    # 生成构建报告
    local report="$BUILD_DIR/report.json"
    
    cat > "$report" << EOF
{
    "project": "$PROJECT_NAME",
    "version": "$PROJECT_VERSION",
    "build_time": "$(date -Iseconds)",
    "duration": $((BUILD_END_TIME - BUILD_START_TIME)),
    "success": $BUILD_SUCCESS_COUNT,
    "failed": $BUILD_FAIL_COUNT,
    "skipped": $BUILD_SKIP_COUNT
}
EOF
}
```

### 5. 部署通知

```bash
post_build_hook() {
    # 发送 Slack 通知
    if [[ -n "$SLACK_WEBHOOK" ]]; then
        curl -X POST "$SLACK_WEBHOOK" \
            -H 'Content-Type: application/json' \
            -d "{
                \"text\": \"构建完成: $PROJECT_NAME v$PROJECT_VERSION\",
                \"attachments\": [{
                    \"color\": \"good\",
                    \"fields\": [{
                        \"title\": \"构建时间\",
                        \"value\": \"$((BUILD_END_TIME - BUILD_START_TIME))秒\",
                        \"short\": true
                    }]
                }]
            }"
    fi
}
```

---

## 下一步

- [插件系统](plugins.md) - 了解插件如何注册钩子
- [目标系统](targets.md) - 了解目标执行流程
- [插件模块 API](../api-reference/plugin-api.md) - 钩子 API 参考
