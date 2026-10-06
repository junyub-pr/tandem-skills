# junyub-pr/tandem-skills — 개인용 포크

원본: [sungminpark-biz/tandem-skills](https://github.com/sungminpark-biz/tandem-skills).
원본이 2026-10-01(`f437050`)에 Grok을 뺀 뒤, 이 포크는 Grok이 맡던 자리를 **Sol**(GPT-6.1 Sol,
reasoning effort high, Codex CLI)에게 맡깁니다.

| 자리 | 원본 | 이 포크 |
|---|---|---|
| 구현 (UI 아님) | Sonnet Orca 워커 | **Sol** Orca 워커 (`--agent codex --model gpt-6.1-sol --effort high`) |
| 구현 (UI) | Sonnet Orca 워커 | Sonnet Orca 워커 (그대로) |
| 설계·foundation 적대 검토 | Claude 리뷰어 (+ 위험 변경 시 리스크 리뷰어) | 위와 같음 **+ Sol 헤드리스 리뷰어** (병렬, 결과를 기다리지 않음) |
| 코드 리뷰 | Claude 리뷰어 | 위와 같음 **+ Sonnet이 짠 청크는 Sol도 리뷰** |
| `/debate` 비평가 | `team-reviewer` (다른 Claude 모델) | **Sol** (실패하면 원본 방식으로 대체) |
| Sol 워커 실패 시 | — | 같은 청크를 **Sonnet**으로 다시 띄우고 보고에 기록 (Sonnet → Sol은 없음) |
| 검토 요청 | — | "요청에 없는 것을 요구하지 말고, 근거 없이 더한 것을 지적하라" 추가 |
| 완료 보고 | 채팅 T5 | 채팅 T5 + `/tmp/team/<slug>/report.html` |

## 이 포크에만 있는 스킬: `/fix`

이슈 파악·수정 워크플로입니다(`skills/fix/`). `/team`의 방식(증거, 다른 모델의 반박 검토, 게이트,
정해진 보고 형식)을 이슈에 맞게 옮겼습니다.
- 드라이버: Claude Code(`/fix`), Codex Astra(`gpt-6-astra`)나 Sol(`gpt-6.1-sol`)(`$fix`).
- 검토자는 항상 다른 모델입니다. Claude가 드라이버면 Sol(`team/sol-turn.sh`), 엄격 등급(결제·인증·권한·
  운영 데이터 보정·스키마·개인정보)이나 지정 시에만 Astra(`SOL_MODEL=gpt-6-astra`). Codex가 드라이버면
  Claude Opus(`fix/claude-turn.sh`, 읽기 전용 헤드리스)가 검토합니다.
- 흐름: 접수 → 읽기 전용 증거 수집(조사의 끝 네 가지) → 교차 진단 검토 → **진단 게이트**("1A 2B"로
  답하는 보고) → 회귀 테스트·최소 수정 → 교차 수정 검토 → 결과 보고(채팅 + HTML).
- 요청에 "끝까지", "멈추지 말고", "가이드대로"가 있으면 진단 게이트를 건너뜁니다(운영 쓰기, 제품 동작이
  갈리는 선택, 사용자만 풀 수 있는 막힘에서는 멈춤).
- 명시 호출 전용: Claude는 `disable-model-invocation`, Codex는 `agents/openai.yaml`.
- 설치: Claude·Codex가 모두 읽도록 `~/.claude/skills/fix`와 `~/.agents/skills/fix`를 이 폴더에 링크합니다.

## 파일

- `skills/fix/`: `/fix` 스킬, `claude-turn.sh`(Codex 드라이버용 읽기 전용 Claude 검토자),
  `agents/openai.yaml`(Codex 자동 호출 끔).
- `skills/team/local.md`, `skills/debate/local.md`: 개인 오버라이드. 원본 문서와 다르면 이쪽이 이깁니다.
- `skills/team/sol-turn.sh`: Sol 헤드리스 읽기 전용 호출(`codex exec`, read-only sandbox, 세션 재개 지원).
- 원본 파일 수정은 `skills/team/SKILL.md`와 `skills/debate/SKILL.md` 제목 아래의 "Local overrides" 한 단락뿐입니다.
  원본 업데이트를 받을 때 충돌이 나도 이 단락뿐이도록, 커스텀은 새 파일에 둡니다.

## 전제

- `codex`가 PATH에 있어야 합니다. 이 맥에서는 `~/.local/bin/codex`가 ChatGPT 앱에 들어 있는 CLI
  (`~/.codex/packages/app-server-daemon/current/bin/codex`)를 실행하는 래퍼입니다. 로그인 확인은
  `codex login status`로 합니다.
- 나머지 요구사항(Claude Code, Orca, ponytail)과 설치(`./install.sh --link`)는 README와 같습니다.

## 원본 업데이트 받기

```bash
cd ~/dev/tandem-skills
git fetch upstream
git merge upstream/main          # 충돌 나면: git merge --abort 하고 충돌 범위를 확인
git push origin main             # 내 포크만. upstream은 push 주소가 막혀 있음
```

원본이 다시 크게 바뀌면(섹션 이름 변경 등) `local.md`가 가리키는 섹션(C-2, C-4, T1, T3, T5, T6, F-4)이
여전히 맞는지 확인합니다.
