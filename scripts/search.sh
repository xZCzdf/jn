#!/usr/bin/env bash
#
# github-search 技能的实际执行脚本
# 调用 GitHub Search API 搜索仓库，并格式化输出结果。
# 用法见 SKILL.md。
#
set -euo pipefail

# 脚本所在目录（用于定位 format.py）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------- 默认值 ----------
QUERY=""
LANGUAGE=""
SORT=""
ORDER=""
PER_PAGE="30"
PAGE="1"
TOKEN="${GITHUB_TOKEN:-}"

# ---------- 解析 key:value 参数（支持引号，值里可含冒号） ----------
for arg in "$@"; do
  IFS=: read -r key val <<< "$arg"
  # 去掉值两端可能存在的引号
  val="${val%\"}"; val="${val#\"}"
  val="${val%\'}"; val="${val#\'}"
  case "$key" in
    query)    QUERY="$val" ;;
    language) LANGUAGE="$val" ;;
    sort)     SORT="$val" ;;
    order)    ORDER="$val" ;;
    per_page) PER_PAGE="$val" ;;
    page)     PAGE="$val" ;;
    token)    TOKEN="$val" ;;
    raw)      RAW="1" ;;
    *)        echo "未知参数: $key" >&2 ;;
  esac
done

if [ -z "$QUERY" ]; then
  echo "错误：缺少必填参数 query。示例：bash search.sh query:\"machine learning\"" >&2
  exit 1
fi

# ---------- 构造查询字符串 q ----------
Q="$QUERY"
if [ -n "$LANGUAGE" ]; then
  Q="$Q language:$LANGUAGE"
fi

# URL 编码（交由 python3 处理，避免特殊字符破坏请求）
Q_ENC=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$Q")

URL="https://api.github.com/search/repositories?q=${Q_ENC}"
[ -n "$SORT" ]     && URL="${URL}&sort=${SORT}"
[ -n "$ORDER" ]    && URL="${URL}&order=${ORDER}"
URL="${URL}&per_page=${PER_PAGE}&page=${PAGE}"

# ---------- 请求头 ----------
HEADERS=(-H "Accept: application/vnd.github+json" -H "User-Agent: github-search-skill")
if [ -n "$TOKEN" ]; then
  HEADERS+=(-H "Authorization: Bearer ${TOKEN}")
fi

# ---------- 调用 API（附带 HTTP 状态码） ----------
RESP=$(curl -sS -w $'\n__HTTP_STATUS__:%{http_code}' "${HEADERS[@]}" "$URL") || {
  echo "网络请求失败，请检查网络连接后重试。" >&2
  exit 1
}
HTTP_STATUS=$(printf '%s\n' "$RESP" | sed -n 's/.*__HTTP_STATUS__:\([0-9]*\)$/\1/p')
BODY=$(printf '%s\n' "$RESP" | sed '/__HTTP_STATUS__:/d')

# ---------- 错误处理 ----------
if [ "$HTTP_STATUS" != "200" ]; then
  echo "GitHub API 返回错误 (HTTP ${HTTP_STATUS})：" >&2
  printf '%s\n' "$BODY" | head -c 600 >&2
  echo "" >&2
  if [ "$HTTP_STATUS" = "403" ] || [ "$HTTP_STATUS" = "429" ]; then
    echo "提示：很可能是触发了速率限制（未认证仅 60 次/小时）。" >&2
    echo "建议设置环境变量 GITHUB_TOKEN 或在参数里传 token:xxxx 提高额度。" >&2
  fi
  exit 1
fi

# ---------- 原始 JSON 模式 ----------
if [ "${RAW:-}" = "1" ]; then
  printf '%s\n' "$BODY"
  exit 0
fi

# ---------- 格式化输出 ----------
printf '%s\n' "$BODY" | python3 "${SCRIPT_DIR}/format.py"
