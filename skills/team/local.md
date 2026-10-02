# /team: personal overrides (junyub-pr fork)

`SKILL.md` reads this file before anything else. Where this file and `SKILL.md` or `foundation.md`
differ, this file wins; everything it doesn't mention follows them unchanged.

Upstream dropped Grok on 2026-10-01 (`f437050`). This fork puts **Sol** (GPT-6.1 Sol at high effort,
through the Codex CLI) in the seats Grok held: the second model in design reviews, the implementer
for everything that isn't UI, and an extra code reviewer for the chunks Sonnet writes. The /debate
override is in `~/.claude/skills/debate/local.md`.

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
  stop and tell the user.
- Ponytail isn't installed for Codex (and `~/.codex` is managed elsewhere), so Sol gets ponytail's
  ladder as text in its spec (below).

## Implementer routing (overrides "a Sonnet worker implements" in C-2, T1, T3, T5)

- **`sol`**, the default: backend, data, scripts, infra, tests — everything that isn't UI.
- **`sonnet`**: UI work — visual design, front-end screens, components, styles, templates, UI copy.
- T1 adds `Implementer: sol | sonnet` per chunk; T3 and T5 show it. A feature with both is split
  into chunks whose files don't overlap (T1 "Chunks", contract in the design doc), one worker per
  chunk, in parallel.
- `--implementer sol|sonnet` in the request overrides the routing for the whole run; "you implement
  it" still means Claude itself (C-2).
- C-2 launch for a `sol` chunk (the `sonnet` launch stays as in C-2):
  ```bash
  orca orchestration worker-start --spec "<spec>" --worktree current --agent codex --model gpt-6.1-sol --effort high --timeout-ms 120000 --json
  ```
- Spec for a `sol` chunk: the C-2 template with its last paragraph ("Ponytail is active through
  Claude Code's hooks…") replaced by:
  ```
  Write the minimum code. Before each piece ask, in order: needed at all? already in this codebase?
  standard library? native platform feature? installed dependency? one line? Stop at the first yes.
  Never cut validation at trust boundaries, data-loss handling, security or accessibility. The design
  doc wins: build everything it specifies; if you think a part should be cut, ask instead of dropping it.
  ```
- "Apply review" goes to the worker that wrote the chunk (`--terminal <handle>`, as in C-4).
- No Orca: tell the user to implement the design doc in this repo with `codex -m gpt-6.1-sol -c
  model_reasoning_effort="high"` (sol) or `claude --model sonnet` (sonnet), in its order and scope
  without committing, then come back for C-4.

## T6 addition: the Sol reviewer

- Design reviews (C-1) and foundation reviews (F-4, F-change): start Sol in the same message as the
  Claude reviewer(s), on the same request file, with Bash `run_in_background: true` and
  `timeout: 3600000`:
  ```bash
  bash ~/.claude/skills/team/sol-turn.sh /tmp/team/<slug>/<name>-req.md new
  ```
  The request must also say: "Read-only: never write files; run only read-only commands."
- T6 step 2 waits for the Claude reviewer(s) only. Sol's result is merged whenever it lands (you
  are notified; never poll):
  - before the gate is shown → like any reviewer's items;
  - while the gate waits → check its items, apply the accepted ones, post a short update; a newly
    accepted Critical that changes the design substantially → show the gate again;
  - after approval → an accepted Critical pauses the affected work and goes to the user; the rest is
    folded into the code review.
- Round 2 to Sol (T6 step 3 message): `sol-turn.sh <round-2 prompt file> <sessionId>`.
- `error`, or `text` without `## Verdict:` → resume once with "Answer now in the required format from
  what you have." Killed → the id is in `/tmp/team/<slug>/last-sol-session`. Still nothing → Sol's
  review **failed**; say so at the gate (never read it as "no Critical items").
- `--reviewer claude` in the request skips Sol; say at the gate that there was no cross-model review.
- Save Sol's text to `/tmp/team/<slug>/<name>-sol-<N>.md`. T3 and T5 count Sol's items next to the
  reviewer's.

## C-4 additions

- Claude reviewer model: code Sol wrote → `model: "opus"`. C-4's "otherwise → `sonnet`" is meant for
  code the driver wrote; Sol's code is already reviewed across families, so it gets the stronger
  reviewer. Code Sonnet wrote → `opus`, as in C-4.
- A chunk Sonnet implemented also gets a Sol code review (T4 format, non-blocking, handled as in T6
  above), so a different model family reviews it too.
