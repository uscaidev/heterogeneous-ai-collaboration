#!/bin/sh
# 사용: send_to_tty.sh /dev/ttys001 "메시지"  — Terminal.app 탭(tty)에 메시지 타이핑 + Enter
[ $# -ge 2 ] || { echo "usage: $0 /dev/ttysNNN \"message\"" >&2; exit 2; }
osascript - "$1" "$2" <<'AS'
on run argv
  set ttyName to item 1 of argv
  set msg to item 2 of argv
  tell application "Terminal"
    repeat with w in windows
      repeat with t in tabs of w
        if (tty of t) is ttyName then
          do script msg in t
          delay 0.5
          do script "" in t   -- Codex TUI는 이 빈 줄이 있어야 제출됨
          return "sent " & ttyName
        end if
      end repeat
    end repeat
  end tell
  return "not found " & ttyName
end run
AS
