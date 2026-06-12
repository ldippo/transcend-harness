#!/usr/bin/env sh
# Shared helpers for fable hook scripts. POSIX sh; no bashisms.
# JSON is parsed/emitted via python3 (present on macOS/Linux). Avoid jq.

# Read all of stdin into a variable. Usage: HOOK_INPUT="$(read_stdin)"
read_stdin() {
  cat
}

# Locate python3, else python. Echoes the interpreter or empty string.
fable_python() {
  if command -v python3 >/dev/null 2>&1; then
    echo python3
  elif command -v python >/dev/null 2>&1; then
    echo python
  else
    echo ""
  fi
}

# Extract a top-level string field from a JSON blob on stdin.
# Usage: echo "$JSON" | fable_json_get cwd
# NOTE: the JSON travels via env var, NOT python's stdin — passing the program
# itself on stdin (python3 - <<heredoc) would consume stdin and the piped JSON
# could never be read.
fable_json_get() {
  _py="$(fable_python)"
  [ -z "$_py" ] && return 1
  FABLE_JSON="$(cat)" FABLE_KEY="$1" "$_py" -c '
import os, json, sys
try:
    data = json.loads(os.environ.get("FABLE_JSON", "") or "{}")
except Exception:
    sys.exit(0)
val = data.get(os.environ.get("FABLE_KEY", ""), "")
if val is None:
    val = ""
sys.stdout.write(str(val))
'
}

# Emit a SessionStart additionalContext / initialUserMessage JSON payload.
# Usage: fable_emit_initial_message "<title>" "<message text>"
fable_emit_initial_message() {
  _py="$(fable_python)"
  if [ -z "$_py" ]; then
    # Fallback: no python — emit nothing (hook becomes a no-op).
    return 0
  fi
  FABLE_TITLE="$1" FABLE_MSG="$2" "$_py" - <<'PYEOF'
import os, json
out = {
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "initialUserMessage": os.environ.get("FABLE_MSG", ""),
  }
}
title = os.environ.get("FABLE_TITLE", "")
if title:
    out["hookSpecificOutput"]["sessionTitle"] = title
print(json.dumps(out))
PYEOF
}

# Read stdin into a temp file and echo its path. Use for PreToolUse/PostToolUse
# inputs, which can be large (Write content) — env vars would hit size limits.
# Caller must rm the file.
fable_stdin_to_tmp() {
  _t="$(mktemp "${TMPDIR:-/tmp}/fable-hook.XXXXXX")" || return 1
  cat > "$_t"
  printf '%s' "$_t"
}

# Get a dotted-path value from a JSON file.
# Usage: fable_json_file_get <file> tool_input.command
fable_json_file_get() {
  _py="$(fable_python)"
  [ -z "$_py" ] && return 1
  "$_py" -c '
import sys, json
try:
    cur = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(0)
for part in sys.argv[2].split("."):
    if isinstance(cur, dict) and part in cur:
        cur = cur[part]
    else:
        sys.exit(0)
sys.stdout.write("" if cur is None else str(cur))
' "$1" "$2"
}

# Emit a PreToolUse deny. Usage: fable_emit_deny "<reason>"; always exits.
fable_emit_deny() {
  _py="$(fable_python)"
  if [ -n "$_py" ]; then
    FABLE_REASON="$1" "$_py" -c '
import os, json
print(json.dumps({"hookSpecificOutput": {
  "hookEventName": "PreToolUse",
  "permissionDecision": "deny",
  "permissionDecisionReason": os.environ.get("FABLE_REASON", "blocked by fable harness"),
}}))
'
    exit 0
  fi
  # No python: blocking exit code 2, reason on stderr.
  printf '%s\n' "$1" 1>&2
  exit 2
}

# Emit non-blocking additionalContext for a given event.
# Usage: fable_emit_context <HookEventName> "<note>"
fable_emit_context() {
  _py="$(fable_python)"
  if [ -n "$_py" ]; then
    FABLE_EVENT="$1" FABLE_NOTE="$2" "$_py" -c '
import os, json
print(json.dumps({"hookSpecificOutput": {
  "hookEventName": os.environ.get("FABLE_EVENT", ""),
  "additionalContext": os.environ.get("FABLE_NOTE", ""),
}}))
'
  else
    printf '%s\n' "$2" 1>&2
  fi
}

# Once-per-session guard. Usage: fable_once "<session_id>" "<key>" || exit 0
# Returns 0 (and records the marker) the first time; 1 thereafter.
# With an empty session_id it always returns 0 (no way to dedupe).
fable_once() {
  [ -z "$1" ] && return 0
  _m="${TMPDIR:-/tmp}/fable-once-$1-$2"
  [ -f "$_m" ] && return 1
  : > "$_m" 2>/dev/null
  return 0
}

# Read YAML-ish frontmatter value from a markdown file. Cheap line scan, no YAML
# parser. Usage: fable_frontmatter_field <file> <key>
fable_frontmatter_field() {
  _file="$1"; _key="$2"
  [ -f "$_file" ] || return 0
  awk -v key="$_key" '
    NR==1 && $0=="---" { infm=1; next }
    infm && $0=="---" { exit }
    infm {
      # match "key: value"
      idx=index($0, ":")
      if (idx>0) {
        k=substr($0,1,idx-1)
        gsub(/^[ \t]+|[ \t]+$/, "", k)
        if (k==key) {
          v=substr($0,idx+1)
          gsub(/^[ \t]+|[ \t]+$/, "", v)
          print v
          exit
        }
      }
    }
  ' "$_file"
}
