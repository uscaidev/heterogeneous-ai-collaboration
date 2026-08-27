# New Communication with AI Agents

**터미널 두 개로 만드는 이기종 AI 에이전트 협업 — 기술 노트**

> Claude Code와 Codex CLI는 서로 말을 못 한다. 그런데 같은 Mac에 떠 있다. 그래서 **터미널에 대신 타이핑하고, 마크다운 파일 한 장을 게시판으로 쓰게** 했더니 — 둘이 손을 들고, 가위바위보를 하고, 시킨 줄만 정확히 고쳤다. 이 노트는 그 방법과 실측, 그리고 뭘 하면 안 되는지에 대한 기록이다.

*English: A technical note on making heterogeneous interactive coding agents (Anthropic Claude Code, OpenAI Codex CLI) talk to each other on one machine with zero extra software — AppleScript typing into the other agent's terminal (push) plus a Markdown "bulletin board" file with a one-line-per-agent status protocol (pull). Includes copy-paste scripts, measured results, a reproducible failure, and honest limits. Korean throughout; scripts are language-agnostic.*

---

## 0. 30초 요약

| 채널 | 방향 | 수단 | 성질 |
|---|---|---|---|
| L1 세션 메시지 | Claude ↔ Claude | Claude Code 내장 `ListAgents` / `SendMessage` | 즉시·양방향. Codex엔 없음 |
| L2 터미널 타이핑 | Claude → Codex | `bin/send_to_tty.sh` (AppleScript `do script … in tab`) | push, 즉시. **Enter를 따로 보내야 함** |
| L2' 화면 읽기 | Codex → Claude | `bin/read_tty.sh` (`history of tab`) | 보조 pull |
| L3 게시판 파일 | 전원 ↔ 전원 | `HANDOFF.md` + `bin/watch_board.sh` | 유일한 공용·영구 채널. 초 단위 |

**한 줄 원리**: 서로 다른 도구는 메시지 API를 공유하지 않지만 **디스크와 터미널 앱은 공유한다.** 지시는 L2로 밀어넣고, 응답은 L3로 받는다.

## 1. 왜 `codex exec` / `claude -p` 대신 이걸 쓰나

서브프로세스로 새로 띄우면 컨텍스트가 0에서 시작한다. 이 방식의 **유일한 진짜 장점**은 30분째 프로젝트를 파고 있는 대화형 세션에 그대로 말을 건다는 것 — 세션이 자산이다. 그 외 모든 면(속도·전달 보장·권한 강제)에서는 서브프로세스가 낫다. §6을 먼저 읽고 결정하라.

## 2. 레시피 (5분)

**준비**: macOS · Terminal.app · 같은 프로젝트 폴더에서 탭마다 `claude` 또는 `codex` 실행. 최초 1회 macOS가 "Terminal 제어 허용"을 묻는다.

```sh
git clone https://github.com/uscaidev/new-communication-with-ai-agents
cd new-communication-with-ai-agents

bin/list_agents.sh                       # 어느 tty에 누가 떠 있나
#  95839 ttys001 …/bin/codex
#  95959 ttys003 claude

bin/handoff_init.sh ~/my-project          # 게시판(HANDOFF.md)·AGENTS.md·CLAUDE.md 복사
# → HANDOFF.md의 작업 절에 [담당: GPT ①] 과 전용 경로를 적는다

bin/send_to_tty.sh /dev/ttys001 "HANDOFF.md 읽고 너는 GPT ①이다. T-2를 수행하고 상태 보고 네 줄을 갱신해."
bin/watch_board.sh ~/my-project/HANDOFF.md "^- T-"   # 상태 보고 줄이 바뀌면 출력
bin/read_tty.sh /dev/ttys001 600          # Codex 화면 마지막 600자 (Working…? 답변?)
```

**게시판 규약 (L3)** — `examples/HANDOFF.md`
1. 작업마다 `[담당: X]` + **전용 경로** → 여럿이 동시에 써도 충돌 없음.
2. 담당자는 `## 상태 보고`의 **자기 줄 한 줄**만 갱신 (`DONE/진행/막힘 — 경로·수치`).
3. 키·비밀은 어디에도 기록 금지. 막히면 `막힘 — 사유` 쓰고 정지.
4. `AGENTS.md`(Codex 자동 로드)·`CLAUDE.md`(Claude 자동 로드)엔 "게시판 먼저"만.

**핵심 한 줄** (`bin/send_to_tty.sh`의 전부):
```applescript
do script msg in t     -- 입력창에 타이핑
delay 0.5
do script "" in t      -- ★ Enter. 없으면 Codex 입력창에 글자만 남는다
```

## 3. 실측 결과지 (2026-08-27, 1세션)

구성: Claude 관리자 1 + Claude 담당 1 + Codex 2, Terminal.app 탭 4개, 같은 폴더.

| 실험 | 결과 | 비고 |
|---|---|---|
| E1 호출–응답 "손 들어" ×2회 | **2/2**, 약 10초 | 1회차 첫 전송은 미제출 → 빈 줄 재전송 후 성공 |
| E2 삼자 동시 기록 (가위바위보) | 충돌·유실 **0** | 관리자 가위(먼저 봉인) / GPT ① 바위 / GPT ② 보 → 비김 |
| E3 편집 범위 준수 ("그 외 파일 건드리지 마") | **3/3** | 매번 요청된 한 줄만 변경, `git status` 확인 |
| 부수: L1 동종 채널 | 담당 Claude가 "API 키 없음 — 추측 투입 안 함" **자발 회신** | L2·L3에 없는 push-back |
| 실패: Enter 미제출 | 재현·우회 완료 | `do script` 줄바꿈을 Codex TUI가 제출로 안 받음 |

원기록: `docs/log-2026-08-27.md`. 방법 상세: `docs/method.md`.

## 4. 이걸로 뭘 하면 좋은가

세션 컨텍스트가 중요하고, 느려도 되고, 실패하면 사람이 보면 되는 일.

| | 활용 | 게시판 한 줄 예 |
|---|---|---|
| ★★★ | **교차 벤더 코드 리뷰** — Claude가 짠 걸 Codex가, Codex가 짠 걸 Claude가. 같은 모델은 자기 가정을 못 본다 | `R-1 chain.py 리뷰 [담당: GPT ①] 전용: docs/review_chain.md` |
| ★★★ | **심판 분리** — 작성 세션과 채점 세션이 서로의 컨텍스트를 모름 (블라인드 평가) | `J-1 결과 7건 채점 [담당: claude-f0]` |
| ★★★ | **막힌 세션 구출** — 40분째 도는 세션에 다른 벤더의 대안 하나 넣어주기 | `send_to_tty.sh ttys003 "다른 접근: …"` |
| ★★ | **두 번째 의견** — 설계 결정마다 "GPT는?" | `Q-3 캐시 전략 의견 [담당: GPT ②]` |
| ★★ | **병렬 작업반** — 같은 과제를 두 벤더에 동시에, 결과 비교 | `T-5a [Claude] / T-5b [GPT ①]` |
| ★★ | **장시간 작업 감시** — `read_tty.sh`로 10분마다 화면 읽고 이상 시 경고 | — |
| ★★ | **컨텍스트 릴레이** — 한계 근처 세션이 인수인계서 쓰고 다른 세션 깨움 | `H-1 인수인계 [담당: 다음 세션]` |
| ★ | 에이전트 토론 / 해시 봉인 가위바위보 / 텔레폰 게임 | 데모용 |

## 5. 기존 에이전트 구조와 뭐가 다른가

```
오케스트레이터–워커 (서브에이전트, AutoGen, CrewAI)     연합 블랙보드 (이 노트)
  [관리자] ─spawn→ [워커] (자식, 같은 프로세스·벤더)       [Claude] [Claude] [Codex] [Codex] (이웃, 각자 독립)
  관리자가 만들고 관리자가 죽임                               아무도 아무를 안 만듦. 관리자가 죽어도 워커는 삶
  상태 = 메모리 객체                                         상태 = 디스크의 마크다운 (사람이 읽음, git이 버전함)
  조정 = 코드 (그래프·라우터)                                조정 = 자연어 문서 (벤더 무관, 강제력 없음)
  프로토콜 연합(A2A)은 각자 서버로 노출돼야 참여               에이전트를 그대로 두고 사람 인터페이스 위에 얹음
```

정직한 자리매김: **1970년대 블랙보드 아키텍처에서 지식원(KS)을 LLM 세션으로, 스케줄러를 LLM + 자연어 규칙으로 바꾼 것.** 새로운 부분은 통신 기술이 아니라 "부품이 말을 알아듣는다"는 것이다.

## 6. 하면 안 되는 것

- **프로덕션 오케스트레이션** — 전달 확인·순서·재시도 없음. Enter 미제출이 그 증거.
- **보안 격리 용도** — 반대다. AppleScript 권한을 가진 프로세스는 어느 탭에나 명령을 넣을 수 있다. 신뢰된 로컬 세션에서만.
- **권한 경계를 지시문에 맡기기** — "그 외 파일 건드리지 마"는 3/3 지켜졌지만 그건 Codex가 잘 지켜서다. 막을 메커니즘은 없다.
- **속도 기대** — 폴링 2초 + 타이핑. 서브프로세스가 항상 빠르다.

## 7. 아직 못 해본 것 — 직접 해보고 이슈로 알려주세요

- E4 대칭 채널: Codex → Claude push (`claude -p` 호출 / 세션 소켓)
- E5 iTerm2(`write text`) · tmux(`send-keys`) · Windows Terminal 대체
- E6 Codex `Working…` 중 전송 시 큐잉 vs 무시
- E7 3+ 에이전트가 같은 파일을 동시에 저장할 때 (마지막 저장이 이기는지)
- E8 sha256 해시 봉인 커밋-리빌
- E9 원래 하려던 실제 협업 과제(채점·실행·진단) 완주 — 이 노트의 실험은 전부 **한 줄 편집**이었다. 진짜 일을 시켜본 결과가 다음 노트다.

## 저장소 구조

```
README.md                 이 노트 (정본)
bin/  send_to_tty.sh      탭에 타이핑 + Enter          read_tty.sh    탭 화면 읽기
      list_agents.sh      떠 있는 에이전트·tty          watch_board.sh 게시판 줄 감시
      handoff_init.sh     게시판·포인터 3파일 복사
examples/  HANDOFF.md · AGENTS.md · CLAUDE.md   템플릿
docs/  method.md          방법 정본            log-2026-08-27.md   교신 원기록
       terminal-bridge.html  공유용 페이지      draft-v0.1-research-framing.md  첫 초안(논문 프레이밍, 폐기 사유 포함)
```

환경: macOS 26.6.2 · Terminal.app 2.15 · Claude Code 2.1.247 · Codex CLI 0.150.1. MIT.
