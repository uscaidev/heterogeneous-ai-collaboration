#!/bin/sh
# 사용: handoff_init.sh [대상폴더]  — 게시판·포인터 파일 3개를 프로젝트에 복사
here=$(cd "$(dirname "$0")/.." && pwd); dst="${1:-.}"
for f in HANDOFF.md AGENTS.md CLAUDE.md; do
  [ -e "$dst/$f" ] && { echo "skip $f (exists)"; continue; }
  cp "$here/examples/$f" "$dst/$f" && echo "created $dst/$f"
done
