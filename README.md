# github-search 技能

GitHub 项目搜索与分析技能。通过关键词、语言、星标数等条件搜索 GitHub 仓库，返回基本信息、热门度数据，并格式化为可读文本。

## 文件结构

| 文件 | 说明 |
|------|------|
| `github-search-SKILL.md` | 技能定义：参数声明、返回结构、工作流程、错误处理 |
| `scripts/search.sh` | 实际调用 GitHub Search API 的执行脚本 |
| `scripts/format.py` | 将 API 返回的 JSON 格式化为可读文本 |

## 安装

```bash
git clone https://github.com/xZCzdf/jn.git
cd jn
```

本仓库同时是一个可直接使用的技能：将 `github-search-SKILL.md` 与 `scripts/` 放入 `~/.codebuddy/skills/github-search/` 即可被技能系统识别。

## 快速开始

```bash
# 基础搜索
bash scripts/search.sh query:"machine learning"

# 语言过滤
bash scripts/search.sh query:"api server" language:python

# 按星标排序（热门优先）
bash scripts/search.sh query:"web framework" sort:stars order:desc

# 输出原始 JSON（便于管道给其他工具）
bash scripts/search.sh query:"graphql" language:go raw:1
```

## 参数

以 `key:value` 形式传入（值可用引号包裹，值内可含冒号）：

| 参数 | 必填 | 说明 |
|------|------|------|
| `query` | 是 | 搜索关键词，可含高级限定符 |
| `language` | 否 | 编程语言过滤（python, go, rust…） |
| `sort` | 否 | 排序字段：`stars` / `forks` / `updated` |
| `order` | 否 | 排序顺序：`desc`（默认）/ `asc` |
| `per_page` | 否 | 每页返回条数（默认 30，最大 100） |
| `page` | 否 | 页码 |
| `raw` | 否 | 置 `1` 输出原始 JSON |
| `token` | 否 | 直接传入 GitHub PAT（也可用环境变量） |

## 提高速率限制（推荐）

GitHub Search API 未认证仅 **60 次/小时**，配置令牌后提升到 **5000 次/小时**：

```bash
export GITHUB_TOKEN=ghp_xxxxxxxxxxxx
bash scripts/search.sh query:"django" language:python sort:stars order:desc
```

也可在参数内传入：`bash scripts/search.sh query:"django" token:ghp_xxx`

## 高级搜索限定符

可直接写进 `query` 进行精确过滤（脚本原样拼接到搜索串 `q`，无需额外配置）：

| 限定符 | 含义 | 示例 |
|--------|------|------|
| `stars:>N` | 星标 > N | `stars:>1000` |
| `stars:N1..N2` | 星标区间 | `stars:1000..5000` |
| `forks:>N` | fork > N | `forks:>100` |
| `pushed:>YYYY-MM-DD` | 此后有推送 | `pushed:>2024-01-01` |
| `created:>YYYY-MM-DD` | 此后创建 | `created:>2023-01-01` |
| `language:xxx` | 编程语言 | `language:rust` |
| `user:xxx` | 某用户仓库 | `user:torvalds` |
| `org:xxx` | 某组织仓库 | `org:github` |
| `topic:xxx` | 带主题标签 | `topic:machine-learning` |
| `archived:false` | 排除已归档 | `archived:false` |

组合示例：

```bash
# 近一年更新、星标 > 5000 的 Rust 终端项目（TUI）
bash scripts/search.sh query:"tui stars:>5000 pushed:>2024-01-01 language:rust" sort:stars order:desc

# 某用户创建、星标过千的仓库
bash scripts/search.sh query:"user:torvalds stars:>1000"

# 机器学习主题、2023 年后创建、星标区间
bash scripts/search.sh query:"topic:machine-learning created:>2023-01-01 stars:500..5000" sort:stars order:desc
```

## 返回数据结构

每个搜索结果包含：`full_name`、`description`、`language`、`stars`、`forks`、`updated`、`html_url`、`score`。

## 注意事项

- 受 GitHub Search API 速率限制，建议配置 `GITHUB_TOKEN`。
- 搜索结果受 GitHub 算法影响，可能随时间变化。
- 仅做搜索，不修改任何仓库。

## 技术细节

- API 端点：`https://api.github.com/search/repositories`
- 依赖：`curl`、`python3`（用于 URL 编码与 JSON 格式化）
