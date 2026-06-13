---
title: Skills & Commands
description: The five entry-point skills — transcend-init, transcend-handoff, transcend-resume, transcend-audit, and transcend-catalog.
---

<!-- adapted from skills/*/SKILL.md frontmatter -->

transcend-harness ships five user-invocable skills. Each resolves `TRANSCEND_ROOT` at startup (plugin root, or the repo root in plain-repo mode) so it can read the CORE library in either [install mode](../../getting-started/).

## `/transcend-init`

**The spine.** Interviews the developer and generates a bespoke, committed `.claude/` harness tailored to the project's stack — architecture, testing, context/handoff, git workflow, review/quality gates, and specialized workflows.

- Detects the stack with read-only probes, then walks scope, appetite, pillar options, per-rule tiers, and catalog selection.
- Shows a plan preview; **nothing is written before you confirm**.
- Guards against clobbering: a handcrafted `.claude/` stops the run (it recommends `/transcend-audit` instead), while an existing transcend manifest switches to re-init/upgrade mode where your previous choices become the interview defaults and hand-edited files are preserved.
- Delegates heavy file materialization to the [transcend-generator agent](../agents/).

## `/transcend-handoff`

Write a compact session handoff (&lt;120 lines) so the next session can resume cheaply without re-scanning the codebase. Use before ending a work session, when pausing a task, or when the Stop hook reminds you that changes lack an updated handoff.

Captures the carved **Goal**, **Done**, ordered **Next** steps, **blockers**, **Context pointers**, and the **Do NOT** list — see [Context & Handoff](../../pillars/context-handoff/).

## `/transcend-resume`

Manually reload the latest handoff into context mid-session (the same one the `SessionStart` hook auto-loads), plus the current work-state delta (uncommitted changes, recent commits). Use to re-orient after a `/compact`, after wandering off-task, or to re-read the carved Goal and Do-NOT list. It also flags staleness — e.g. when the work-state delta shows changes the handoff's "Done" section doesn't mention.

## `/transcend-audit`

Critique an existing `.claude/` harness — whether transcend generated it or not. Read-only by default; checks for:

- drift from the transcend manifest (pristine vs. hand-edited vs. missing files)
- missing pillars and over/under-enforcement
- stale handoffs, oversized `CLAUDE.md`, broken imports
- unwired specialized workflows

Proposes diff-style improvements and can **safe-apply** the additive ones: hand-edited or untracked files are never overwritten, only suggested. See [Architecture](../../internals/architecture/) for the merge machinery.

## `/transcend-catalog`

Browse the curated catalog of specialized workflow skills and wire chosen ones into the project's harness after init. Filters by the project's stack, guards against writing to hand-edited files, and applies each entry's wiring idempotently. The entries themselves are documented in the [Workflow Catalog](../catalog/).

## Generated skills

Beyond these five framework entry points, a harness can **generate bespoke skills into
your project** (`.claude/skills/`, owned by your repo). The [Delivery Pipeline pillar](../../pillars/delivery-pipeline/)
generates two: `/pipeline-plan` (plan a high-level goal into a reviewable roadmap of
issues via the `pm` agent) and `/pipeline-loop` (execute one issue end-to-end — the
`/loop` target that grinds the roadmap to done). These are full bespoke skills, distinct
from the thin pointer skills the [catalog](../catalog/) drops in.
