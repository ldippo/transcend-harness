#!/usr/bin/env sh
# transcend SessionStart hook: auto-load the latest handoff so a new session resumes
# from the "Next" list without re-scanning the codebase.
#
# Behavior:
#   - Reads .claude/handoffs/current.md in the project.
#   - If it exists and its frontmatter `status` is not "done", emits a
#     SessionStart initialUserMessage containing the handoff, plus a sessionTitle.
#   - Otherwise emits nothing (clean start).
#
# POSIX sh. Resolves its own lib relative to the script's directory, so it works
# from anywhere it's copied (generated harnesses copy it to
# ${CLAUDE_PROJECT_DIR}/.claude/scripts/transcend/).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# lib is a sibling of the event subdir (../lib/common.sh)
. "$SCRIPT_DIR/../lib/common.sh" 2>/dev/null || true

HOOK_INPUT="$(read_stdin)"

# Determine the project dir: prefer CLAUDE_PROJECT_DIR, else the hook's cwd field.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$PROJECT_DIR" ]; then
  PROJECT_DIR="$(printf '%s' "$HOOK_INPUT" | transcend_json_get cwd 2>/dev/null)"
fi
[ -z "$PROJECT_DIR" ] && PROJECT_DIR="$(pwd)"

HANDOFF="$PROJECT_DIR/.claude/handoffs/current.md"
[ -f "$HANDOFF" ] || exit 0

STATUS="$(transcend_frontmatter_field "$HANDOFF" status)"
case "$STATUS" in
  done|Done|DONE) exit 0 ;;
esac

SLUG="$(transcend_frontmatter_field "$HANDOFF" session)"
BODY="$(cat "$HANDOFF")"

MSG="Resuming this project. The latest session handoff is below.

Start from the **Next** list and respect the **Do NOT** list. Read only the files
under **Context pointers** — do not re-scan the whole repository.

$BODY"

transcend_emit_initial_message "$SLUG" "$MSG"
exit 0
