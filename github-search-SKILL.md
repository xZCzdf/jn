---
name: github-search
description: GitHub 项目搜索与分析技能。支持通过关键词、语言、星标数等条件搜索GitHub项目，并获取项目基本信息、热门度数据和分析报告。调用 GitHub Search API，支持语言/排序/星标筛选，可携带 PAT 提高速率限制。
arguments:
  - name: query
    description: 搜索查询关键词
    required: true
  - name: language
    description: 编程语言过滤（如 python, javascript, go 等）
    required: false
  - name: sort
    description: 排序方式（stars, forks, updated）
    required: false
  - name: order
    description: 排序顺序（desc, asc）
    required: false
---

# GitHub 项目搜索技能

调用 GitHub Search API 搜索仓库，返回匹配项目的基本信息、热门度数据，并格式化为可读文本。

## 使用方法（实际调用）

本技能通过 `scripts/search.sh` 实际执行，参数为 `key:value` 形式（值可用引号包裹，值内可含冒号）：

```bash
# 基础搜索
bash scripts/search.sh query:"machine learning"

# 语言过滤
bash scripts/search.sh query:"api server" language:python

# Star 数量排序（热门优先）
bash scripts/search.sh query:"web framework" sort:stars order:desc

# 更新时间排序（最新优先）
bash scripts/search.sh query:"react component" sort:updated
```

### 提高速率限制（推荐）

未认证调用仅 **60 次/小时**。设置令牌后可提升到 5000 次/小时：

```bash
# 方式一：环境变量
export GITHUB_TOKEN=ghp_xxxxxxxxxxxx
bash scripts/search.sh query:"django" language:python sort:stars order:desc

# 方式二：参数内传入
bash scripts/search.sh query:"django" language:python token:ghp_xxxxxxxxxxxx
```

### 获取原始 JSON

追加 `raw:1` 可输出原始 JSON（便于二次处理或管道给其他工具）：

```bash
bash scripts/search.sh query:"graphql" language:go raw:1
```

## 返回数据结构

每个搜索结果包含：

- `full_name` - 仓库全名（owner/repo）
- `description` - 仓库描述
- `language` - 主要编程语言
- `stars` - 星标数（`stargazers_count`）
- `forks` - 分叉数（`forks_count`）
- `updated` - 最后更新时间（`updated_at`）
- `html_url` - GitHub 链接
- `score` - 搜索相关性评分

## 使用示例

### 搜索热门 Python 项目
```bash
bash scripts/search.sh query:"django" language:python sort:stars order:desc
```

### 搜索最新的 JavaScript 项目
```bash
bash scripts/search.sh query:"tailwindcss" sort:updated order:desc
```

### 搜索特定语言的项目
```bash
bash scripts/search.sh query:"graphql" language:go
```

## 高级搜索限定符

除了 `query` 关键词和 `language:` 参数，GitHub 还支持大量**限定符（qualifier）**，可直接写进 `query` 里进行精确过滤。常用如下：

| 限定符 | 含义 | 示例 |
|--------|------|------|
| `stars:>N` | 星标数大于 N | `stars:>1000` |
| `stars:N1..N2` | 星标数区间 | `stars:1000..5000` |
| `forks:>N` | fork 数大于 N | `forks:>100` |
| `pushed:>YYYY-MM-DD` | 此后有更新/推送 | `pushed:>2024-01-01` |
| `created:>YYYY-MM-DD` | 此后创建 | `created:>2023-01-01` |
| `language:xxx` | 编程语言（也可用 `language:` 参数） | `language:rust` |
| `user:xxx` | 某用户名下仓库 | `user:torvalds` |
| `org:xxx` | 某组织名下仓库 | `org:github` |
| `topic:xxx` | 带某主题标签 | `topic:machine-learning` |
| `archived:false` | 排除已归档仓库 | `archived:false` |

### 组合示例

```bash
# 近一年更新、星标 > 5000 的 Rust 终端项目（TUI）
bash scripts/search.sh query:"tui stars:>5000 pushed:>2024-01-01 language:rust" sort:stars order:desc

# 某用户创建、星标过千的仓库
bash scripts/search.sh query:"user:torvalds stars:>1000"

# 机器学习主题、2023 年后创建、星标区间
bash scripts/search.sh query:"topic:machine-learning created:>2023-01-01 stars:500..5000" sort:stars order:desc
```

> 限定符之间用空格分隔，整体作为 `query` 的值（建议用引号包裹）。脚本会原样拼接到 GitHub 搜索串 `q` 中，无需额外配置。

## 工作流程

1. **参数解析**：解析 `query / language / sort / order / per_page / page / token / raw` 等 `key:value` 参数，校验 `query` 非空。
2. **构造查询**：将 `query` 与可选的 `language:` 限定符拼接为 GitHub 搜索串 `q`，并按需附加 `sort / order / per_page / page`。
3. **调用 API**：由 `scripts/search.sh` 请求 `https://api.github.com/search/repositories`，自动附带 `Authorization: Bearer <token>`（若提供）。
4. **格式化输出**：由 `scripts/format.py` 解析 JSON，输出「仓库名 / 描述 / 语言 / ⭐ / 🍴 / 更新时间 / 链接」的可读文本；`raw:1` 时直接输出原始 JSON。

## 注意事项

- GitHub Search API 有请求频率限制，未认证仅 60 次/小时，建议配置 `GITHUB_TOKEN`。
- 搜索结果受 GitHub 算法影响，可能随时间变化。
- 某些高级搜索语法需要熟悉 GitHub 的搜索语法（如 `stars:>1000`、`pushed:>2024-01-01` 等可直接写入 `query`）。
- 结果可能受地区和网络条件影响。

## 技术细节

- 通过 GitHub Search API `https://api.github.com/search/repositories` 进行搜索。
- 支持的排序字段：`stars`, `forks`, `updated`；排序顺序：`desc`（默认）, `asc`。
- 默认每页返回 30 个结果，可通过 `per_page` 调整（最大 100）。
- 脚本依赖：`curl`、`python3`（仅用于 URL 编码与 JSON 格式化）。

## 错误处理

- 当 `query` 为空时返回错误提示并退出。
- 当 GitHub API 返回非 200（如 403 速率限制、404 等）时，打印 HTTP 状态码、响应摘要与针对性建议（如配置令牌）。
- 网络请求失败时提供友好的错误信息并建议重试。
