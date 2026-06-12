#!/usr/bin/env sh
# transcend PreToolUse blocking hook: deny direct pushes to the protected branch.
#
# Usage (hook args): protect-main.sh <protected-branch>   (default: main)
#
# Denies when the push command targets the protected branch explicitly
# (`git push origin main`, `HEAD:main`, `--force ... main`) or when it's a bare
# `git push` while the protected branch is checked out. POSIX sh.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh" 2>/dev/null || true

PROTECTED="${1:-main}"

TMP="$(transcend_stdin_to_tmp)" || exit 0
trap 'rm -f "$TMP"' EXIT

CMD="$(transcend_json_file_get "$TMP" tool_input.command)"
case "$CMD" in
  *git*push*) ;;
  *) exit 0 ;;
esac

DENY_MSG="Direct push to '$PROTECTED' is not allowed (see .claude/rules/git-workflow.md). Push a feature branch and open a PR instead."

# Explicit refspec targeting the protected branch.
case "$CMD" in
  *" $PROTECTED"|*" $PROTECTED "*|*":$PROTECTED"|*":$PROTECTED "*)
    transcend_emit_deny "$DENY_MSG"
    ;;
esac

# Bare push (no refspec — at most a remote after `push`) while the protected
# branch is checked out. `git push origin feature/x` from main is fine.
REST="$(printf '%s' "$CMD" | sed 's/^.*push//')"
NONFLAG=0
for tok in $REST; do
  case "$tok" in
    -*) ;;
    *) NONFLAG=$((NONFLAG + 1)) ;;
  esac
done
if [ "$NONFLAG" -le 1 ]; then
  PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(transcend_json_file_get "$TMP" cwd)}"
  [ -z "$PROJECT_DIR" ] && PROJECT_DIR="$(pwd)"
  CURRENT="$(cd "$PROJECT_DIR" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)"
  if [ "$CURRENT" = "$PROTECTED" ]; then
    transcend_emit_deny "$DENY_MSG (You are on '$PROTECTED'; a bare \`git push\` would push it.)"
  fi
fi

exit 0
