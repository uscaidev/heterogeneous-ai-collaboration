#!/bin/sh
# 이 Mac에 떠 있는 에이전트 CLI와 tty
ps -eo pid,etime,tty,command | grep -E "(bin/codex|bin/claude|[ /]claude|[ /]codex|gemini)$" | grep -v grep | awk '{print $1, $2, $3, $NF}'
