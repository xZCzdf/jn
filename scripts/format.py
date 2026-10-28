#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""读取 GitHub Search API 返回的 JSON（来自 stdin），格式化为可读文本。"""
import json
import sys


def main():
    try:
        data = json.load(sys.stdin)
    except Exception as e:  # noqa: BLE001
        print("解析响应失败:", e, file=sys.stderr)
        sys.exit(1)

    total = data.get("total_count", 0)
    items = data.get("items", [])
    print(f"共匹配 {total} 个仓库，显示前 {len(items)} 个：\n")
    for it in items:
        print(f"★ {it.get('full_name')}")
        desc = it.get("description") or "(无描述)"
        print(f"  描述 : {desc}")
        print(
            f"  语言 : {it.get('language')}   "
            f"⭐ {it.get('stargazers_count')}   "
            f"🍴 {it.get('forks_count')}   "
            f"更新: {it.get('updated_at')}"
        )
        print(f"  链接 : {it.get('html_url')}")
        print()


if __name__ == "__main__":
    main()
