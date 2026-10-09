# /team: personal overrides (junyub-pr fork)

`SKILL.md` reads this file before anything else. Where this file and `SKILL.md` or `foundation.md`
differ, this file wins; everything it doesn't mention follows them unchanged. Section names are
upstream's as of `7f4f1c5` (2026-10-09): SKILL.md Rules, Feature 1–7, Orca worker, templates D R C G S
T; foundation.md Found 1–6, Milestone run 1–7, Change 1–5.

Upstream dropped Grok on 2026-10-01 (`f437050`). This fork puts **Sol** (GPT-6.1 Sol at high effort,
through the Codex CLI) in the seats Grok held: the second model in design reviews, the implementer
for everything that isn't UI, and an extra code reviewer for code Sonnet writes. It also adds a path
for long work inside a running service (Long work, below). The /debate override is in
`~/.claude/skills/debate/local.md`.

## Sol

- **Headless, read-only:** `bash ~/.claude/skills/team/sol-turn.sh <prompt-file> [session-id|new]` →
  one JSON line `{"sessionId","text"}` (+ `"error"`). Reads files and runs read-only commands; writes
  fail at the OS level. Verified 2026-10-02 (codex-cli 0.160.0): a write was blocked, and a resumed
  session remembered round 1.
- **Orca worker:** `--agent codex --model gpt-6.1-sol --effort high`. The receipt's
  `launch.effective` shows the model and effort; the worker's status line shows "GPT-6.1-Sol high".
  Verified 2026-10-02 (Orca 1.4.204): it implemented a spec and replied with `worker_done`, with no
  trust prompt.
- `codex` on PATH is `~/.local/bin/codex`, a wrapper for the CLI bundled with the ChatGPT app
  (`~/.codex/packages/app-server-daemon/current/bin/codex`). `codex login status` not logged in →
  tell the user; workers fall back to Sonnet (below), headless Sol reviews count as failed.
- Ponytail isn't installed for Codex (and `~/.codex` is managed elsewhere), so Sol gets ponytail's
  ladder as text in its spec (below).
- Prompts and specs for Sol follow upstream's language rule: written in the user's language, asking
  for answers in it, template headings such as `## Verdict:` kept as written.

## Implementer routing (overrides "a Claude Sonnet worker writes the code": Rules "Roles", Feature 5, Orca worker, template S, Milestone run 5)

- **`sol`**, the default: backend, data, scripts, infra, tests — everything that isn't UI.
- **`sonnet`**: UI work — visual design, front-end screens, components, styles, templates, UI copy.
- Template D adds `Implementer: sol | sonnet` per chunk (Feature) or per slice (Milestone run), and
  in a Milestone run `Estimate: <worker minutes>` per slice, passed on in spec S; G and T show them.
  Work with both is split into chunks or slices whose files don't overlap, with the contract in the
  design doc.
- `--implementer sol|sonnet` in the request overrides the routing for the whole run; "you implement
  it" still means Claude itself.
- A `sol` worker starts like the Orca worker start in SKILL.md, with `--agent codex --model
  gpt-6.1-sol --effort high` in place of `--agent claude --model sonnet` (Milestone run 5's
  child-worktree start too). Its terminal must show GPT-6.1-Sol high, or stop.
- Spec S for a `sol` worker: replace its ponytail sentence ("ponytail is on: … build everything the
  design specifies.") with:
  ```
  코드는 최소한으로 쓴다. 각 부분마다 순서대로 묻는다: 꼭 필요한가? 이 코드베이스에 이미 있는가?
  표준 라이브러리로 되는가? 플랫폼 기본 기능인가? 설치된 의존성으로 되는가? 한 줄로 되는가?
  처음 '예'가 나오면 거기서 멈춘다. 신뢰 경계의 검증, 데이터 유실 처리, 보안, 접근성은 줄이지 않는다.
  설계 문서가 이긴다: 설계에 있는 것은 모두 만들고, 빼야 할 것 같으면 빼지 말고 묻는다.
  ```
- Milestone run 5: dependent slices reuse the worker of their implementer (`--terminal <handle>`); a
  dependent slice routed to the other implementer gets its own worker in the milestone worktree.
  Parallel slices start their routed agent in their child worktree.
- **Fallback, one way only:** a `sol` worker that can't do the work (usage limit, auth, launch
  failure, exits without `worker_done`) → its work moves to a `sonnet` worker; never a `sonnet` chunk
  to Sol.
  1. `worker-show` its dispatch; not settled → send it Stop as in Change 1, wait until it settles,
     release it. Its file changes stay where they are.
  2. Change that chunk's or slice's `Implementer` line to `sonnet` in the design doc right away, so a
     resume (another day, another session) doesn't hand it back to Sol.
  3. Start the `sonnet` worker in the same worktree with spec S as upstream wrote it, plus
     "이어서 작업한다. 지금까지 바뀐 파일: <files>".
  4. T says "Sol → Sonnet: <reason>".
- "Apply review: …" goes to the worker that wrote it (Feature 6).
- No Orca: tell the user to implement the design doc in this repo with `codex -m gpt-6.1-sol -c
  model_reasoning_effort="high"` (sol) or `claude --model sonnet` (sonnet), in its order and scope
  without committing, then come back for Feature 6.

## The Sol reviewer (Feature 3, Found 5, Milestone run 3, Change 3, Project plan below)

- Start Sol in the same message as the Claude reviewer(s), on the same request file, with Bash
  `run_in_background: true` and `timeout: 3600000`:
  ```bash
  bash ~/.claude/skills/team/sol-turn.sh /tmp/team/<slug>/<name>-req.md new
  ```
  The request already ends with upstream's "Review only: … Stop after 30 tool calls …" line; Sol
  follows it too.
- **Long work (Found, Project plan, Milestone run, Change): wait for Sol like any reviewer** before the
  gate — one approval there starts several slices, so a late Critical would mean rework across them.
  Sol not back when the Bash call ends, or failed (below) → the gate says Sol's review failed.
- **Feature only:** overrides "wait for every reviewer you started" for Sol: wait for the Claude
  reviewer(s); Sol's result is merged whenever it lands (you are notified; never poll):
  - before the gate is shown → like any reviewer's items;
  - while the gate waits → check its items, apply the accepted ones, post a short update; a newly
    accepted Critical that changes the design substantially → show the gate again;
  - after approval → an accepted Critical pauses the affected work and goes to the user; the rest is
    folded into the code review.
- Round 2 (Feature 3's message): `sol-turn.sh <round-2 prompt file> <sessionId>`.
- `error`, or `text` without `## Verdict:` → resume once with "지금까지 본 것으로, 요구한 형식에 맞춰
  지금 답하라." Killed → the id is in `/tmp/team/<slug>/<prompt name>.sol-session`. Still nothing →
  Sol's review **failed**; say so at the gate (never read it as "no Critical items").
- `--reviewer claude` in the request skips Sol; say at the gate that there was no cross-model review.
- Save Sol's text to `/tmp/team/<slug>/<name>-sol-<N>.md`. G and T count Sol's items next to the
  reviewers'.

## Code review additions (Feature 6, Milestone run 5)

- Code Sol wrote → Claude reviewer `model: "opus"` for risky slices or chunks (money, auth,
  data-changing migration); otherwise upstream's `model: "sonnet"` — it is already a different model
  family. (Measured 2026-10-08, CMS run: 74 reviewer agents, mostly Opus, read 327M tokens.)
- UI and copy slices or chunks with nothing risky: one code-review round. Accepted fixes are checked by
  the driver re-running the affected definition-of-done commands, not by a second reviewer round.
- Code Sonnet wrote also gets a Sol code review (template C): in a Feature always, merged whenever it
  lands as in The Sol reviewer's Feature rule; in a Milestone run only for risky slices (money, auth,
  data-changing migration), and waited for before that slice's commit.

## Every review request (Sol included)

Add to the request: "Do not ask for anything the user's request did not ask for; something the
design or code adds with no basis in the user's words is itself a finding." (in the user's language).
A review item that widens the scope or drops part of the request is rebutted, not applied — except a
finding that breaks the current result (money, data, auth, or the definition of done): in a Milestone
run it goes to Findings (Milestone run additions 1); in a Feature it is a Critical.

## Long work

### Short or long
- **Short** — one design gets one approval and one build: Feature, `/fix`, `/debate`, or a direct
  edit (unchanged).
- **Long** — one approved design can drive several slices in a row, or the work has to carry across
  sessions. Size (more than one PR, more than a day of worker time) is a signal, not the rule.
  - a new service or a re-founding → upstream Found, then Milestone runs;
  - a long project inside a running service (PhoneGo 효성CMS, Paysoft…) → Project plan (below), then
    Milestone runs on it.
- A Feature whose design turns out to hold two or more slices: at its gate, offer to run it as M1 of a
  project plan. Agreeing to that is not approval to build. Keep the survey, design and review done so
  far (the doc becomes M1's design, nothing is rewritten); write `plan.md` and `slices.md` and add only
  what Milestone run 2 needs (shared interfaces, per-slice scope, definition of done, regression tests,
  estimate); review just those additions, Sol awaited; then show the Project plan gate (6). Its
  approval starts Build.

### Project plan (`/team project <name>`)
A project inside a running service doesn't get its own foundation. Its plan is subordinate to the
service's canon (PhoneGo: `~/work/phonego/AGENTS.md`, `rules/`, `projects/<project>/README.md` and its
topics): it links to what that canon settled and never restates or overrides it. As upstream's
foundation does, the canon decides what gets built and its safety rules; how the team works (implementer,
approval unit, reviews, reports) follows this skill and this file.
1. Survey (Feature 1) of the project's code, docs and data, read-only.
2. `plan.md`: goal · done result per milestone (what the user runs or opens to accept it) · not doing
   · links to the canon it follows · a decision note only for something new and expensive to reverse
   that stays inside the project. A plan that would change a service-wide decision → stop; that's
   the user's call in the canon, not in the plan.
3. `slices.md`: milestones of 2–4 slices (Found 4's sizing), each slice with its repo, plus a
   `## Backlog` section.
4. M1's design doc (Milestone run 2).
5. One review of plan + M1 (reviewer, risk reviewer if any slice is risky, Sol), ≤2 rounds.
6. One gate: plan one-liner, milestones one line each, then Milestone run 4's gate for M1. Approval
   starts M1's Build.
Later milestones: `/team <name> M2` → Milestone run 1–7 with the plan in the foundation's place.
`/team M2` alone works when exactly one plan for this repo has unfinished milestones.

### Where the plan lives
- PhoneGo (`phone_go`, `overdue_admin_temporary` — one plan may span both) and RegoTrade keep design
  material out of product Git (phone_go `.gitignore` has `*.md`, Overdue's has `docs/*`;
  `~/work/phonego/rules/runtime-data.md`, `~/work/regotrade/AGENTS.md`), and ignored files inside a
  worktree vanish with it. Their plans (and a service foundation, if one is ever made) live in
  `~/work/<phonego|regotrade>/projects/<name>/` (`plan.md`, `slices.md`, `design/`).
- Slice commits there hold product files only, and `slices.md` is updated in that folder (never
  `git add -f`). Because the two no longer share a commit, a `done` line records `<repo> <commit>`;
  on resume, check those commits are on the milestone branch before going on, and fix the line or
  stop if they aren't.
- A plan that spans repos: each milestone design names, per repo, its milestone worktree and branch.
  Every slice is built, reviewed, committed and checked on resume in its own repo's milestone worktree,
  and Milestone run 5's rules (worker reuse, child worktrees, cherry-pick) apply within that repo. A
  slice that depends on another repo's slice starts after that slice's commit.
- Other repos: upstream's `docs/design/foundation/`; a plan goes in `docs/design/projects/<name>/`.

### Milestone run additions
1. **Findings.** Optional improvements, and work outside the slice that the current result doesn't
   need → one line under `## Backlog`; keep going. A finding that breaks the current result — money,
   data, auth, or a slice's definition of done — stops the affected slices even when the fix is
   outside their files (a stop item); unaffected slices go on. T lists both.
2. **Spec S adds** (the worker asks the driver with the preamble's `ask`; the driver answers, and only
   gate stop items go to the user): "같은 대상이 두 번 실패하거나, 테스트를 끄거나 지우거나 기대값을
   느슨하게 해야 할 것 같거나, 설계에 없는 도구·하네스·진단 스크립트를 새로 만들어야 할 것 같거나, 지시에
   적힌 예상 시간(Estimate)의 두 배를 넘기면 멈추고 ask로 묻는다."
3. **Verification.** A slice's definition of done runs its own tests plus the regression tests for the
   contracts it changes and the existing money and auth paths it touches; the milestone design names
   them per slice. The full suite and the done demo run at the end of the milestone, before T; a
   failure there is fixed and re-run like any other. The driver runs a slice's definition of done once
   before its commit; after a fix round, only the commands the fix touches. `phone_go` slices: `$phonego-ci --lane auto`
   on the staged slice before its commit — it checks formatting, lint and the frontend build, not
   behaviour, and runs only in the Django repo. Slices in other repos (Overdue…) use that repo's own
   checks, named in the milestone design.
4. **Workers.** Within two minutes of a start, read its terminal: the spec must have been submitted and
   work begun; if the input box still holds it, send it again (`orca terminal send --enter`). Parallel
   slices that each need their own database stack count against the project's resource rule.
5. **T adds one line:** elapsed time · summed worker time · waits by cause (approval, usage limit,
   environment) · design and code review rounds · stops and why · slices reopened · backlog lines.
6. **One driver session per milestone.** Measured 2026-10-08 (CMS run, one session for M1–M6): every
   call re-read about 530k tokens, 445M in 21 hours. So after a milestone's T (or when a stop leaves
   the run waiting on the user), end the session with a handoff and start the next milestone in a new
   one:
   - A decision the user makes in chat goes into the plan, design doc or `slices.md` right away; the
     conversation is never the record.
   - `handoff.md` next to `slices.md`: done slices with commits, slices in progress (worker handle,
     worktree, uncommitted files), stops and open questions for the user, Backlog lines added, the next
     milestone and the exact command to resume (`/team <name> M<n>`). No narrative of how it went.
   - The new session reads `handoff.md`, the plan and the milestone design; not the old conversation.
   - Start the next milestone only after the current one's slices are committed or `blocked`; don't run
     several milestones' slices from one session.

## T addition: HTML report

Besides the T text in chat, write `/tmp/team/<slug>/report.html` (a Milestone run: one for the
milestone) and put its absolute path on the first line of the report. One self-contained file (CSS
in `<style>`, no external scripts, fonts or images), in the user's language, ordered the way the user
judges it: request → what was built → review rounds (accepted / rebutted) → tests with the command and
output tail → open issues and backlog. Same privacy rules as chat. Gates (G and the milestone gate)
stay in chat only.
