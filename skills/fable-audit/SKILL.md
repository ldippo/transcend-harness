---
name: fable-audit
description: Critique an existing .claude/ harness — drift from a fable manifest, missing pillars, over/under-enforcement, stale handoffs, oversized CLAUDE.md, broken imports, and unwired specialized workflows — propose diff-style improvements, and optionally apply the safe ones. Use to review or improve a project's Claude Code harness (whether fable generated it or not).
user-invocable: true
allowed-tools: Read, Bash, Grep, Task, AskUserQuestion
---

# fable-audit

Inspect the target project's `.claude/` harness and produce a critique with
concrete, diff-style suggestions. **Read-only by default** — write only via the
safe-apply flow in Step 3 after explicit confirmation, and never overwrite a
hand-edited or untracked file at all (propose the change instead).

## Step 0 — Inventory (already run below)

```!
FABLE_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$CLAUDE_SKILL_DIR")/.." && pwd)}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
C="$PROJECT_DIR/.claude"
echo "FABLE_ROOT=$FABLE_ROOT"
echo "PROJECT_DIR=$PROJECT_DIR"
echo "--- tree ---"; ( cd "$PROJECT_DIR" && find .claude -maxdepth 3 -type f 2>/dev/null | sort )
echo "--- drift report ---"; sh "$FABLE_ROOT/core/audit/verify-manifest.sh" "$PROJECT_DIR"
echo "--- manifest ---"; cat "$C/.fable/manifest.json" 2>/dev/null || echo "NO_MANIFEST (harness not fable-generated, or hand-built)"
echo "--- CLAUDE.md line count ---"; wc -l "$C/CLAUDE.md" 2>/dev/null || echo "NO_CLAUDE_MD"
echo "--- handoff status ---"; sed -n '1,6p' "$C/handoffs/current.md" 2>/dev/null || echo "NO_HANDOFF"
echo "--- settings hooks present? ---"; grep -l '"hooks"' "$C/settings.json" 2>/dev/null || echo "no hooks block"
```

You may delegate the deeper read-only inspection to the `fable-auditor` agent
(`context: fork`) to keep the main context clean — pass it `FABLE_ROOT` and
`PROJECT_DIR`; it returns findings JSON with optional `apply` plans.

## Step 1 — Critique across these dimensions

For each, produce findings with a severity (`info` / `warn` / `error`):

1. **Provenance & drift** — read the drift report from Step 0. `modified` =
   **hand-edited**: flag as `info`, mark "preserve — suggest only". `missing` =
   recorded file deleted (`warn` — offer to regenerate). `untracked` = present
   but unrecorded (never touch; mention only if it conflicts with the harness).
   `handoffs/current.md` reporting `modified` is the handoff loop working — do
   NOT flag it.
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
**diff-style suggestion** (the exact rule/settings edit). Partition into:

- **Safe to auto-apply** — findings carrying an `apply` plan whose target is, per
  the drift report, a new path (`create`) or pristine (`ok` → `regenerate` /
  `append` / `settings-merge`).
- **Suggest-only** — everything touching a `modified` (hand-edited) or untracked
  file, plus judgment calls (tier changes, restructuring). These are shown as
  diffs for the developer to apply by hand.

Do not write anything yet.

## Step 3 — Safe-apply (on confirmation only)

If there are no safe-apply findings, end after the report. Otherwise ask
(AskUserQuestion): **[Just report / Apply N safe fixes / Show full diffs first]**
— after showing diffs, ask again whether to apply.

On "apply", delegate to the `fable-generator` agent in **merge mode**: pass
`FABLE_ROOT`, `PROJECT_DIR`, the drift report, and the list of `apply` plans.
Merge-mode rules (the generator re-verifies each one before writing):

- `create` — write a file that exists neither on disk nor in the manifest.
- `regenerate` / `append` — only if the target's CURRENT sha256 still matches
  the manifest (re-hash at write time; the audit may be minutes old).
- `settings-merge` — additive JSON merge into a pristine `settings.json`: append
  hook entries / permission lines, never remove or reorder existing ones. Copy
  any referenced scripts into `.claude/scripts/fable/` (with `lib/common.sh`)
  and `chmod +x`.
- A hand-edited or untracked target is NEVER written, even if an `apply` plan
  slipped through — the generator downgrades it to a suggestion.
- After writing, the generator updates `.fable/manifest.json`: refresh/add
  `files[]` hashes for every written file and stamp top-level `last_merge`
  (ISO-8601 UTC).

Print the generator's summary — written / skipped (with reasons) / remaining
suggestions — and recommend reviewing with `git diff .claude` before committing.
