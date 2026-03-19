# 自定义目标示例

本文档展示如何创建和使用自定义构建目标。

---

## 目录

- [目标概述](#目标概述)
- [在 YAML 中定义目标](#在-yaml-中定义目标)
- [在脚本中定义目标](#在脚本中定义定义目标)
- [目标依赖](#目标依赖)
- [完整示例](#完整示例)

---

## 目标概述

自定义目标允许你扩展 build-tool 的功能，添加项目特定的构建任务。

---

## 在 YAML 中定义目标

### 基本定义

```yaml
targets:
  build: scripts/build.sh
  test: scripts/test.sh
  clean: scripts/clean.sh
```

### 带描述的定义

```yaml
targets:
  build:
    script: scripts/build.sh
    description: 编译项目源码
  
  test:
    script: scripts/test.sh
    description: 运行单元测试
  
  lint:
    script: scripts/lint.sh
    description: 代码风格检查
```

### 带依赖的定义

```yaml
targets:
  build:
    script: scripts/build.sh
    description: 编译项目
    deps: []
  
  test:
    script: scripts/test.sh
    description: 运行测试
    deps: [build]
  
  package:
    script: scripts/package.sh
    description: 打包
    deps: [build, test]
  
  release:
    script: scripts/release.sh
    description: 发布
    deps: [package]
```

---

## 在脚本中定义目标

### 创建目标脚本

`scripts/build.sh`:

```bash
#!/usr/bin/env bash

step_start "编译源码"

local src_dir="${SOURCE_DIR:-src}"
local build_dir="${BUILD_DIR:-output}"

ensure_dir "$build_dir"

# 查找源文件
local -a sources=()
while IFS= read -r -d '' file; do
    sources+=("$file")
done < <(find "$src_dir" -name "*.java" -print0 2>/dev/null)

local total=${#sources[@]}
output_info "找到 $total 个源文件"

# 编译
local success=0
local failed=0

for src in "${sources[@]}"; do
    output_file_status "$src" "$build_dir" "processing"
    
    if javac -d "$build_dir" "$src" 2>&1; then
        output_file_status "$src" "$build_dir" "success"
        ((success++))
    else
        output_file_status "$src" "$build_dir" "error"
        ((failed++))
    fi
done

step_end

if [[ $failed -gt 0 ]]; then
    output_error "$failed 个文件编译失败"
    return 1
fi

output_success "成功编译 $success 个文件"
return 0
```

### 创建清理脚本

`scripts/clean.sh`:

```bash
#!/usr/bin/env bash

output_info "清理构建产物..."

rm -rf "${BUILD_DIR:-output}"
rm -rf "${CACHE_DIR:-.cache}"

output_success "清理完成"
return 0
```

---

## 目标依赖

### 依赖图

```
release
   │
   ├── package
   │      │
   │      ├── build
   │      │
   │      └── test
   │             │
   │             └── build
   │
   └── docs
          │
          └── build
```

### 定义复杂依赖

```yaml
targets:
  build:
    script: scripts/build.sh
    deps: []
  
  test:
    script: scripts/test.sh
    deps: [build]
  
  lint:
    script: scripts/lint.sh
    deps: []
  
  docs:
    script: scripts/docs.sh
    deps: [build]
  
  package:
    script: scripts/package.sh
    deps: [build, test, lint]
  
  release:
    script: scripts/release.sh
    deps: [package, docs]
```

---

## 完整示例

### 项目结构

```
my-project/
├── build.yaml
├── scripts/
│   ├── build.sh
│   ├── test.sh
│   ├── lint.sh
│   ├── docs.sh
│   ├── package.sh
│   └── release.sh
└── src/
    └── ...
```

### build.yaml

```yaml
project:
  name: my-project
  version: 1.0.0

directories:
  source: src
  build: output
  docs: docs

targets:
  build:
    script: scripts/build.sh
    description: 编译项目
    deps: []
  
  test:
    script: scripts/test.sh
    description: 运行测试
    deps: [build]
  
  lint:
    script: scripts/lint.sh
    description: 代码检查
    deps: []
  
  docs:
    script: scripts/docs.sh
    description: 生成文档
    deps: [build]
  
  package:
    script: scripts/package.sh
    description: 打包发布
    deps: [build, test, lint]
  
  release:
    script: scripts/release.sh
    description: 发布版本
    deps: [package, docs]
  
  clean:
    script: scripts/clean.sh
    description: 清理构建产物
    deps: []

hooks:
  pre_build: scripts/hooks/pre_build.sh
  post_build: scripts/hooks/post_build.sh
```

### 执行示例

```bash
# 执行单个目标
build build

# 执行带依赖的目标
build release

# 查看执行顺序
build -v release
```

输出：

```
⚙ 解析目标依赖
⚙ 执行顺序: build test lint package docs release

▶ build
✓ build 完成

▶ test
✓ test 完成

▶ lint
✓ lint 完成

▶ package
✓ package 完成

▶ docs
✓ docs 完成

▶ release
✓ release 完成

构建成功完成。
```

---

## 下一步

- [目标系统](../user-guide/targets.md) - 目标系统文档
- [钩子系统](../user-guide/hooks.md) - 钩子系统文档
