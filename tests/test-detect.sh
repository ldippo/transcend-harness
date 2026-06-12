#!/usr/bin/env sh
# Behavior test for core/detectors/detect.sh multi-profile scoring (M4).
# Builds minimal fixture projects in a temp dir and asserts profile/confidence/pkg.
# POSIX sh. Exit 0 = pass.

set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DETECT="$ROOT/core/detectors/detect.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/transcend-detect-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# Assert a python expression about the detection report is true.
# Usage: check <fixture-dir> "<description>" "<python expr over `r`>"
check() {
  sh "$DETECT" "$1" | DESC="$2" EXPR="$3" python3 -c '
import json, os, sys
r = json.load(sys.stdin)
if not eval(os.environ["EXPR"]):
    sys.exit("FAIL: %s\n%s" % (os.environ["DESC"], json.dumps(r, indent=2)))
'
}

# 1. node-ts-react: react + typescript + pnpm lockfile.
mkdir -p "$TMP/node"
cat > "$TMP/node/package.json" <<'EOF'
{ "dependencies": { "react": "^19.0.0" },
  "devDependencies": { "typescript": "~6.0.0" },
  "scripts": { "lint": "eslint ." } }
EOF
touch "$TMP/node/pnpm-lock.yaml"
check "$TMP/node" "react+ts+pnpm -> node-ts-react 0.9 pnpm" \
  'r["profile"] == "node-ts-react" and r["confidence"] == 0.9 and r["pkg"] == "pnpm"'

# 2. python-fastapi: pyproject with fastapi + uv lockfile.
mkdir -p "$TMP/py"
cat > "$TMP/py/pyproject.toml" <<'EOF'
[project]
name = "svc"
dependencies = ["fastapi>=0.115", "pytest>=8"]
[tool.ruff]
line-length = 100
EOF
touch "$TMP/py/uv.lock"
check "$TMP/py" "pyproject+fastapi+uv -> python-fastapi 0.9 uv" \
  'r["profile"] == "python-fastapi" and r["confidence"] == 0.9 and r["pkg"] == "uv" and r["signals"]["py_pkg_run"] == "uv run" and r["signals"]["has_pytest"] and r["signals"]["has_ruff"]'

# 3. fastapi via requirements.txt only -> lower confidence, pip.
mkdir -p "$TMP/py-req"
echo "fastapi==0.115.0" > "$TMP/py-req/requirements.txt"
check "$TMP/py-req" "requirements-only fastapi -> python-fastapi 0.7 pip" \
  'r["profile"] == "python-fastapi" and r["confidence"] == 0.7 and r["pkg"] == "pip"'

# 4. go-service: go.mod with an http framework.
mkdir -p "$TMP/go"
cat > "$TMP/go/go.mod" <<'EOF'
module example.com/svc

go 1.23

require github.com/go-chi/chi/v5 v5.1.0
EOF
check "$TMP/go" "go.mod+chi -> go-service 0.9 go" \
  'r["profile"] == "go-service" and r["confidence"] == 0.9 and r["pkg"] == "go" and r["signals"]["go_module"] == "example.com/svc"'

# 5. bare go.mod -> weaker go-service.
mkdir -p "$TMP/go-bare"
printf 'module example.com/lib\n\ngo 1.23\n' > "$TMP/go-bare/go.mod"
check "$TMP/go-bare" "bare go.mod -> go-service 0.7" \
  'r["profile"] == "go-service" and r["confidence"] == 0.7'

# 6. polyglot: node 0.9 beats bare go.mod 0.7; both appear in candidates.
mkdir -p "$TMP/poly"
cp "$TMP/node/package.json" "$TMP/poly/" && touch "$TMP/poly/pnpm-lock.yaml"
cp "$TMP/go-bare/go.mod" "$TMP/poly/"
check "$TMP/poly" "node beats bare go; both in candidates" \
  'r["profile"] == "node-ts-react" and {c["profile"] for c in r["candidates"]} == {"node-ts-react", "go-service"}'

# 7. empty dir -> unknown.
mkdir -p "$TMP/empty"
check "$TMP/empty" "empty dir -> unknown 0.2" \
  'r["profile"] == "unknown" and r["confidence"] == 0.2'

echo "PASS: detect behavior tests"
