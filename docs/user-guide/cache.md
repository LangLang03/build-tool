# 缓存管理

本文档详细介绍 build-tool 的缓存系统，包括缓存机制、缓存命令、缓存配置和缓存清理策略。

---

## 目录

- [缓存概念](#缓存概念)
- [缓存机制原理](#缓存机制原理)
- [缓存目录结构](#缓存目录结构)
- [缓存命令](#缓存命令)
- [缓存配置](#缓存配置)
- [增量构建](#增量构建)
- [缓存 API](#缓存-api)
- [最佳实践](#最佳实践)

---

## 缓存概念

build-tool 的缓存系统用于：

- **加速构建**：跳过未变更的文件编译
- **存储中间结果**：保存构建过程中的中间产物
- **支持增量构建**：基于文件哈希判断是否需要重新构建

### 缓存类型

| 类型 | 说明 | 用途 |
|------|------|------|
| **构建缓存** | 文件哈希缓存 | 增量构建判断 |
| **输出缓存** | 编译产物缓存 | 快速恢复构建结果 |
| **元数据缓存** | 缓存条目信息 | 缓存管理和过期清理 |

---

## 缓存机制原理

### 文件哈希

build-tool 使用文件哈希来判断文件是否变更：

```
源文件 ──────► 哈希计算 ──────► 缓存键
   │
   │  比较
   ▼
缓存哈希 ════════════════════► 是否重新构建
```

### 缓存键生成

```bash
# 缓存键 = 文件哈希 + 目标路径
cache_key=$(cache_incremental_key "$source_file" "$output_file")
```

示例：

```
源文件: src/Main.java
目标文件: output/classes/Main.class
缓存键: a1b2c3d4e5f6_output_classes_Main_class
```

### 增量构建流程

```
┌─────────────────────────────────────────────────────────────┐
│                    增量构建流程                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  遍历源文件                                                  │
│  for src in sources; do                                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  计算缓存键                                                  │
│  cache_key = hash(src) + hash(target)                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  检查缓存                                                    │
│  cache_has(cache_key) ?                                      │
└─────────────────────────────────────────────────────────────┘
                    │                   │
                    │ 是                │ 否
                    ▼                   ▼
        ┌──────────────────┐   ┌──────────────────┐
        │  跳过编译         │   │  执行编译         │
        │  使用缓存结果     │   │  更新缓存         │
        └──────────────────┘   └──────────────────┘
                    │                   │
                    └─────────┬─────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  继续处理下一个文件                                          │
└─────────────────────────────────────────────────────────────┘
```

---

## 缓存目录结构

### 默认位置

```bash
# Linux/macOS
~/.cache/build-tool/

# Windows (WSL)
~/.cache/build-tool/

# 自定义位置
export BUILD_CACHE_DIR=/custom/cache/path
```

### 目录结构

```
~/.cache/build-tool/
├── meta/                    # 元数据目录
│   ├── a1b2c3d4.meta       # 缓存条目元数据
│   ├── e5f6g7h8.meta
│   └── ...
├── files/                   # 缓存文件目录
│   ├── a1b2c3d4            # 缓存文件内容
│   ├── e5f6g7h8
│   └── ...
└── stats                    # 缓存统计文件
```

### 元数据文件格式

```bash
# meta/a1b2c3d4.meta
CACHE_META_KEY="a1b2c3d4"
CACHE_META_CREATED=1678886400
CACHE_META_EXPIRES=1679491200
CACHE_META_SOURCE="/path/to/source/file"
CACHE_META_HASH="md5hash..."
```

---

## 缓存命令

### 查看缓存统计

```bash
build cache stats
build cache status
```

输出：

```
缓存统计
  命中:       150
  未命中:     25
  命中率:     85%
  条目:       45
  大小:       12.5MB
```

### 清空缓存

```bash
build cache clear
build cache clean
```

输出：

```
ℹ 清理缓存...
✓ 缓存已清理
```

### 启用缓存

```bash
build cache enable
```

输出：

```
✓ 缓存已启用
```

### 禁用缓存

```bash
build cache disable
```

输出：

```
✓ 缓存已禁用
```

### 清理过期缓存

```bash
build cache cleanup
```

输出：

```
ℹ 清理过期和过大的缓存条目...
✓ 缓存清理完成
```

---

## 缓存配置

### 配置文件

在 `config/default.conf` 中配置：

```ini
[cache]
enabled = true
max_size = 1073741824
max_age = 604800
hash_algorithm = "md5"
```

### 配置项说明

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `CACHE.ENABLED` | boolean | true | 是否启用缓存 |
| `CACHE.MAX_SIZE` | integer | 1073741824 | 缓存最大大小（字节，默认 1GB） |
| `CACHE.MAX_AGE` | integer | 604800 | 缓存有效期（秒，默认 7 天） |
| `CACHE.HASH_ALGORITHM` | string | md5 | 哈希算法 (md5/sha1/sha256) |
| `CACHE.DIR` | string | ~/.cache/build-tool | 缓存目录 |

### 环境变量

```bash
# 禁用缓存
export BUILD_CACHE_ENABLED=false

# 设置缓存目录
export BUILD_CACHE_DIR=/tmp/build-cache

# 设置缓存最大大小（1GB）
export BUILD_CACHE_MAX_SIZE=1073741824

# 设置缓存有效期（1天）
export BUILD_CACHE_MAX_AGE=86400
```

### 命令行选项

```bash
# 禁用缓存（本次构建）
build --no-cache build

# 使用详细输出查看缓存命中情况
build -v build
```

---

## 增量构建

### 原理

增量构建通过比较文件哈希来判断是否需要重新编译：

1. **首次构建**：编译所有文件，缓存哈希
2. **后续构建**：
   - 文件未变更 → 跳过编译
   - 文件已变更 → 重新编译，更新缓存

### 判断逻辑

```bash
# 检查是否需要重新构建
if cache_needs_rebuild "$source" "$output"; then
    # 需要重新编译
    compile "$source"
    # 更新缓存
    cache_mark_built "$source" "$output"
else
    # 使用缓存
    output_file_status "$source" "$output" "cached"
fi
```

### 增量构建示例

```bash
# 首次构建
build build
# 输出: 编译 10 个文件

# 未修改文件，再次构建
build build
# 输出: 跳过 10 个文件（使用缓存）

# 修改一个文件
echo "// comment" >> src/Main.java

# 再次构建
build build
# 输出: 编译 1 个文件，跳过 9 个文件
```

### 强制重新构建

```bash
# 方法一：禁用缓存
build --no-cache build

# 方法二：清空缓存后构建
build cache clear && build build

# 方法三：删除构建输出
rm -rf output && build build
```

---

## 缓存 API

### 初始化缓存

```bash
# 使用默认目录初始化
cache_init

# 使用指定目录初始化
cache_init "/custom/cache/dir"

# 设置缓存目录
cache_set_dir "/custom/cache/dir"
```

### 启用/禁用缓存

```bash
# 启用缓存
cache_enable

# 禁用缓存
cache_disable

# 检查缓存是否启用
if cache_is_enabled; then
    echo "缓存已启用"
fi
```

### 缓存操作

```bash
# 检查缓存是否存在
if cache_has "my_cache_key"; then
    echo "缓存存在"
fi

# 获取缓存内容
content=$(cache_get "my_cache_key")

# 获取缓存到文件
cache_get "my_cache_key" "/path/to/output"

# 存储缓存
cache_put "my_cache_key" "cache content"

# 存储文件到缓存
cache_put "my_cache_key" "/path/to/file"

# 删除缓存
cache_delete "my_cache_key"

# 清空所有缓存
cache_clear
```

### 哈希计算

```bash
# 计算文件哈希
hash=$(cache_compute_hash "/path/to/file")

# 计算内容哈希
hash=$(cache_compute_content_hash "some content")
```

### 增量构建 API

```bash
# 生成增量构建缓存键
cache_key=$(cache_incremental_key "$source" "$target")

# 检查是否需要重新构建
if cache_needs_rebuild "$source" "$target"; then
    echo "需要重新构建"
fi

# 标记文件已构建
cache_mark_built "$source" "$target"

# 检查文件哈希
if cache_check_file_hash "$file" "$cache_key"; then
    echo "文件未变更"
fi

# 存储文件哈希
cache_store_file_hash "$file" "$cache_key"
```

### 缓存清理

```bash
# 清理过期缓存
cache_clean_expired

# 清理过大缓存
cache_clean_oversized

# 完整清理（过期 + 过大）
cache_cleanup
```

### 缓存统计

```bash
# 获取缓存大小
size=$(cache_get_size)

# 获取缓存条目数
count=$(cache_get_entry_count)

# 获取缓存统计信息
cache_get_stats
```

### 缓存持久化

```bash
# 加载缓存统计
cache_load_stats

# 保存缓存统计
cache_save_stats
```

---

## 最佳实践

### 1. 合理设置缓存大小

```bash
# 小项目：512MB
CACHE_MAX_SIZE=536870912

# 中等项目：1GB（默认）
CACHE_MAX_SIZE=1073741824

# 大型项目：2GB 或更多
CACHE_MAX_SIZE=2147483648
```

### 2. 定期清理缓存

```bash
# 在 CI/CD 中定期清理
build cache cleanup

# 或设置较短的有效期
CACHE_MAX_AGE=86400  # 1 天
```

### 3. 开发环境使用缓存

```bash
# 开发环境：启用缓存，加速构建
build build  # 使用缓存

# CI/CD 环境：禁用缓存，确保一致性
build --no-cache build
```

### 4. 处理缓存失效

当以下情况发生时，缓存会自动失效：

- 源文件被修改
- 缓存条目过期
- 缓存大小超限

### 5. 调试缓存问题

```bash
# 使用详细模式查看缓存命中情况
build -v build

# 输出示例：
# ⚙ 缓存命中: src/Main.java
# ⚙ 缓存未命中: src/NewFile.java
```

---

## 缓存与并行构建

缓存系统与并行构建兼容：

```bash
# 并行构建时，每个文件独立检查缓存
build -j 8 build
```

注意事项：

- 并行构建时缓存检查是线程安全的
- 缓存写入会自动处理并发问题
- 建议在并行构建时使用更快的哈希算法（md5）

---

## 下一步

- [增量构建](../advanced/incremental-build.md) - 深入了解增量构建
- [并行构建](../advanced/parallel-build.md) - 了解并行构建
- [缓存模块 API](../api-reference/cache-api.md) - 缓存 API 参考
