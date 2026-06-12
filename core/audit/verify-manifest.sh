#!/usr/bin/env sh
# fable manifest verifier. Read-only. Compares the on-disk .claude/ tree against
# .claude/.fable/manifest.json and emits a JSON drift report on stdout:
#   { "manifest_present": true,
#     "summary": { "ok": n, "modified": n, "missing": n, "untracked": n },
#     "files": [ { "path": ".claude/...", "status": "ok|modified|missing" } ],
#     "untracked": [ ".claude/..." ] }
#
# Status meanings:
#   ok        — on-disk sha256 matches the manifest hash (pristine; safe to regenerate)
#   modified  — file exists but hash differs (hand-edited; PRESERVE — suggest only)
#   missing   — recorded in the manifest but absent on disk
#   untracked — present under .claude/ but not in the manifest (never touch)
#
# Untracked scan skips .claude/.fable/, .claude/handoffs/ (the handoff loop
# creates dated files there by design), and settings.local.json (personal,
# gitignored). NOTE: handoffs/current.md IS manifest-tracked and will usually
# report `modified` — that churn is by design; auditors must not flag it.
#
# Usage: verify-manifest.sh [PROJECT_DIR]   (defaults to $CLAUDE_PROJECT_DIR or cwd)
# POSIX sh; JSON + hashing via python3 (no jq, no shasum dependency).

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"

if command -v python3 >/dev/null 2>&1; then PY=python3
elif command -v python >/dev/null 2>&1; then PY=python
else
  printf '{ "manifest_present": false, "error": "python3 not found" }\n'
  exit 1
fi

PROJECT_DIR="$PROJECT_DIR" "$PY" - <<'PYEOF'
import hashlib, json, os, sys

project = os.environ["PROJECT_DIR"]
claude_dir = os.path.join(project, ".claude")
manifest_path = os.path.join(claude_dir, ".fable", "manifest.json")

if not os.path.isfile(manifest_path):
    print(json.dumps({"manifest_present": False,
                      "error": "no .claude/.fable/manifest.json (hand-built harness?)"}))
    sys.exit(0)

try:
    manifest = json.load(open(manifest_path))
except Exception as e:
    print(json.dumps({"manifest_present": False,
                      "error": "manifest unreadable: %s" % e}))
    sys.exit(0)

def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return "sha256:" + h.hexdigest()

files, tracked = [], set()
for entry in manifest.get("files", []):
    rel = entry.get("path", "")
    tracked.add(rel)
    abspath = os.path.join(project, rel)
    if not os.path.isfile(abspath):
        status = "missing"
    elif sha256(abspath) == entry.get("hash", ""):
        status = "ok"
    else:
        status = "modified"
    files.append({"path": rel, "status": status})

# Untracked: anything under .claude/ the manifest doesn't record, minus paths
# that churn or are personal by design.
SKIP_DIRS = {".fable", "handoffs"}
untracked = []
for root, dirs, names in os.walk(claude_dir):
    rel_root = os.path.relpath(root, claude_dir)
    parts = [] if rel_root == "." else rel_root.split(os.sep)
    if parts and parts[0] in SKIP_DIRS:
        dirs[:] = []
        continue
    if not parts:
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
    for name in names:
        if name == ".DS_Store":
            continue
        rel = os.path.join(".claude", *(parts + [name])) if parts else os.path.join(".claude", name)
        if rel == ".claude/settings.local.json" or rel in tracked:
            continue
        untracked.append(rel)
untracked.sort()

summary = {"ok": 0, "modified": 0, "missing": 0, "untracked": len(untracked)}
for f in files:
    summary[f["status"]] += 1

print(json.dumps({"manifest_present": True,
                  "summary": summary,
                  "files": files,
                  "untracked": untracked}, indent=2))
PYEOF
