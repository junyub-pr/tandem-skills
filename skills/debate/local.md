# /debate: personal overrides (junyub-pr fork)

`SKILL.md` reads this file before anything else. Where they differ, this file wins.

- **The critic is Sol** (GPT-6.1 Sol at high effort, through the Codex CLI), as Grok was before
  upstream dropped it — not the `team-reviewer` subagent:
  ```bash
  bash ~/.claude/skills/team/sol-turn.sh /tmp/team/<slug>/debate-r<N>.md [new|<sessionId>]
  # → {"sessionId":"…","text":"…"}  (+ "error")
  ```
  Round 1 uses `new`; every later round passes the returned `sessionId` (Sol keeps the conversation,
  so never repeat earlier content). Give the Bash call `timeout: 1800000`. Prompts always go in files.
- Add to the round 1 requirements: "Read-only: never write files; run only read-only commands."
  Sol runs in a read-only sandbox (`sol-turn.sh`), so writes fail anyway.
- `error`, or `text` without `## Verdict:` → resume the same `sessionId` once with "Answer now in the
  required format." Still failing → fall back to the critic in `SKILL.md` (`team-reviewer` on a
  different Claude model) and say so in the report.
