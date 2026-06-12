#!/usr/bin/env sh
# transcend stack detector. Read-only. Emits a JSON object on stdout:
#   { "profile": "<id>", "confidence": 0.0-1.0, "pkg": "<cmd>",
#     "signals": { ... }, "candidates": [ {"profile":..,"score":..}, ... ] }
#
# Usage: detect.sh [PROJECT_DIR]   (defaults to $CLAUDE_PROJECT_DIR or cwd)
# POSIX sh. Delegates language-specific probing to signals.*.sh siblings.

DET_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"

# Collect signals from each language probe (each prints `key=value` lines).
NODE_SIGNALS="$(sh "$DET_DIR/signals.node.sh" "$PROJECT_DIR" 2>/dev/null)"
PY_SIGNALS="$(sh "$DET_DIR/signals.python.sh" "$PROJECT_DIR" 2>/dev/null)"
GO_SIGNALS="$(sh "$DET_DIR/signals.go.sh" "$PROJECT_DIR" 2>/dev/null)"

# Helper to read a key from a `key=value` block.
sig() { printf '%s\n' "$2" | grep "^$1=" | head -1 | cut -d= -f2-; }

HAS_PKG_JSON="$(sig has_package_json "$NODE_SIGNALS")"
HAS_REACT="$(sig has_react "$NODE_SIGNALS")"
HAS_TS="$(sig has_typescript "$NODE_SIGNALS")"
NODE_PKG="$(sig pkg "$NODE_SIGNALS")"
HAS_TEST_SCRIPT="$(sig has_test_script "$NODE_SIGNALS")"
HAS_LINT_SCRIPT="$(sig has_lint_script "$NODE_SIGNALS")"
HAS_TYPECHECK_SCRIPT="$(sig has_typecheck_script "$NODE_SIGNALS")"

HAS_PYPROJECT="$(sig has_pyproject "$PY_SIGNALS")"
HAS_REQUIREMENTS="$(sig has_requirements "$PY_SIGNALS")"
HAS_FASTAPI="$(sig has_fastapi "$PY_SIGNALS")"
HAS_PYTEST="$(sig has_pytest "$PY_SIGNALS")"
HAS_RUFF="$(sig has_ruff "$PY_SIGNALS")"
HAS_MYPY="$(sig has_mypy "$PY_SIGNALS")"
PY_PKG="$(sig pkg "$PY_SIGNALS")"
PY_PKG_RUN="$(sig pkg_run "$PY_SIGNALS")"

HAS_GO_MOD="$(sig has_go_mod "$GO_SIGNALS")"
HAS_HTTP_FRAMEWORK="$(sig has_http_framework "$GO_SIGNALS")"
HAS_GOLANGCI="$(sig has_golangci "$GO_SIGNALS")"
GO_MODULE="$(sig go_module "$GO_SIGNALS")"

# Score each profile 0-100 (integer percent of confidence).
NODE_SCORE=0
if [ "$HAS_PKG_JSON" = "1" ] && [ "$HAS_REACT" = "1" ] && [ "$HAS_TS" = "1" ]; then
  NODE_SCORE=90
elif [ "$HAS_PKG_JSON" = "1" ] && [ "$HAS_REACT" = "1" ]; then
  NODE_SCORE=60
fi

PY_SCORE=0
if [ "$HAS_FASTAPI" = "1" ] && [ "$HAS_PYPROJECT" = "1" ]; then
  PY_SCORE=90
elif [ "$HAS_FASTAPI" = "1" ]; then
  PY_SCORE=70
fi

GO_SCORE=0
if [ "$HAS_GO_MOD" = "1" ] && [ "$HAS_HTTP_FRAMEWORK" = "1" ]; then
  GO_SCORE=90
elif [ "$HAS_GO_MOD" = "1" ]; then
  GO_SCORE=70
fi

# Pick the highest-scoring profile (ties: node > python > go, arbitrary but stable).
PROFILE="unknown"; SCORE=20; PKG=""
if [ "$NODE_SCORE" -ge "$PY_SCORE" ] && [ "$NODE_SCORE" -ge "$GO_SCORE" ] && [ "$NODE_SCORE" -gt 0 ]; then
  PROFILE="node-ts-react"; SCORE=$NODE_SCORE; PKG="${NODE_PKG:-npm}"
elif [ "$PY_SCORE" -ge "$GO_SCORE" ] && [ "$PY_SCORE" -gt 0 ]; then
  PROFILE="python-fastapi"; SCORE=$PY_SCORE; PKG="${PY_PKG:-pip}"
elif [ "$GO_SCORE" -gt 0 ]; then
  PROFILE="go-service"; SCORE=$GO_SCORE; PKG="go"
fi

# Emit JSON via python (preferred) or a hand-rolled fallback.
if command -v python3 >/dev/null 2>&1; then PY=python3
elif command -v python >/dev/null 2>&1; then PY=python
else PY=""; fi

if [ -n "$PY" ]; then
  PROFILE="$PROFILE" SCORE="$SCORE" PKG="$PKG" \
  NODE_SCORE="$NODE_SCORE" PY_SCORE="$PY_SCORE" GO_SCORE="$GO_SCORE" \
  HAS_PKG_JSON="$HAS_PKG_JSON" HAS_REACT="$HAS_REACT" HAS_TS="$HAS_TS" \
  HAS_TEST_SCRIPT="$HAS_TEST_SCRIPT" HAS_LINT_SCRIPT="$HAS_LINT_SCRIPT" \
  HAS_TYPECHECK_SCRIPT="$HAS_TYPECHECK_SCRIPT" \
  HAS_PYPROJECT="$HAS_PYPROJECT" HAS_REQUIREMENTS="$HAS_REQUIREMENTS" \
  HAS_FASTAPI="$HAS_FASTAPI" HAS_PYTEST="$HAS_PYTEST" HAS_RUFF="$HAS_RUFF" \
  HAS_MYPY="$HAS_MYPY" PY_PKG_RUN="$PY_PKG_RUN" \
  HAS_GO_MOD="$HAS_GO_MOD" HAS_HTTP_FRAMEWORK="$HAS_HTTP_FRAMEWORK" \
  HAS_GOLANGCI="$HAS_GOLANGCI" GO_MODULE="$GO_MODULE" \
  "$PY" - <<'PYEOF'
import os, json
def b(k): return os.environ.get(k, "") == "1"
def score(k): return int(os.environ.get(k, "0") or 0) / 100.0
candidates = [
    {"profile": "node-ts-react", "score": score("NODE_SCORE")},
    {"profile": "python-fastapi", "score": score("PY_SCORE")},
    {"profile": "go-service", "score": score("GO_SCORE")},
]
candidates = sorted([c for c in candidates if c["score"] > 0],
                    key=lambda c: -c["score"]) or [{"profile": "unknown", "score": 0.2}]
out = {
  "profile": os.environ.get("PROFILE", "unknown"),
  "confidence": int(os.environ.get("SCORE", "20") or 20) / 100.0,
  "pkg": os.environ.get("PKG", ""),
  "signals": {
    "has_package_json": b("HAS_PKG_JSON"),
    "has_react": b("HAS_REACT"),
    "has_typescript": b("HAS_TS"),
    "has_test_script": b("HAS_TEST_SCRIPT"),
    "has_lint_script": b("HAS_LINT_SCRIPT"),
    "has_typecheck_script": b("HAS_TYPECHECK_SCRIPT"),
    "has_pyproject": b("HAS_PYPROJECT"),
    "has_requirements": b("HAS_REQUIREMENTS"),
    "has_fastapi": b("HAS_FASTAPI"),
    "has_pytest": b("HAS_PYTEST"),
    "has_ruff": b("HAS_RUFF"),
    "has_mypy": b("HAS_MYPY"),
    "py_pkg_run": os.environ.get("PY_PKG_RUN", ""),
    "has_go_mod": b("HAS_GO_MOD"),
    "has_http_framework": b("HAS_HTTP_FRAMEWORK"),
    "has_golangci": b("HAS_GOLANGCI"),
    "go_module": os.environ.get("GO_MODULE", ""),
  },
  "candidates": candidates,
}
print(json.dumps(out, indent=2))
PYEOF
else
  # Minimal fallback without python.
  printf '{ "profile": "%s", "confidence": %s, "pkg": "%s", "signals": {}, "candidates": [] }\n' \
    "$PROFILE" "0.$SCORE" "$PKG"
fi
