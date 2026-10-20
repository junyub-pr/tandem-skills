# /team with a Codex driver (junyub-pr fork)

Read when a Codex model (Sol `gpt-6.1-sol`, Astra `gpt-6-astra`) is the agent reading `SKILL.md`. It
overrides SKILL.md's "For Claude Code only" stop: Codex drives, and the seats Codex holds when Claude
drives go to Claude. Read order: `SKILL.md` → `local.md` → this file; where they differ, this file
wins, and everything it doesn't mention follows them unchanged (Route, Feature steps, gates,
templates, Long work, Project plan, Milestone run, Test scope, HTML report). Wherever those files say
"Claude" for the driver (designs, reviews, decides, runs the full suites), read "the driver".

## Seats

| Seat | Claude drives (SKILL.md + local.md) | Codex drives (this file) |
|---|---|---|
| Survey, design, gate, decisions | Claude | the driver |
| Design review (+ risk reviewer) | `team-reviewer` subagents + Sol headless | Claude Opus headless (`claude-turn.sh`), one call per reviewer |
| Implementer, not UI | Sol Orca worker | Claude **Opus** Orca worker |
| Implementer, UI | Sonnet Orca worker | Claude **Sonnet** Orca worker (unchanged) |
| Code review | a model other than the author | Sol headless (`sol-turn.sh`, template C) + the driver's own check |

## Headless reviewers

- Claude: `bash ~/.claude/skills/fix/claude-turn.sh <request file> [new|<sessionId>]`, run from the
  worktree (it reviews the repository it is started in). Read-only by permissions; model
  `CLAUDE_MODEL`, default `opus`. Same JSON line as `sol-turn.sh`; a new session's id is saved to
  `last-claude-session` next to the request, so give each reviewer its own folder or read the id from
  the JSON before starting the next one.
- Sol: `bash ~/.claude/skills/team/sol-turn.sh <request file> [new|<sessionId>]` (local.md "Sol").
- Several reviewers at once: start each in the background with its output redirected to a file, then
  `wait`, in one command with a timeout of at least 60 minutes. A review takes several minutes; never
  read an unfinished one as an approval.
- Round 2 resumes the same `sessionId` with "Accepted: … → changed: … / Rebutted: … — evidence: … /
  Re-check and answer in the same format." in the user's language.
- `error`, or text without `## Verdict:` → resume once with "지금까지 본 것으로, 요구한 형식에 맞춰
  지금 답하라."; still nothing → that review **failed**; say so at the gate and in T.
- Save each answer to `/tmp/team/<slug>/<name>-<claude|sol>-<N>.md`; G and T count its items.

## Overrides, by section

- **Rules "Roles"**: the driver designs, reviews and decides; Claude Orca workers write the code
  (routing below). No Orca → the user runs the spec in `claude --model opus` (not UI) or
  `claude --model sonnet` (UI). "You implement it" → the driver does.
- **Rules "Independent review"** and **local.md "The Sol reviewer"**: every design is reviewed by
  `claude-turn.sh` (Opus); the risk reviewer is a second `claude-turn.sh` call on its own request file
  that asks for the risk view only. There is no Sol design reviewer (the driver is already the Codex
  family), and both Claude reviewers are waited for before the gate, Feature included. `--reviewer
  none` in the request skips them; the gate says there was no cross-model review.
- **Rules "Code is reviewed by a different model"**: Claude-written code → Sol (template C through
  `sol-turn.sh`); risky chunks or slices (money, auth, data-changing migration) also get Astra
  (`SOL_MODEL=gpt-6-astra sol-turn.sh`), both waited for. Code the driver wrote itself ("you implement
  it") → `claude-turn.sh` (Opus). Gemini-written code → local.md "Code Gemini wrote" with
  `claude-turn.sh` (Opus) as its reviewer. Overrides the rest of local.md "Code review additions".
- **Rules "Preflight"**: instead of the ponytail check, `claude --version` and `codex login status`
  must work (Claude reviewers and workers, Sol reviewers); context7 and the project's database MCP are
  checked with `codex mcp list`, with SKILL.md's stop on "needs authentication".
- **ponytail**: not installed for Codex. Every design and code review request carries the ladder as
  text (local.md "Implementer routing", the Sol spec paragraph), and the driver applies the same ladder
  to the diff itself in place of `ponytail-review` — judging each item like a finding, never cutting
  validation, data-loss handling or security. Claude workers have ponytail installed, so spec S keeps
  upstream's ponytail sentence.
- **Parallel survey**: Explore agents and the search agent are Claude-only. The driver surveys and
  searches today's options itself (web search, context7); the "≤10 minutes" budget holds.
- **Implementer routing** (local.md): `opus` replaces `sol` — backend, data, scripts, infra, tests;
  `sonnet` stays for UI, `gemini` only when the user names it. Template D writes `Implementer: opus |
  sonnet | gemini`. `--implementer opus|sonnet|gemini` in the request overrides the routing for the
  whole run.
- **Orca worker**: start as in SKILL.md with `--agent claude --model opus` or `--agent claude --model
  sonnet`; the terminal must show that model, or stop. Commands need a command timeout of at least
  180 s (`worker-start`) and 600 s (`check --wait … --timeout-ms 540000`). Orca's "You have N
  orchestration message…" turns aren't the user: answer with a one-line status.
- **Fallback, one way only**: an `opus` worker that can't do the work (usage limit, auth, launch
  failure, exits without `worker_done`) → its work moves to a Sol worker (`--agent codex --model
  gpt-6.1-sol --effort high`, spec S with local.md's Sol ponytail paragraph), following local.md's
  fallback steps 1–4 with `opus` → `sol` (the design doc's line becomes `Implementer: sol`); that code
  is then reviewed by `claude-turn.sh` (Opus). A `sonnet` worker that can't do the work → stop and
  report; UI never goes to Sol. T says "Opus → Sol: <reason>".
- **Gotchas**: `team-reviewer`, SendMessage, the Skill tool and the `/ponytail` warnings are
  Claude-only and don't apply; headless reviewers replace them as above.
- **Long programs**: Codex has no `SessionStart` hook; after a context compaction the driver reads
  `handoff.md`, `slices.md` and the current milestone design itself before going on.
