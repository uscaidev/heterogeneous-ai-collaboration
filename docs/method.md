# 터미널 간 AI 에이전트 통신 — Claude Code ↔ Codex CLI 실측 방법

> 한 대의 Mac에서 서로 다른 회사의 AI 코딩 에이전트(Anthropic Claude Code, OpenAI Codex CLI)를 **서로 대화시키고 협업시키는** 방법. 공식 API·플러그인 없이, 운영체제가 이미 주는 것(터미널·파일·AppleScript)만으로 됨. 2026-08-27 실측.

## 0. 요약

| 채널 | 방향 | 지연 | 도구 | 비고 |
|---|---|---|---|---|
| ① 세션 메시지 | Claude ↔ Claude | 즉시 | `ListAgents`, `SendMessage` | Claude Code 내장. Codex엔 없음 |
| ② 터미널 타이핑 | Claude → Codex | 즉시 | AppleScript `do script … in tab` | **Enter 별도 전송 필요** |
| ③ 화면 읽기 | Codex → Claude | 폴링 | AppleScript `history of tab` | 보조. Codex가 화면에 쓴 것을 읽음 |
| ④ 게시판 파일 | 전원 ↔ 전원 | 초 단위 | `HANDOFF.md` + 파일 감시 | 유일한 **공용·영구** 채널 |

핵심 통찰: **파일이 프로토콜이다.** 서로 다른 도구는 메시지 API를 공유하지 않지만 같은 디스크를 공유한다. 지시는 ②로 밀어넣고, 응답은 ④로 받는다.

## 1. 왜 필요한가

- Claude Code는 같은 기기의 다른 Claude 세션과는 메시지를 주고받지만(①), Codex는 그 목록에 나타나지 않는다.
- Codex CLI는 `AGENTS.md`를 자동으로 읽고, Claude Code는 `CLAUDE.md`를 자동으로 읽는다 — 즉 둘 다 **파일은 읽는다**.
- 사람이 두 터미널 사이에서 복사·붙여넣기를 하는 것이 병목이었다. 이걸 없애는 것이 목표.

## 2. 참가자 배치 (실측 환경)

```
Terminal.app
├─ ttys000  claude   (claude-13)  관리자 — 지시·기록
├─ ttys001  codex    (GPT ①)      담당 T-2
├─ ttys002  codex    (GPT ②)      담당 T-3
└─ ttys003  claude   (claude-f0)  담당 T-1
```
모두 같은 프로젝트 디렉터리에서 실행. 환경: macOS 26.6.2, Terminal.app 2.15, Claude Code 2.1.247, Codex CLI 0.150.1 (gpt-5.6-sol).

## 3. 채널별 레시피

### ① Claude ↔ Claude — 세션 메시지
```
ListAgents                       → 동료 세션 이름 (예: claude-f0)
SendMessage(to="claude-f0", message="…", notify_when_idle=true)
```
상대 세션이 다음 턴에 `<cross-session-message>`로 받는다. 회신도 같은 방법. `notify_when_idle`로 상대가 멈추면 알림.

### ② Claude → Codex — 터미널에 직접 타이핑
1. Codex가 떠 있는 tty 찾기:
   ```sh
   ps -eo pid,tty,command | grep -E "bin/codex$"
   #  95839 ttys001 …/bin/codex
   #  95896 ttys002 …/bin/codex
   ```
2. Terminal.app 탭을 tty로 찾아 텍스트를 넣는다:
   ```applescript
   on sendTo(ttyName, msg)
     tell application "Terminal"
       repeat with w in windows
         repeat with t in tabs of w
           if (tty of t) is ttyName then
             do script msg in t      -- 입력창에 타이핑됨
             delay 0.5
             do script "" in t       -- ★ Enter. 이게 없으면 제출 안 됨
             return "sent"
           end if
         end repeat
       end repeat
     end tell
   end sendTo
   sendTo("/dev/ttys001", "claude-13이다. HANDOFF.md T-2 줄을 …로 바꿔줘.")
   ```
   Codex 입장에서는 사용자가 타이핑한 것과 구분되지 않는다. macOS가 최초 1회 "Terminal 제어 허용" 권한을 묻는다.

**함정 (실측)**: `do script`가 붙이는 줄바꿈을 Codex TUI가 제출로 받지 않는다. 첫 시도에서 메시지가 입력창(`›`)에만 남아 있었고, 빈 `do script ""`를 한 번 더 보내자 제출됐다.

### ③ Codex → Claude — 화면 읽기 (보조)
```applescript
tell application "Terminal" to repeat with w in windows
  repeat with t in tabs of w
    if (tty of t) is "/dev/ttys001" then
      set h to history of t
      log text ((length of h) - 600) thru (length of h) of h   -- 마지막 600자
    end if
  end repeat
end repeat
```
Codex가 "Working…"인지, 무슨 답을 했는지 확인할 수 있다. 정형 응답이 필요하면 ④를 쓴다.

### ④ 전원 공용 — `HANDOFF.md` 작업 게시판
```markdown
# HANDOFF — 작업 게시판 · 사이클 N (관리: Claude claude-13)
## 게시판 공통 규칙
1. 자기 담당 작업 외 파일을 건드리지 않는다.  2. 키는 어디에도 기록하지 않는다. …
## 작업
### T-2 — C·D 사건 실행 [담당: GPT ①]   전용: 결과/C_*, 결과/D_*
### T-3 — 심사지침 진단     [담당: GPT ②]   전용: 지침/심사_강도보정_v2.md
## 상태 보고
- T-2 (GPT ①): TODO
- T-3 (GPT ②): TODO
```
- 작업마다 **담당 + 전용 경로**를 못박는다 → 셋이 동시에 써도 충돌 없음.
- 담당자는 `## 상태 보고`의 **자기 줄 한 줄**만 갱신한다 (DONE/진행/막힘 — 경로·수치).
- `AGENTS.md`(Codex)·`CLAUDE.md`(Claude)에는 "게시판 먼저 읽고 지정 담당만"이라고만 적는다.
- 관리자는 그 줄을 감시한다:
  ```sh
  prev=""; while true; do cur=$(grep -E "^- T-[23]" HANDOFF.md)
    [ "$cur" != "$prev" ] && echo "$cur" && prev="$cur"; sleep 2; done
  ```

## 4. 실측 기록 — "손 들어 보세요"

| 시각 | 채널 | 사건 |
|---|---|---|
| 16:59 | ① | claude-13 → claude-f0: T-1 지시 |
| 17:00 | ① | claude-f0 → claude-13: "막힘 — API 키 없음" (추측으로 넣지 않음) |
| 17:05 | ④ | HANDOFF를 게시판 형식으로 개편, T-1~T-4 배정 |
| 17:07 | ② | claude-13 → GPT ①·②: "손 들어! 상태 보고 네 줄을 `🙋 손 듦`으로 바꿔라" → **입력창에만 남음** |
| 17:08 | ② | 빈 줄 재전송 → 제출. GPT ①: "요청한 한 줄만 확인해 정확히 바꾸겠습니다" |
| 17:09 | ④ | `T-2 (GPT ①): 🙋 손 듦 — claude-13 호출 확인, 지시 대기` |
| 17:09 | ④ | `T-3 (GPT ②): 🙋 손 듦 — …` → 감시 스크립트 `BOTH_RAISED` |
| 17:12 | ①② | 사용자 지시로 전원 작업 중지 (방향 전환: 이 방법 자체를 기록) |

관찰: Codex는 지시문에 "그 외 파일은 건드리지 말고"를 넣자 정확히 한 줄만 고쳤다. **편집 범위를 지시문에 명시하는 것이 곧 안전장치**다.

## 5. 재현 절차 (처음부터)
1. 프로젝트 폴더에 `HANDOFF.md`(게시판), `AGENTS.md`, `CLAUDE.md`(둘 다 "HANDOFF 먼저") 작성.
2. Terminal.app 탭을 여러 개 열고 각각 `claude` 또는 `codex` 실행 (같은 폴더).
3. 관리자 Claude에서 `ps`로 Codex tty 확인, `ListAgents`로 Claude 동료 확인.
4. 지시: Claude에는 `SendMessage`, Codex에는 AppleScript(메시지 + 빈 줄).
5. 응답: 게시판 상태 보고 줄을 감시. 필요하면 `history of tab`으로 화면 확인.
6. 끝나면 교신 타임라인을 `협업로그/`에 남긴다.

## 6. 한계·미검증
- Terminal.app 전용. iTerm2는 `write text`, tmux는 `send-keys`로 대체 가능(미검증).
- Codex → Claude 직접 push 채널은 없음. Codex가 셸에서 `claude`를 호출하거나 파일을 쓰는 방식이 후보(미검증).
- 타이핑 채널은 Codex가 입력 대기 중일 때만 안전. "Working…" 중에 보내면 큐에 쌓이거나 무시될 수 있음(미검증).
- 보안: AppleScript 권한을 가진 프로세스는 어느 탭에나 명령을 넣을 수 있다. 신뢰하는 로컬 세션에서만.

## 7. 왜 이게 재미있는가
서로 다른 벤더의 에이전트가 **공통 프로토콜 없이** 협업했다. 필요했던 건 세 가지뿐 — 같은 디스크, 같은 터미널 앱, 그리고 "누가 어느 줄을 고치는가"에 대한 합의(게시판). 멀티에이전트 프레임워크가 하는 일의 상당 부분이 사실은 이 합의라는 점이 시사점이다.
