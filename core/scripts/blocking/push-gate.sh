#!/usr/bin/env sh
# transcend PreToolUse blocking hook (generic push gate): before a `git push`, run a
# gate command; deny the push if it fails.
#
# Usage (hook args): push-gate.sh <label> <gate command>
#   e.g. push-gate.sh "tests" "pnpm test"
#        push-gate.sh "lint/typecheck" "pnpm run lint && pnpm run typecheck"
#
# Registered with `if: Bash(git push *)` so it only fires on pushes; we still
# cheaply re-check. POSIX sh.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh" 2>/dev/null || true

LABEL="${1:-gate}"
GATE_CMD="${2:-}"
[ -z "$GATE_CMD" ] && exit 0

TMP="$(transcend_stdin_to_tmp)" || exit 0
trap 'rm -f "$TMP"' EXIT

CMD="$(transcend_json_file_get "$TMP" tool_input.command)"
case "$CMD" in
  *git*push*) ;;
  *) exit 0 ;;
esac

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(transcend_json_file_get "$TMP" cwd)}"
[ -z "$PROJECT_DIR" ] && PROJECT_DIR="$(pwd)"
cd "$PROJECT_DIR" 2>/dev/null || exit 0

OUT="$(sh -c "$GATE_CMD" 2>&1)"
STATUS=$?
if [ $STATUS -ne 0 ]; then
  TAIL="$(printf '%s\n' "$OUT" | tail -15)"
  transcend_emit_deny "Push blocked: $LABEL gate failed (\`$GATE_CMD\` exited $STATUS). Fix before pushing. Output tail:
$TAIL"
fi
exit 0
