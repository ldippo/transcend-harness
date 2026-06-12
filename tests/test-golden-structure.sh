#!/usr/bin/env sh
# Structural validation of every golden fixture under tests/golden/ (M5).
#
# Rendered prose (CLAUDE.md, rules) is LLM-filled and NOT byte-stable between
# generator runs, so golden fixtures are validated by invariants, with exact
# byte checks only for deterministic artifacts (copied scripts). This script IS
# the golden-comparison contract; extend it when fragments gain new guarantees.
# POSIX sh. Exit 0 = pass.

set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILED=0

fail() { echo "FAIL[$FIX]: $1" 1>&2; FAILED=1; }

for FIXDIR in "$ROOT"/tests/golden/*/; do
  FIX="$(basename "$FIXDIR")"
  C="$FIXDIR.claude"

  # 1. Manifest present and self-verifying: no drift, nothing untracked.
  sh "$ROOT/core/audit/verify-manifest.sh" "$FIXDIR" | python3 -c '
import json, sys
r = json.load(sys.stdin)
ok = r.get("manifest_present") and r["summary"]["modified"] == 0 \
     and r["summary"]["missing"] == 0 and r["summary"]["untracked"] == 0
sys.exit(0 if ok else 1)
' || fail "manifest does not self-verify cleanly"

  # 2. CLAUDE.md: exists, <200 lines, imports the handoff pointer.
  [ -f "$C/CLAUDE.md" ] || fail "CLAUDE.md missing"
  [ "$(wc -l < "$C/CLAUDE.md")" -lt 200 ] || fail "CLAUDE.md >= 200 lines"
  grep -q '@.claude/handoffs/current.md' "$C/CLAUDE.md" || fail "CLAUDE.md missing handoff import"

  # 3. Expected rule files exist; path-scoped ones carry paths: frontmatter.
  for r in architecture testing git-workflow quality-gates task-carving; do
    [ -f "$C/rules/$r.md" ] || fail "rules/$r.md missing"
  done
  for r in architecture testing quality-gates; do
    [ -f "$C/rules/$r.md" ] && { head -1 "$C/rules/$r.md" | grep -q '^---$' || fail "rules/$r.md lacks paths: frontmatter"; }
  done

  # 4. No leftover template placeholders in rendered markdown.
  if grep -rnE '\{[a-z_]+\}' "$C/CLAUDE.md" "$C/rules" 2>/dev/null | grep -v '^Binary'; then
    fail "leftover {placeholders} in rendered output"
  fi

  # 5. settings.json: valid JSON; every transcend hook command resolves to an
  #    executable script in the fixture; handoff loop hooks present.
  C="$C" python3 - <<'PYEOF' || fail "settings.json hook validation failed"
import json, os, sys
c = os.environ["C"]
s = json.load(open(os.path.join(c, "settings.json")))
hooks = s.get("hooks", {})
assert "SessionStart" in hooks and "Stop" in hooks, "handoff loop hooks missing"
for event, groups in hooks.items():
    for g in groups:
        for h in g.get("hooks", []):
            cmd = h.get("command", "")
            if "${CLAUDE_PROJECT_DIR}" in cmd:
                rel = cmd.split("${CLAUDE_PROJECT_DIR}/", 1)[1].split()[0]
                p = os.path.join(os.path.dirname(c), rel)
                assert os.path.isfile(p), "hook references missing script: %s" % rel
                assert os.access(p, os.X_OK), "hook script not executable: %s" % rel
PYEOF

  # 6. Copied scripts are byte-identical to their core/scripts/ sources.
  for f in $(cd "$C/scripts/transcend" && find . -name '*.sh'); do
    cmp -s "$C/scripts/transcend/$f" "$ROOT/core/scripts/$f" \
      || fail "scripts/transcend/$f differs from core/scripts/$f"
  done

  # 7. Appetite/enforcement coherence: strict => at least one PreToolUse hook;
  #    docs => no PreToolUse/PostToolUse enforcement hooks at all.
  APPETITE="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["appetite"])' "$C/.transcend/manifest.json")"
  HAS_PRE="$(python3 -c 'import json,sys;print(1 if "PreToolUse" in json.load(open(sys.argv[1])).get("hooks",{}) else 0)' "$C/settings.json")"
  HAS_POST="$(python3 -c 'import json,sys;print(1 if "PostToolUse" in json.load(open(sys.argv[1])).get("hooks",{}) else 0)' "$C/settings.json")"
  case "$APPETITE" in
    strict) [ "$HAS_PRE" = "1" ] || fail "strict appetite but no blocking PreToolUse hook" ;;
    docs)   [ "$HAS_PRE" = "0" ] && [ "$HAS_POST" = "0" ] || fail "docs appetite but enforcement hooks present" ;;
  esac

  # 8. Version coherence with the plugin.
  PLUGIN_V="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["version"])' "$ROOT/.claude-plugin/plugin.json")"
  MANIFEST_V="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["transcend_version"])' "$C/.transcend/manifest.json")"
  [ "$PLUGIN_V" = "$MANIFEST_V" ] || fail "manifest transcend_version $MANIFEST_V != plugin $PLUGIN_V"

  # 9. The rename holds: no stale branding.
  if grep -ri 'fable' "$FIXDIR" >/dev/null 2>&1; then fail "stale 'fable' reference"; fi

  echo "ok: $FIX"
done

[ "$FAILED" = "0" ] && echo "PASS: golden structure tests" || { echo "FAIL: golden structure tests" 1>&2; exit 1; }
