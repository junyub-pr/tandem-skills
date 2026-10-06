#!/usr/bin/env bash
# sol-turn.sh — one headless, read-only Codex turn on GPT-6.1 Sol (high effort), used by this fork's
# /team reviews and /debate critic (see local.md next to this file). Not part of upstream.
#
# Usage:
#   sol-turn.sh <prompt-file> [session-id|new]
#
# Output: one JSON line {"sessionId":"…","text":"…"}; on failure it also carries "error".
#   Resume a later round (or a killed call) with the same sessionId: Codex keeps the conversation.
#   The id is also written to <prompt-file minus extension>.sol-session, and is the thread_id in the
#   first line of <prompt-file minus extension>.sol-events.jsonl while a call is still running. Side
#   files are named after the prompt file so parallel calls in one folder don't overwrite each other.
# Read-only: sandbox_mode="read-only" on every call (`codex exec resume` has no --sandbox flag). Codex
#   reads files and runs read-only commands; any write fails at the OS level (verified 2026-10-02,
#   codex-cli 0.160.0). Codex reads the repository's AGENTS.md itself. Runs from the repository root.
# Model and effort: SOL_MODEL (default gpt-6.1-sol), SOL_EFFORT (default high).
set -euo pipefail

PROMPT_FILE="${1:?prompt file required}"
SESSION="${2:-new}"
MODEL="${SOL_MODEL:-gpt-6.1-sol}"
EFFORT="${SOL_EFFORT:-high}"

# ~/.local/bin/codex wraps the CLI bundled with the ChatGPT app; fall back to the app's copy directly.
CODEX="$(command -v codex || echo "$HOME/.codex/packages/app-server-daemon/current/bin/codex")"
for bin in "$CODEX" jq git; do
  command -v "$bin" >/dev/null 2>&1 || { echo "{\"error\":\"$bin not found\"}"; exit 2; }
done
[[ -r "$PROMPT_FILE" ]] || { echo "{\"error\":\"prompt file not readable: $PROMPT_FILE\"}"; exit 2; }

PROMPT_DIR="$(cd "$(dirname "$PROMPT_FILE")" && pwd)"
PROMPT_FILE="$PROMPT_DIR/$(basename "$PROMPT_FILE")"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo '{"error":"not inside a git repository"}'; exit 2; }
cd "$REPO_ROOT"

OUT="$(mktemp "${TMPDIR:-/tmp}/sol-turn.XXXXXX")"
trap 'rm -f "$OUT"' EXIT
BASE="${PROMPT_FILE%.*}"
EVENTS="$BASE.sol-events.jsonl"
ERRLOG="$BASE.sol-stderr.log"
opts=(--json -c 'sandbox_mode="read-only"' -m "$MODEL" -c "model_reasoning_effort=\"$EFFORT\"" -o "$OUT")
if [[ "$SESSION" == "new" || -z "$SESSION" ]]; then
  cmd=("$CODEX" exec "${opts[@]}" -)
else
  cmd=("$CODEX" exec resume "${opts[@]}" "$SESSION" -)
fi

code=0
"${cmd[@]}" < "$PROMPT_FILE" > "$EVENTS" 2>>"$ERRLOG" || code=$?

sid="$(jq -r 'select(.type=="thread.started") | .thread_id' "$EVENTS" 2>/dev/null | head -n 1)"
[[ -n "$sid" ]] || sid="$SESSION"
[[ "$sid" == "new" ]] || printf '%s\n' "$sid" > "$BASE.sol-session"
text="$(cat "$OUT")"

if [[ $code -eq 0 && -n "$text" ]]; then
  jq -nc --arg sid "$sid" --arg text "$text" '{sessionId: $sid, text: $text}'
else
  err="$(jq -r 'select(.type=="error" or .type=="turn.failed") | (.message // .error.message // tostring)' "$EVENTS" 2>/dev/null | tail -n 1)"
  [[ -n "$err" ]] || err="$(tail -n 3 "$ERRLOG" 2>/dev/null)"
  jq -nc --arg sid "$sid" --arg text "$text" --arg err "${err:-codex exited $code}" \
    '{sessionId: $sid, text: $text, error: $err}'
  [[ $code -ne 0 ]] || code=1
fi
exit "$code"
