#!/usr/bin/env sh
# transcend module-boundary hook: detect cross-feature imports in an Edit/Write.
#
# Usage (hook args): module-boundary.sh <mode> <features-root>
#   mode:          block (PreToolUse — deny) | warn (PostToolUse — note)
#   features-root: e.g. "src/features"
#
# Rule (feature-sliced): a file under <root>/<a>/ must not import from
# <root>/<b>/ where b != a. Shared code goes through the shared layer.
# POSIX sh + python for content scanning.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh" 2>/dev/null || true

MODE="${1:-warn}"
ROOT="${2:-src/features}"

_py="$(transcend_python)"
[ -z "$_py" ] && exit 0

TMP="$(transcend_stdin_to_tmp)" || exit 0
trap 'rm -f "$TMP"' EXIT

VIOLATION="$("$_py" -c '
import sys, json, re, os
try:
    data = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(0)
root = sys.argv[2].strip("/")
ti = data.get("tool_input") or {}
path = ti.get("file_path") or ""
# Edit carries new_string; Write carries content.
content = ti.get("new_string") or ti.get("content") or ""
if not path or not content:
    sys.exit(0)
norm = path.replace("\\", "/")
m = re.search(re.escape(root) + r"/([^/]+)/", norm)
if not m:
    sys.exit(0)  # file is not inside a feature module
feature = m.group(1)
base = root.split("/")[-1]   # e.g. "features"
hits = set()
for imp in re.finditer(base + r"/([A-Za-z0-9_.-]+)", content):
    other = imp.group(1)
    if other != feature:
        hits.add(other)
if hits:
    print(feature + " -> " + ", ".join(sorted(hits)))
' "$TMP" "$ROOT")"

[ -z "$VIOLATION" ] && exit 0

MSG="Module boundary: this change imports across feature boundaries ($VIOLATION). Features must not import each other directly — go through the shared layer (see .claude/rules/architecture.md)."

if [ "$MODE" = "block" ]; then
  transcend_emit_deny "$MSG"
else
  transcend_emit_context PostToolUse "$MSG"
fi
exit 0
