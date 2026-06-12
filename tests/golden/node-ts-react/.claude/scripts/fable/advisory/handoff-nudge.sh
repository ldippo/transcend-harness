#!/usr/bin/env sh
# fable Stop hook (advisory, non-blocking): if this session changed files but the
# current handoff was not updated, remind the developer to run /fable-handoff.
#
# Never blocks. Emits a short additionalContext note via exit code 0 + JSON.
# POSIX sh.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh" 2>/dev/null || true

HOOK_INPUT="$(read_stdin)"

# Stop fires after EVERY response, and uncommitted changes are the normal state
# mid-work — so nudge at most once per session. Marker keyed on session_id.
SESSION_ID="$(printf '%s' "$HOOK_INPUT" | fable_json_get session_id 2>/dev/null)"
if [ -n "$SESSION_ID" ]; then
  MARKER="${TMPDIR:-/tmp}/fable-nudge-$SESSION_ID"
  [ -f "$MARKER" ] && exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$PROJECT_DIR" ]; then
  PROJECT_DIR="$(printf '%s' "$HOOK_INPUT" | fable_json_get cwd 2>/dev/null)"
fi
[ -z "$PROJECT_DIR" ] && PROJECT_DIR="$(pwd)"

cd "$PROJECT_DIR" 2>/dev/null || exit 0

# Only meaningful inside a git repo.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Any working-tree changes this session?
if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
  exit 0
fi

HANDOFF="$PROJECT_DIR/.claude/handoffs/current.md"

# If the handoff is itself among the changed files, the developer already updated
# it this session — stay quiet. Use -uall so untracked files aren't collapsed
# into a bare ".claude/" directory entry.
if git status --porcelain --untracked-files=all 2>/dev/null | grep -q ".claude/handoffs/"; then
  exit 0
fi

NOTE="You have uncommitted changes but the session handoff (.claude/handoffs/current.md) was not updated this session. Consider running /fable-handoff before ending so the next session can resume cheaply."

# Mark that we nudged this session (only when actually emitting).
[ -n "$SESSION_ID" ] && : > "${TMPDIR:-/tmp}/fable-nudge-$SESSION_ID" 2>/dev/null

_py="$(fable_python)"
if [ -n "$_py" ]; then
  FABLE_NOTE="$NOTE" "$_py" - <<'PYEOF'
import os, json
print(json.dumps({
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "additionalContext": os.environ.get("FABLE_NOTE", "")
  }
}))
PYEOF
else
  # No python: print to stderr as a non-blocking note.
  printf '%s\n' "$NOTE" 1>&2
fi
exit 0
