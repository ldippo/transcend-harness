---
name: fable-handoff
description: Write a compact session handoff document so the next Claude Code session can resume cheaply without re-scanning the codebase. Use before ending a work session, when pausing a task, or when you've been reminded that uncommitted changes lack an updated handoff.
user-invocable: true
allowed-tools: Read, Bash, Write, Edit
---

# fable-handoff

Capture the state of the current carved task into a compact handoff doc that the
next session will auto-load. Keep it short (<120 lines) — the goal is a low-token
bridge across sessions, not a full report.

## Step 0 — Gather state (already run below)

```!
FABLE_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$CLAUDE_SKILL_DIR")/.." && pwd)}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
echo "PROJECT_DIR=$PROJECT_DIR"
echo "NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "STAMP=$(date -u +%Y-%m-%d-%H%M)"
echo "--- git status ---"
( cd "$PROJECT_DIR" && git status --short --untracked-files=all 2>/dev/null | head -40 )
echo "--- diff stat ---"
( cd "$PROJECT_DIR" && git diff --stat 2>/dev/null | tail -20 )
echo "--- existing handoff ---"
cat "$PROJECT_DIR/.claude/handoffs/current.md" 2>/dev/null || echo "NO_CURRENT_HANDOFF"
```

## Step 1 — Draft the handoff

Using the git status/diff above and the conversation so far, fill the template at
`$FABLE_ROOT/core/templates/handoffs/handoff.template.md.tmpl`. Be concrete and
brief. The sections:

- **Goal (carved task)** — the one task this session targeted; keep the scope line.
- **Done** — what actually changed (reference files, tie to the diff).
- **Next (ordered)** — the exact next steps, in order. This is what the next
  session starts from — make it actionable.
- **Open questions / blockers** — decisions pending or things that block progress.
- **Context pointers** — the FEW files worth reading next session (not everything).
  This list is what keeps the next session's context light.
- **Do NOT** — out-of-scope areas and expensive operations to avoid.

Set frontmatter: `session: <STAMP>-<short-slug>`, `status: in-progress` (or
`blocked` / `done`), `updated: <NOW>`.

If a `current.md` already exists and is not `done`, preserve any still-relevant
Next/blocker items.

## Step 2 — Write files

1. Write the new handoff to `.claude/handoffs/<STAMP>-<slug>.md`.
2. If a prior `current.md` pointed at a different dated file and that file exists,
   move it into `.claude/handoffs/archive/` (create the dir if needed).
3. Overwrite `.claude/handoffs/current.md` with the new handoff's full content
   (CLAUDE.md imports this fixed path, and the SessionStart hook reads it).
4. If `.claude/.fable/manifest.json` exists, update its `last_handoff` field to the
   new dated path.

## Step 3 — Confirm

Tell the developer the handoff was written and that the next session will auto-load
it (when `status` is not `done`). Do not commit unless asked.
