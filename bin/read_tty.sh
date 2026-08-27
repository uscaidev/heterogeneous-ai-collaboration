#!/bin/sh
# 사용: read_tty.sh /dev/ttys001 [chars=600] — 해당 탭 화면의 마지막 N자
[ $# -ge 1 ] || { echo "usage: $0 /dev/ttysNNN [chars]" >&2; exit 2; }
osascript - "$1" "${2:-600}" <<'AS'
on run argv
  set ttyName to item 1 of argv
  set n to (item 2 of argv) as integer
  tell application "Terminal"
    repeat with w in windows
      repeat with t in tabs of w
        if (tty of t) is ttyName then
          set h to history of t
          set L to length of h
          if L > n then return text (L - n) thru L of h
          return h
        end if
      end repeat
    end repeat
  end tell
  return "not found " & ttyName
end run
AS
