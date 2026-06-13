#!/usr/bin/env sh
# Behavior tests for core/scripts/pipeline/issues.sh — the delivery-pipeline issue
# store helper. Exercises the state machine, dependency-aware `next`, single-flight
# `claim`, monotonic ids, and roadmap regeneration. POSIX sh. Exit 0 = pass.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ISSUES_SH="$ROOT/core/scripts/pipeline/issues.sh"
FAILED=0
fail() { echo "FAIL: $1" 1>&2; FAILED=1; }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/transcend-issues.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/.claude/issues"
export CLAUDE_PROJECT_DIR="$TMP"
iss() { sh "$ISSUES_SH" "$@"; }

# --- create + monotonic ids -------------------------------------------------
A="$(iss new feature alpha --title "Alpha" | awk '{print $1}')"
B="$(iss new feature beta  --title "Beta" --depends-on "$A" | awk '{print $1}')"
[ "$A" = "0001" ] || fail "first id should be 0001, got $A"
[ "$B" = "0002" ] || fail "second id should be 0002, got $B"

# --- list by status ---------------------------------------------------------
[ "$(iss list proposed | wc -l | tr -d ' ')" = "2" ] || fail "expected 2 proposed"
[ -z "$(iss list ready)" ] || fail "nothing should be ready yet"

# --- approve: proposed -> ready --------------------------------------------
iss approve 0001 >/dev/null
iss approve 0002 >/dev/null
[ "$(iss list ready | wc -l | tr -d ' ')" = "2" ] || fail "expected 2 ready after approve"

# --- next respects depends_on ----------------------------------------------
N="$(iss next | awk '{print $1}')"
[ "$N" = "0001" ] || fail "next should be 0001 (0002 blocked by dep), got $N"

# --- claim is single-flight -------------------------------------------------
iss claim 0001 >/dev/null
if iss claim 0002 >/dev/null 2>&1; then
  fail "claim 0002 should fail while 0001 is in-progress"
fi
# 0002 is ready but its dep (0001) is not done -> next is empty
[ -z "$(iss next)" ] || fail "next should be empty while only blocked-by-dep issues remain"

# --- claim resume is idempotent --------------------------------------------
iss claim 0001 >/dev/null 2>&1 || fail "re-claiming the in-progress issue should succeed (resume)"

# --- done unblocks the dependent -------------------------------------------
iss done 0001 >/dev/null
N2="$(iss next | awk '{print $1}')"
[ "$N2" = "0002" ] || fail "after 0001 done, next should be 0002, got $N2"
iss claim 0002 >/dev/null
iss done 0002 >/dev/null

# --- followup discovery: proposed, then approve ----------------------------
G="$(iss new bug gamma --title "Gamma bug" --discovered-by 0001 | awk '{print $1}')"
[ "$G" = "0003" ] || fail "followup id should be 0003, got $G"
[ "$(iss list proposed | wc -l | tr -d ' ')" = "1" ] || fail "expected 1 proposed followup"
iss approve 0003 >/dev/null
[ "$(iss next | awk '{print $1}')" = "0003" ] || fail "next should be the approved followup 0003"

# --- drain to empty: the terminal PIPELINE DONE state ----------------------
iss claim 0003 >/dev/null
iss done 0003 >/dev/null
[ -z "$(iss next)" ] || fail "next should be empty once all issues are done"
[ -z "$(iss list proposed)" ] || fail "no proposals should remain at the terminal state"

# --- roadmap regeneration ---------------------------------------------------
iss roadmap >/dev/null
[ -f "$TMP/.claude/roadmap.md" ] || fail "roadmap.md not generated"
grep -q "Milestone" "$TMP/.claude/roadmap.md" || fail "roadmap missing milestone heading"
grep -q "0001" "$TMP/.claude/roadmap.md" || fail "roadmap missing issue 0001"
grep -q "\[x\] 0001" "$TMP/.claude/roadmap.md" || fail "roadmap should mark 0001 done"

# --- lock is released (no stale .lock after operations) ---------------------
[ ! -d "$TMP/.claude/issues/.lock" ] || fail "claim left a stale lock dir"

[ "$FAILED" = "0" ] && echo "PASS: issues.sh behavior tests" || { echo "FAIL: issues.sh behavior tests" 1>&2; exit 1; }
