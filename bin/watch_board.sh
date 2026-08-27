#!/bin/sh
# 사용: watch_board.sh HANDOFF.md "^- T-" — 상태 보고 줄 변경을 감시해 출력
f="${1:-HANDOFF.md}"; pat="${2:-^- }"; prev=""
while true; do
  cur=$(grep -E "$pat" "$f" 2>/dev/null)
  [ "$cur" != "$prev" ] && echo "$cur" && prev="$cur"
  sleep 2
done
