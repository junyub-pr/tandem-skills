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

## 파일

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
