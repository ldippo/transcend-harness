#!/usr/bin/env sh
# fable PostToolUse advisory hook: after editing a source (non-test) file, remind
# once per session if no test file has been touched in the working tree.
# Never blocks. POSIX sh.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh" 2>/dev/null || true

TMP="$(fable_stdin_to_tmp)" || exit 0
trap 'rm -f "$TMP"' EXIT

FILE="$(fable_json_file_get "$TMP" tool_input.file_path)"
[ -z "$FILE" ] && exit 0

# Skip if the edited file IS a test (or docs/config) — that's the desired outcome.
case "$FILE" in
  *.test.*|*.spec.*|*/tests/*|*__tests__*|*.md|*.json|*.yaml|*.yml) exit 0 ;;
esac

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(fable_json_file_get "$TMP" cwd)}"
[ -z "$PROJECT_DIR" ] && PROJECT_DIR="$(pwd)"
cd "$PROJECT_DIR" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Any test files among working-tree changes? Then the convention is being followed.
if git status --porcelain --untracked-files=all 2>/dev/null \
   | grep -Eq '\.(test|spec)\.|/tests/|__tests__'; then
  exit 0
fi

SESSION_ID="$(fable_json_file_get "$TMP" session_id)"
fable_once "$SESSION_ID" "untested-edit" || exit 0

fable_emit_context PostToolUse "Source files are changing but no test file has been touched yet this session. The testing convention (.claude/rules/testing.md) expects behavioral changes to ship with tests."
exit 0
