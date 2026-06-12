#!/usr/bin/env sh
# transcend Stop hook (advisory, non-blocking): if this session changed files but the
# current handoff was not updated, remind the developer to run /transcend-handoff.
#
# Never blocks. Emits a short additionalContext note via exit code 0 + JSON.
# POSIX sh.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh" 2>/dev/null || true

HOOK_INPUT="$(read_stdin)"

SESSION_ID="$(printf '%s' "$HOOK_INPUT" | transcend_json_get session_id 2>/dev/null)"

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$PROJECT_DIR" ]; then
  PROJECT_DIR="$(printf '%s' "$HOOK_INPUT" | transcend_json_get cwd 2>/dev/null)"
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

# Stop fires after EVERY response, and uncommitted changes are the normal state
# mid-work — nudge at most once per session.
transcend_once "$SESSION_ID" "handoff-nudge" || exit 0

transcend_emit_context Stop "You have uncommitted changes but the session handoff (.claude/handoffs/current.md) was not updated this session. Consider running /transcend-handoff before ending so the next session can resume cheaply."
exit 0
