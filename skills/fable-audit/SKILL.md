---
name: fable-audit
description: Critique an existing .claude/ harness — drift from a fable manifest, missing pillars, over/under-enforcement, stale handoffs, oversized CLAUDE.md, broken imports, and unwired specialized workflows — and propose diff-style improvements. Use to review or improve a project's Claude Code harness (whether fable generated it or not).
user-invocable: true
allowed-tools: Read, Bash, Grep, Task
---

# fable-audit

Inspect the target project's `.claude/` harness and produce a critique with
concrete, diff-style suggestions. **Read-only by default** — never overwrite files
without explicit confirmation, and never overwrite a hand-edited file at all
(propose the change instead).

## Step 0 — Inventory (already run below)

```!
FABLE_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$CLAUDE_SKILL_DIR")/.." && pwd)}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
C="$PROJECT_DIR/.claude"
echo "PROJECT_DIR=$PROJECT_DIR"
echo "--- tree ---"; ( cd "$PROJECT_DIR" && find .claude -maxdepth 3 -type f 2>/dev/null | sort )
echo "--- manifest ---"; cat "$C/.fable/manifest.json" 2>/dev/null || echo "NO_MANIFEST (harness not fable-generated, or hand-built)"
echo "--- CLAUDE.md line count ---"; wc -l "$C/CLAUDE.md" 2>/dev/null || echo "NO_CLAUDE_MD"
echo "--- rules ---"; ls "$C/rules" 2>/dev/null || echo "NO_RULES"
echo "--- handoff status ---"; sed -n '1,6p' "$C/handoffs/current.md" 2>/dev/null || echo "NO_HANDOFF"
echo "--- settings hooks present? ---"; grep -l '"hooks"' "$C/settings.json" 2>/dev/null || echo "no hooks block"
```

You may delegate the deeper read-only inspection to the `fable-auditor` agent
(`context: fork`) to keep the main context clean.

## Step 1 — Critique across these dimensions

For each, produce findings with a severity (`info` / `warn` / `error`):

1. **Provenance & drift** — if a manifest exists, compare each recorded file's
   current `sha256` (compute via `shasum -a 256`) against the manifest hash. A
   mismatch = **hand-edited**; flag as `info` and mark it "preserve — suggest only".
2. **Missing pillars** — check all six pillars are represented (a `rules/*.md` or a
   CLAUDE.md section each). Flag gaps; missing context/handoff is `warn` ("you're
   losing session state").
3. **Over/under-enforcement** — cross-reference manifest `appetite` vs actual
   hooks. Strict appetite but no blocking hooks = under (`warn`). A blocking hook
   that could fire on routine edits (broad matcher, no `if:`) = over (`warn`).
   Hooks referencing scripts that don't exist = `error`.
4. **Stale handoffs / broken auto-load** — `current.md` with `status: done` or an
   old `updated` while work is clearly ongoing; a SessionStart load hook present
   but `current.md` missing; archive bloat.
5. **Size & import health** — CLAUDE.md > 200 lines (`warn`); `@imports` deeper
   than 4; dangling `@paths`; rule `paths:` globs that match no files.
6. **Portability** — hook commands with bashisms, hardcoded absolute paths, or
   missing `${CLAUDE_PLUGIN_ROOT}`/`${CLAUDE_PROJECT_DIR}`.
7. **Catalog drift** — specialized skills recommended for the detected stack
   (`core/catalog/catalog.yaml`) that aren't wired.

## Step 2 — Report

Group findings by pillar with severities. For each actionable finding, show a
**diff-style suggestion** (the exact rule/settings edit). Do not write yet.

## Step 3 — Offer to apply (M3+)

Ask: [Just report / Apply safe additive fixes / Show full diffs]. "Safe additive"
= new rule files or appended lines that never overwrite a hand-edited file.
Applying routes through generation logic that respects manifest provenance. (In
the current version, prefer report-only and let the developer apply; full
safe-apply/merge is a later milestone.)
