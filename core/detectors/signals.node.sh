#!/usr/bin/env sh
# Node/TS/React signal probe. Read-only. Prints `key=value` lines.
# Usage: signals.node.sh PROJECT_DIR
# POSIX sh. Uses python for JSON when available, falls back to grep.

DIR="${1:-$(pwd)}"
PKG_JSON="$DIR/package.json"

has_package_json=0
has_react=0
has_typescript=0
has_test_script=0
has_lint_script=0
has_typecheck_script=0
pkg=""

if [ -f "$PKG_JSON" ]; then
  has_package_json=1

  if command -v python3 >/dev/null 2>&1; then PY=python3
  elif command -v python >/dev/null 2>&1; then PY=python
  else PY=""; fi

  if [ -n "$PY" ]; then
    eval "$("$PY" - "$PKG_JSON" <<'PYEOF'
import sys, json
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(0)
deps = {}
for k in ("dependencies", "devDependencies", "peerDependencies"):
    deps.update(d.get(k) or {})
scripts = d.get("scripts") or {}
def yn(c): return "1" if c else "0"
print("has_react=" + yn("react" in deps or "react-dom" in deps))
print("has_typescript=" + yn("typescript" in deps))
print("has_test_script=" + yn("test" in scripts))
print("has_lint_script=" + yn("lint" in scripts))
print("has_typecheck_script=" + yn("typecheck" in scripts or "tsc" in scripts))
PYEOF
)"
  else
    # grep fallback (coarse)
    grep -q '"react"' "$PKG_JSON" && has_react=1
    grep -q '"typescript"' "$PKG_JSON" && has_typescript=1
    grep -q '"test"[[:space:]]*:' "$PKG_JSON" && has_test_script=1
    grep -q '"lint"[[:space:]]*:' "$PKG_JSON" && has_lint_script=1
    grep -q '"typecheck"[[:space:]]*:' "$PKG_JSON" && has_typecheck_script=1
  fi
fi

# Resolve package manager from lockfiles.
if   [ -f "$DIR/pnpm-lock.yaml" ]; then pkg=pnpm
elif [ -f "$DIR/yarn.lock" ];      then pkg=yarn
elif [ -f "$DIR/bun.lockb" ];      then pkg=bun
elif [ -f "$DIR/package-lock.json" ]; then pkg=npm
fi

printf 'has_package_json=%s\n' "$has_package_json"
printf 'has_react=%s\n' "$has_react"
printf 'has_typescript=%s\n' "$has_typescript"
printf 'has_test_script=%s\n' "$has_test_script"
printf 'has_lint_script=%s\n' "$has_lint_script"
printf 'has_typecheck_script=%s\n' "$has_typecheck_script"
printf 'pkg=%s\n' "$pkg"
