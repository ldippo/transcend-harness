#!/usr/bin/env sh
# fable Stop advisory hook: remind (once per session) when work is happening
# directly on the protected branch.
#
# Usage (hook args): on-protected-branch.sh <protected-branch>   (default: main)
# Never blocks. POSIX sh.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh" 2>/dev/null || true

PROTECTED="${1:-main}"
HOOK_INPUT="$(read_stdin)"

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$PROJECT_DIR" ]; then
  PROJECT_DIR="$(printf '%s' "$HOOK_INPUT" | fable_json_get cwd 2>/dev/null)"
fi
[ -z "$PROJECT_DIR" ] && PROJECT_DIR="$(pwd)"
cd "$PROJECT_DIR" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

CURRENT="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
[ "$CURRENT" = "$PROTECTED" ] || exit 0

# Only worth saying if something is actually changing on the branch.
[ -z "$(git status --porcelain 2>/dev/null)" ] && exit 0

SESSION_ID="$(printf '%s' "$HOOK_INPUT" | fable_json_get session_id 2>/dev/null)"
fable_once "$SESSION_ID" "on-protected-branch" || exit 0

fable_emit_context Stop "You are working directly on '$PROTECTED' with uncommitted changes. The git workflow (.claude/rules/git-workflow.md) expects a branch per change — consider moving this work to a feature branch."
exit 0
