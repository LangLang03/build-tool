# 缓存模块 API 参考

本文档详细介绍 `lib/cache.sh` 模块提供的缓存 API。

---

## 目录

- [模块概述](#模块概述)
- [全局变量](#全局变量)
- [缓存操作](#缓存操作)
- [增量构建](#增量构建)
- [缓存管理](#缓存管理)
- [缓存统计](#缓存统计)

---

## 模块概述

`cache.sh` 提供缓存管理功能：

- 文件哈希缓存
- 增量构建支持
- 缓存过期清理
- 缓存统计

---

## 全局变量

```bash
declare -g CACHE_ENABLED=true        # 是否启用缓存
declare -g CACHE_DIR=""              # 缓存目录
declare -g CACHE_MAX_SIZE=1073741824 # 最大缓存大小（1GB）
declare -g CACHE_MAX_AGE=604800      # 最大有效期（7天）
declare -g CACHE_HASH_ALGO="md5"     # 哈希算法
declare -g CACHE_HITS=0              # 缓存命中数
declare -g CACHE_MISSES=0            # 缓存未命中数
```

---

## 缓存操作

### cache_init

初始化缓存系统。

```bash
cache_init [cache_dir]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| cache_dir | string | 否 | ~/.cache/build-tool | 缓存目录 |

**示例：**

```bash
cache_init
cache_init "/custom/cache/dir"
```

### cache_has

检查缓存是否存在。

```bash
cache_has <key>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| key | string | 是 | 缓存键 |

**返回值：**

- `0` - 缓存存在
- `1` - 缓存不存在

**示例：**

```bash
if cache_has "my_cache_key"; then
    echo "缓存存在"
fi
```

### cache_get

获取缓存内容。

```bash
cache_get <key> [output_file]
```

**参数：**

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| key | string | 是 | - | 缓存键 |
| output_file | string | 否 | - | 输出文件路径 |

**返回值：**

缓存内容（不指定输出文件时）。

**示例：**

```bash
content=$(cache_get "my_cache_key")
cache_get "my_cache_key" "/path/to/output"
```

### cache_put

存储缓存内容。

```bash
cache_put <key> <content_or_file>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| key | string | 是 | 缓存键 |
| content_or_file | string | 是 | 内容或文件路径 |

**示例：**

```bash
cache_put "my_cache_key" "cache content"
cache_put "my_cache_key" "/path/to/file"
```

### cache_delete

删除缓存。

```bash
cache_delete <key>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| key | string | 是 | 缓存键 |

**示例：**

```bash
cache_delete "my_cache_key"
```

### cache_clear

清空所有缓存。

```bash
cache_clear
```

**示例：**

```bash
cache_clear
```

---

## 增量构建

### cache_compute_hash

计算文件哈希。

```bash
cache_compute_hash <file>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| file | string | 是 | 文件路径 |

**返回值：**

文件哈希值。

**示例：**

```bash
hash=$(cache_compute_hash "src/Main.java")
```

### cache_incremental_key

生成增量构建缓存键。

```bash
cache_incremental_key <source> <target>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| source | string | 是 | 源文件路径 |
| target | string | 是 | 目标文件路径 |

**返回值：**

缓存键。

**示例：**

```bash
key=$(cache_incremental_key "src/Main.java" "output/Main.class")
```

### cache_needs_rebuild

检查是否需要重新构建。

```bash
cache_needs_rebuild <source> <target>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| source | string | 是 | 源文件路径 |
| target | string | 是 | 目标文件路径 |

**返回值：**

- `0` - 需要重新构建
- `1` - 不需要重新构建

**示例：**

```bash
if cache_needs_rebuild "$src" "$dest"; then
    # 重新编译
fi
```

### cache_mark_built

标记文件已构建。

```bash
cache_mark_built <source> <target>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| source | string | 是 | 源文件路径 |
| target | string | 是 | 目标文件路径 |

**示例：**

```bash
cache_mark_built "src/Main.java" "output/Main.class"
```

---

## 缓存管理

### cache_enable

启用缓存。

```bash
cache_enable
```

**示例：**

```bash
cache_enable
```

### cache_disable

禁用缓存。

```bash
cache_disable
```

**示例：**

```bash
cache_disable
```

### cache_is_enabled

检查缓存是否启用。

```bash
cache_is_enabled
```

**返回值：**

- `0` - 已启用
- `1` - 已禁用

**示例：**

```bash
if cache_is_enabled; then
    echo "缓存已启用"
fi
```

### cache_set_dir

设置缓存目录。

```bash
cache_set_dir <directory>
```

**参数：**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| directory | string | 是 | 缓存目录路径 |

**示例：**

```bash
cache_set_dir "/tmp/build-cache"
```

### cache_clean_expired

清理过期缓存。

```bash
cache_clean_expired
```

**示例：**

```bash
cache_clean_expired
```

### cache_clean_oversized

清理过大缓存。

```bash
cache_clean_oversized
```

**示例：**

```bash
cache_clean_oversized
```

### cache_cleanup

完整清理（过期 + 过大）。

```bash
cache_cleanup
```

**示例：**

```bash
cache_cleanup
```

---

## 缓存统计

### cache_get_size

获取缓存大小。

```bash
cache_get_size
```

**返回值：**

缓存大小（字节）。

**示例：**

```bash
size=$(cache_get_size)
echo "缓存大小: $size 字节"
```

### cache_get_entry_count

获取缓存条目数。

```bash
cache_get_entry_count
```

**返回值：**

缓存条目数。

**示例：**

```bash
count=$(cache_get_entry_count)
echo "缓存条目: $count"
```

### cache_get_stats

获取缓存统计信息。

```bash
cache_get_stats
```

**示例：**

```bash
cache_get_stats
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

---

## 下一步

- [核心 API](core-api.md) - 核心 API 参考
- [配置模块 API](config-api.md) - 配置 API 参考
