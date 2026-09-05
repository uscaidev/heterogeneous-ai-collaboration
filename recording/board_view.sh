#!/bin/sh
# 게시판 실시간 표시 (시연용)
f="${1:-scene/HANDOFF.md}"
while true; do
  clear
  echo "  ┌─────────────────────────────────────────────┐"
  echo "  │  HANDOFF.md  —  공용 게시판 (실시간)        │"
  echo "  └─────────────────────────────────────────────┘"
  echo
  sed -n '/## 대전표/,$p' "$f" | sed 's/^/  /'
  echo
  echo "  ─────────────────────────────────────────────"
  echo "  갱신: $(date +%H:%M:%S)"
  sleep 1
done
