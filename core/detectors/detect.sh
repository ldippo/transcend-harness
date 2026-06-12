#!/usr/bin/env sh
# fable stack detector. Read-only. Emits a JSON object on stdout:
#   { "profile": "<id>", "confidence": 0.0-1.0, "pkg": "<cmd>",
#     "signals": { ... }, "candidates": [ {"profile":..,"score":..}, ... ] }
#
# Usage: detect.sh [PROJECT_DIR]   (defaults to $CLAUDE_PROJECT_DIR or cwd)
# POSIX sh. Delegates language-specific probing to signals.*.sh siblings.

DET_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"

# Collect signals from each language probe (each prints `key=value` lines).
NODE_SIGNALS="$(sh "$DET_DIR/signals.node.sh" "$PROJECT_DIR" 2>/dev/null)"

# Helper to read a key from a `key=value` block.
sig() { printf '%s\n' "$2" | grep "^$1=" | head -1 | cut -d= -f2-; }

HAS_PKG_JSON="$(sig has_package_json "$NODE_SIGNALS")"
HAS_REACT="$(sig has_react "$NODE_SIGNALS")"
HAS_TS="$(sig has_typescript "$NODE_SIGNALS")"
PKG="$(sig pkg "$NODE_SIGNALS")"
HAS_TEST_SCRIPT="$(sig has_test_script "$NODE_SIGNALS")"
HAS_LINT_SCRIPT="$(sig has_lint_script "$NODE_SIGNALS")"
HAS_TYPECHECK_SCRIPT="$(sig has_typecheck_script "$NODE_SIGNALS")"

# Score profiles. (M1: node-ts-react + unknown. More stacks land in M4.)
PROFILE="unknown"
CONFIDENCE="0.2"
if [ "$HAS_PKG_JSON" = "1" ] && [ "$HAS_REACT" = "1" ] && [ "$HAS_TS" = "1" ]; then
  PROFILE="node-ts-react"
  CONFIDENCE="0.9"
elif [ "$HAS_PKG_JSON" = "1" ] && [ "$HAS_REACT" = "1" ]; then
  PROFILE="node-ts-react"
  CONFIDENCE="0.6"
fi

[ -z "$PKG" ] && PKG="npm"

# Emit JSON via python (preferred) or a hand-rolled fallback.
if command -v python3 >/dev/null 2>&1; then PY=python3
elif command -v python >/dev/null 2>&1; then PY=python
else PY=""; fi

if [ -n "$PY" ]; then
  PROFILE="$PROFILE" CONFIDENCE="$CONFIDENCE" PKG="$PKG" \
  HAS_PKG_JSON="$HAS_PKG_JSON" HAS_REACT="$HAS_REACT" HAS_TS="$HAS_TS" \
  HAS_TEST_SCRIPT="$HAS_TEST_SCRIPT" HAS_LINT_SCRIPT="$HAS_LINT_SCRIPT" \
  HAS_TYPECHECK_SCRIPT="$HAS_TYPECHECK_SCRIPT" \
  "$PY" - <<'PYEOF'
import os, json
def b(k): return os.environ.get(k, "") == "1"
out = {
  "profile": os.environ.get("PROFILE", "unknown"),
  "confidence": float(os.environ.get("CONFIDENCE", "0") or 0),
  "pkg": os.environ.get("PKG", "npm"),
  "signals": {
    "has_package_json": b("HAS_PKG_JSON"),
    "has_react": b("HAS_REACT"),
    "has_typescript": b("HAS_TS"),
    "has_test_script": b("HAS_TEST_SCRIPT"),
    "has_lint_script": b("HAS_LINT_SCRIPT"),
    "has_typecheck_script": b("HAS_TYPECHECK_SCRIPT"),
  },
  "candidates": [
    {"profile": os.environ.get("PROFILE", "unknown"),
     "score": float(os.environ.get("CONFIDENCE", "0") or 0)},
  ],
}
print(json.dumps(out, indent=2))
PYEOF
else
  # Minimal fallback without python.
  printf '{ "profile": "%s", "confidence": %s, "pkg": "%s", "signals": {}, "candidates": [] }\n' \
    "$PROFILE" "$CONFIDENCE" "$PKG"
fi
