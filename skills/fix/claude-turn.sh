#!/usr/bin/env bash
# claude-turn.sh — one headless, read-only Claude Code turn, used as the /fix reviewer when the driver
# is a Codex model (Astra or Sol). Part of this fork; not in upstream.
#
# Usage:
#   claude-turn.sh <prompt-file> [session-id|new]
#
# Output: one JSON line {"sessionId":"…","text":"…"}; on failure it also carries "error".
#   Resume a later round with the same sessionId: Claude keeps the conversation. A new session's id is
#   chosen before the call and written to <prompt-file dir>/last-claude-session, so a killed call can
#   be resumed too.
# Read-only by permissions: Read/Grep/Glob/WebSearch/WebFetch are allowed and Write/Edit are denied.
#   There is no Bash allow rule on purpose: under dontAsk, Claude Code runs only the commands it
#   classifies as read-only (git log/diff/show, grep, ls, cat…) and refuses the rest. A blanket `Bash`
#   allow let `touch` write a file (2026-10-02). Allow rules in the user's own settings still apply
#   (they include git add/commit/switch/stash/tag), so MUTATING_BASH denies those by name — deny wins.
#   Claude loads CLAUDE.md and the project memory.
# Model: CLAUDE_MODEL (default opus).
set -euo pipefail

PROMPT_FILE="${1:?prompt file required}"
SESSION="${2:-new}"
MODEL="${CLAUDE_MODEL:-opus}"

for bin in claude jq git; do
  command -v "$bin" >/dev/null 2>&1 || { echo "{\"error\":\"$bin not found in PATH\"}"; exit 2; }
done
[[ -r "$PROMPT_FILE" ]] || { echo "{\"error\":\"prompt file not readable: $PROMPT_FILE\"}"; exit 2; }

PROMPT_DIR="$(cd "$(dirname "$PROMPT_FILE")" && pwd)"
PROMPT_FILE="$PROMPT_DIR/$(basename "$PROMPT_FILE")"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo '{"error":"not inside a git repository"}'; exit 2; }
cd "$REPO_ROOT"

MUTATING_BASH="Bash(git add *),Bash(git commit *),Bash(git fetch *),Bash(git branch *),Bash(git switch *),Bash(git stash *),Bash(git tag *),Bash(git remote *),Bash(git checkout *),Bash(git restore *),Bash(git reset *),Bash(git clean *),Bash(git push *),Bash(git pull *),Bash(git rebase *),Bash(git merge *),Bash(git worktree *),Bash(git -c *),Bash(rm *),Bash(mv *),Bash(cp *),Bash(touch *),Bash(mkdir *),Bash(sed -i *),Bash(chmod *),Bash(tee *),Bash(brew *),Bash(kubectl *),Bash(psql *)"
args=(--model "$MODEL" --permission-mode dontAsk --output-format json --max-turns 60
      --allowedTools "Read,Grep,Glob,WebSearch,WebFetch"
      --disallowedTools "Write,Edit,NotebookEdit,${MUTATING_BASH}")

if [[ "$SESSION" != "new" && -n "$SESSION" ]]; then
  args+=(--resume "$SESSION")
else
  SESSION="$(uuidgen | tr 'A-Z' 'a-z')"
  args+=(--session-id "$SESSION")
  printf '%s\n' "$SESSION" > "$PROMPT_DIR/last-claude-session"
fi

code=0
# < /dev/null: skip claude -p's wait for piped stdin
raw="$(claude -p "$(cat "$PROMPT_FILE")" "${args[@]}" < /dev/null 2>>"$PROMPT_DIR/claude-stderr.log")" || code=$?

# claude prints its result JSON even when it exits non-zero (e.g. error_max_turns), so parse it first.
if printf '%s' "$raw" | jq -e 'type == "object"' >/dev/null 2>&1; then
  printf '%s' "$raw" | jq -c --arg sid "$SESSION" \
    '{sessionId: (.session_id // $sid), text: (.result // "")}
     + (if .is_error or (.subtype != "success") then {error: (.subtype // "error")} else {} end)'
else
  jq -nc --arg sid "$SESSION" --argjson code "$code" \
    '{sessionId: $sid, text: "", error: "claude exited \($code) without a JSON result (see claude-stderr.log next to the prompt)"}'
  [[ $code -ne 0 ]] || code=1
fi
exit "$code"
