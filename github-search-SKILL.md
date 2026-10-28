---
name: github-search
description: GitHub 项目搜索与分析技能。支持通过关键词、语言、星标数等条件搜索GitHub项目，并获取项目基本信息、热门度数据和分析报告。
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

自动执行GitHub仓库搜索，返回项目匹配结果和分析数据。

## 搜索功能

### 基础搜索
使用关键词搜索GitHub项目：

```bash
github-search query:"machine learning"
```

### 高级筛选

#### 语言过滤
```bash
github-search query:"api server" language:python
```

#### Star 数量筛选
```bash
github-search query:"web framework" sort:stars order:desc
```

#### 更新时间筛选
```bash
github-search query:"react component" sort:updated
```

## 返回数据结构

每个搜索结果包含：

- `full_name` - 仓库全名（owner/repo）
- `description` - 仓库描述
- `language` - 主要编程语言
- `stars` - 星标数
- `forks` - 分叉数
- `updated` - 最后更新时间
- `html_url` - GitHub链接
- `score` - 搜索相关性评分

## 使用示例

### 搜索热门 Python 项目
```bash
github-search query:"django" language:python sort:stars order:desc
```

### 搜索最新的 JavaScript 项目
```bash
github-search query:"tailwindcss" sort:updated order:desc
```

### 搜索特定语言的项目
```bash
github-search query:"graphql" language:go
```

## 工作流程

### 1. 参数解析
- 解析用户提供的搜索查询参数
- 验证查询关键词非空
- 确定可选的语言、排序和排序顺序参数

### 2. GitHub API 搜索
- 使用 GitHub Search API 构建搜索查询字符串
- 发送搜索请求并获取原始结果
- 解析返回的 JSON 数据提取关键字段

### 3. 数据整理
- 将原始 API 结果转换为统一的数据结构
- 按相关性和筛选条件对结果进行排序
- 移除不可用或重复的条目

### 4. 结果展示
- 格式化搜索结果为可读的文本输出
- 包含关键信息：项目名称、描述、语言、星标数、链接
- 提供分页信息和结果计数

## 注意事项

- GitHub Search API 有请求频率限制，请合理间隔搜索请求
- 搜索结果受 GitHub 算法影响，可能随时间变化
- 某些高级搜索语法需要熟悉 GitHub 的搜索语法
- 建议在需要时使用 GitHub 个人访问令牌提高速率限制
- 结果可能受地区和网络条件影响

## 技术细节

- 通过 GitHub Search API `https://api.github.com/search/repositories` 进行搜索
- 支持的排序字段：stars, forks, updated
- 支持的排序顺序：desc (默认), asc
- 默认每页返回最多 30 个结果
- 支持通过 `per_page` 参数调整每页结果数（最大 100）

## 错误处理

- 当搜索关键词为空时返回错误提示
- 当 GitHub API 返回错误时（如 403 速率限制、404 等）返回相应错误信息
- 网络请求失败时提供友好的错误信息并建议重试