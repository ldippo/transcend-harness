#!/usr/bin/env sh
# transcend PostToolUse advisory hook: lint just the touched file and surface
# findings as a non-blocking note.
#
# Usage (hook args): lint-on-edit.sh <lint command> <ext list>
#   e.g. lint-on-edit.sh "npx eslint" "ts,tsx,js,jsx"
# POSIX sh.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh" 2>/dev/null || true

LINT_CMD="${1:-}"
EXTS="${2:-}"
[ -z "$LINT_CMD" ] && exit 0

TMP="$(transcend_stdin_to_tmp)" || exit 0
trap 'rm -f "$TMP"' EXIT

FILE="$(transcend_json_file_get "$TMP" tool_input.file_path)"
[ -z "$FILE" ] || [ ! -f "$FILE" ] && exit 0

# Extension filter (comma-separated list).
if [ -n "$EXTS" ]; then
  EXT="${FILE##*.}"
  case ",$EXTS," in
    *",$EXT,"*) ;;
    *) exit 0 ;;
  esac
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(transcend_json_file_get "$TMP" cwd)}"
[ -z "$PROJECT_DIR" ] && PROJECT_DIR="$(pwd)"
cd "$PROJECT_DIR" 2>/dev/null || exit 0

OUT="$(sh -c "$LINT_CMD \"\$1\"" _ "$FILE" 2>&1)"
STATUS=$?
[ $STATUS -eq 0 ] && exit 0

HEAD_OUT="$(printf '%s\n' "$OUT" | head -30)"
transcend_emit_context PostToolUse "Lint findings in $FILE (non-blocking — fix before the PR per .claude/rules/quality-gates.md):
$HEAD_OUT"
exit 0
