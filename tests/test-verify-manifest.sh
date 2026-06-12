#!/usr/bin/env sh
# Behavior test for core/audit/verify-manifest.sh (the M3 audit acceptance check:
# a hand-edited generated file must be detected as `modified`, never silently
# treated as regenerable). Uses the golden fixture as the pristine baseline.
# POSIX sh. Exit 0 = pass.

set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERIFY="$ROOT/core/audit/verify-manifest.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/transcend-audit-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

cp -R "$ROOT/tests/golden/node-ts-react/." "$TMP/"

fail() { echo "FAIL: $1" 1>&2; exit 1; }

# Assert a python expression about the report is true.
# Usage: check "<description>" "<python expr over `r`>"
check() {
  sh "$VERIFY" "$TMP" | DESC="$1" EXPR="$2" python3 -c '
import json, os, sys
r = json.load(sys.stdin)
if not eval(os.environ["EXPR"]):
    sys.exit("FAIL: %s\n%s" % (os.environ["DESC"], json.dumps(r, indent=2)))
'
}

# 1. Pristine copy: everything ok.
check "pristine fixture verifies clean" \
  'r["manifest_present"] and r["summary"] == {"ok": 14, "modified": 0, "missing": 0, "untracked": 0}'

# 2. Hand-edit a generated rule -> modified (preserve, suggest-only).
echo "## My team note" >> "$TMP/.claude/rules/testing.md"
check "hand-edited rule reported as modified" \
  '[f["status"] for f in r["files"] if f["path"] == ".claude/rules/testing.md"] == ["modified"] and r["summary"]["modified"] == 1'

# 3. Delete a tracked file -> missing.
rm "$TMP/.claude/rules/quality-gates.md"
check "deleted tracked file reported as missing" \
  '[f["status"] for f in r["files"] if f["path"] == ".claude/rules/quality-gates.md"] == ["missing"]'

# 4. Add an unrecorded file -> untracked; handoffs/ and settings.local.json churn is ignored.
echo "x" > "$TMP/.claude/rules/extra.md"
echo "x" > "$TMP/.claude/handoffs/2026-06-12-0900-old.md"
echo "{}" > "$TMP/.claude/settings.local.json"
check "unrecorded rule is untracked; handoffs + settings.local.json ignored" \
  'r["untracked"] == [".claude/rules/extra.md"]'

# 5. No manifest -> graceful manifest_present: false.
rm "$TMP/.claude/.transcend/manifest.json"
check "missing manifest handled gracefully" \
  'r["manifest_present"] == False'

echo "PASS: verify-manifest behavior tests"
