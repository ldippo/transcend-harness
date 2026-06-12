#!/usr/bin/env sh
# Python/FastAPI signal probe. Read-only. Prints `key=value` lines.
# Usage: signals.python.sh PROJECT_DIR
# POSIX sh. Cheap substring greps; no TOML parser.

DIR="${1:-$(pwd)}"
PYPROJECT="$DIR/pyproject.toml"

has_pyproject=0
has_requirements=0
has_fastapi=0
has_pytest=0
has_ruff=0
has_mypy=0
pkg=""
pkg_run=""

[ -f "$PYPROJECT" ] && has_pyproject=1
for f in "$DIR/requirements.txt" "$DIR/requirements"/*.txt; do
  [ -f "$f" ] && has_requirements=1 && break
done

# Dependency signals from pyproject + requirements (coarse substring match).
probe_dep() {
  if [ "$has_pyproject" = "1" ] && grep -qi "\"$1\|'$1\|^$1" "$PYPROJECT" 2>/dev/null; then
    return 0
  fi
  if [ "$has_requirements" = "1" ] && grep -qi "^$1" "$DIR/requirements.txt" 2>/dev/null; then
    return 0
  fi
  return 1
}
probe_dep fastapi && has_fastapi=1
probe_dep pytest  && has_pytest=1
probe_dep mypy    && has_mypy=1
if probe_dep ruff || { [ "$has_pyproject" = "1" ] && grep -q '^\[tool\.ruff' "$PYPROJECT" 2>/dev/null; }; then
  has_ruff=1
fi

# Resolve runner from lockfiles. pkg is the manager; pkg_run prefixes commands.
if   [ -f "$DIR/uv.lock" ];      then pkg=uv;     pkg_run="uv run"
elif [ -f "$DIR/poetry.lock" ];  then pkg=poetry; pkg_run="poetry run"
elif [ "$has_pyproject" = "1" ] || [ "$has_requirements" = "1" ]; then pkg=pip; pkg_run=""
fi

printf 'has_pyproject=%s\n' "$has_pyproject"
printf 'has_requirements=%s\n' "$has_requirements"
printf 'has_fastapi=%s\n' "$has_fastapi"
printf 'has_pytest=%s\n' "$has_pytest"
printf 'has_ruff=%s\n' "$has_ruff"
printf 'has_mypy=%s\n' "$has_mypy"
printf 'pkg=%s\n' "$pkg"
printf 'pkg_run=%s\n' "$pkg_run"
