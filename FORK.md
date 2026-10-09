# junyub-pr/tandem-skills — 개인용 포크

원본: [sungminpark-biz/tandem-skills](https://github.com/sungminpark-biz/tandem-skills).
원본이 2026-10-01(`f437050`)에 Grok을 뺀 뒤, 이 포크는 Grok이 맡던 자리를 **Sol**(GPT-6.1 Sol,
reasoning effort high, Codex CLI)에게 맡깁니다. 그리고 운영 중인 서비스 안의 긴 작업을 위한 경로를
더했습니다(아래 "장기 작업").

| 자리 | 원본 | 이 포크 |
|---|---|---|
| 구현 (UI 아님) | Sonnet Orca 워커 | **Sol** Orca 워커 (`--agent codex --model gpt-6.1-sol --effort high`) |
| 구현 (UI) | Sonnet Orca 워커 | Sonnet Orca 워커 (그대로) |
| 설계·foundation·마일스톤·변경 검토 | Claude 리뷰어 (+ 위험 변경 시 리스크 리뷰어) | 위와 같음 **+ Sol 헤드리스 리뷰어** (병렬, 결과를 기다리지 않음) |
| 코드 리뷰 | 다른 모델의 Claude 리뷰어 | Sol이 짠 코드는 Opus가 리뷰. **Sonnet이 짠 코드는 Sol도 리뷰** (마일스톤 실행에서는 위험 슬라이스만) |
| `/debate` 비평가 | `team-reviewer` (다른 Claude 모델) | **Sol** (실패하면 원본 방식으로 대체) |
| Sol 워커 실패 시 | — | 같은 일을 **Sonnet**으로 다시 띄우고 보고에 기록 (Sonnet → Sol은 없음) |
| 검토 요청 | — | "요청에 없는 것을 요구하지 말고, 근거 없이 더한 것을 지적하라" 추가 |
| 운영 중인 서비스 안의 긴 작업 | 기능마다 설계·승인 | **프로젝트 계획**(`/team project <이름>`, 서비스 정본에 종속) → 마일스톤 실행 |
| 장기 작업 설계 검토의 Sol | — | 게이트 전에 기다림 (기능 모드에서는 기다리지 않음) |
| 계획·foundation 위치 | 저장소 `docs/design/` | PhoneGo·RegoTrade: `~/work/<…>/projects/<이름>/` (제품 Git 밖, done 줄에 커밋 기록) |
| 완료 보고 | 채팅 T | 채팅 T + `/tmp/team/<slug>/report.html` |

## 장기 작업

- **단기**: 설계 하나를 한 번 승인하고 한 번 만든다. `/team` 기능, `/fix`, `/debate`, 직접 수정.
- **장기**: 승인된 설계 하나로 슬라이스 여러 개를 연달아 만들 수 있거나, 세션을 넘겨 이어야 하는 일.
  크기(PR 여러 개, 워커 시간 하루 이상)는 판단 신호다.
  - 새 서비스·재구축 → 원본 `/team foundation` → `/team M1`…
  - 운영 중인 서비스 안의 긴 프로젝트 → `/team project <이름>`: 서비스 정본(PhoneGo는 `~/work/phonego`)을
    링크만 하는 계획(`plan.md`, `slices.md`)과 M1 설계를 한 번 검토하고 한 번 승인 → M1 실행 →
    `/team <이름> M2`…
  - 기능 설계가 슬라이스 2개 이상으로 나오면 게이트에서 "프로젝트 계획의 M1로 돌리기"를 제안한다(문서는
    옮기지 않음).
- 마일스톤 실행(원본)에 더한 것:
  - 현재 결과를 깨는 발견(돈·데이터·권한·완료 기준)은 해당 슬라이스를 멈추고, 선택적 개선은 백로그에 적고
    계속한다.
  - 워커는 같은 실패 두 번, 테스트 끄기·지우기, 설계에 없는 도구 만들기, 예상 시간의 두 배 초과 때 지휘에게
    묻는다.
  - 슬라이스 완료 기준은 자체 테스트와 건드린 계약·돈·권한 경로의 회귀 테스트이고, 전체 테스트와 데모는
    마일스톤 끝에 돌린다.
  - 워커 시작 2분 안에 지시가 들어갔는지 확인한다.
  - 보고에 경과 시간·워커 시간·원인별 대기·리뷰 라운드·멈춘 이유·재작업을 적는다.

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
- 원본 파일 수정은 `skills/team/SKILL.md`와 `skills/debate/SKILL.md` 첫 단락 아래의 "Local overrides" 한
  단락뿐입니다. 원본 업데이트를 받을 때 충돌이 나도 이 단락뿐이도록, 커스텀은 새 파일에 둡니다.

## 전제

- `codex`가 PATH에 있어야 합니다. 이 맥에서는 `~/.local/bin/codex`가 ChatGPT 앱에 들어 있는 CLI
  (`~/.codex/packages/app-server-daemon/current/bin/codex`)를 실행하는 래퍼입니다. 로그인 확인은
  `codex login status`로 합니다.
- 나머지 요구사항(Claude Code, Orca, ponytail, context7)과 설치(`./install.sh --link`)는 README와 같습니다.

## 원본 업데이트 받기

```bash
cd ~/dev/tandem-skills
git fetch upstream
git merge upstream/main          # 충돌 나면: git merge --abort 하고 충돌 범위를 확인
git push origin main             # 내 포크만. upstream은 push 주소가 막혀 있음
```

원본이 다시 크게 바뀌면(섹션 이름 변경 등) `local.md`가 가리키는 섹션(SKILL.md의 Rules, Feature 3·5·6,
Orca worker, 템플릿 D·S·C·G·T와 foundation.md의 Found 1~6, Milestone run 3·5, Change 3)이 여전히 맞는지
확인합니다. 2026-10-07(`31f97ba`, 이후 `ecad95f`)에 원본이 SKILL.md를 새로 쓰면서 옛 이름(C-2, C-4, T1~T6, F-4)이 모두
바뀌었습니다.
