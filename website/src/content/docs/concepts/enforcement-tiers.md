---
title: Enforcement Tiers
description: Every convention renders as docs (Tier 1), an advisory nudge (Tier 2), or a hard block (Tier 3) — chosen per rule during the interview.
---

<!-- adapted from docs/ENFORCEMENT-TIERS.md -->

Every convention transcend codifies can be rendered at one of three tiers. The tier is chosen per-rule during the interview, defaulting from the option's `tier_default` in `pillar.yaml` adjusted by the project's overall enforcement appetite.

| Tier | Mechanism | Blocks? | Renders |
|------|-----------|---------|---------|
| 1 — DOCS | `CLAUDE.md` summary + `.claude/rules/<x>.md` (path-scoped via `paths:`) | no | `rule.*` + `claudemd.*` fragment |
| 2 — ADVISORY | non-blocking `PostToolUse` / `Stop` hook that prints a reminder | no | + `hook.advisory.*` block & script |
| 3 — BLOCKING | `PreToolUse` hook that returns `permissionDecision: deny` (exit 2) | yes | + `hook.blocking.*` block & script |

Tier 1 is always emitted. Tier 2 and Tier 3 are additive. A single convention may be both Tier 2 and Tier 3 (e.g. nudge on every untested edit AND hard-block the push).

## Appetite → default mapping

The interview asks for an overall appetite once, which caps and seeds per-rule defaults:

- **docs-only** → cap at Tier 1 (no hooks generated).
- **advisory** → cap at Tier 2; `tier_default` of 3 is clamped to 2.
- **strict** → allow Tier 3; bump each option's `tier_default` up one where the option is `tier_eligible` for the higher tier.

The developer can still override any individual rule's tier in the per-rule pass.

## Representative mappings

| Convention | Tier 1 | Tier 2 | Tier 3 |
|------------|--------|--------|--------|
| Tests green before push | `rules/testing.md`: "push only on green" | `untested-edit.sh` warns when src changed, no test changed | `push-gate.sh "tests" "{test_cmd}"` on `Bash(git push *)` |
| No direct push to `main` | `rules/git-workflow.md` | `on-protected-branch.sh` reminds at Stop if on `main` with changes | `protect-main.sh` denies push targeting `main` (or bare push on it) |
| Module boundary | `rules/architecture.md` boundary table | `module-boundary.sh warn` notes cross-feature imports (PostToolUse) | `module-boundary.sh block` denies them (PreToolUse) |
| Lint/typecheck clean | `rules/quality-gates.md` | `lint-on-edit.sh` (touched file only) | `push-gate.sh "lint/typecheck" "{lint_cmd} && {typecheck_cmd}"` |

Hook fragments are JSON files of the shape `{"event": "<HookEventName>", "entry": {...}}`; the generator appends each rendered `entry` to the target project's `settings.json` `hooks.<event>` array and copies the referenced scripts into `.claude/scripts/transcend/`.

## Hook portability

Scripts are POSIX `sh` (no bashisms), parse JSON via `python3` (present on macOS/Linux) rather than `jq`, and avoid `realpath`/`sed -i`. Windows users need a POSIX shell (Git Bash / WSL); a `.cmd` shim is deferred to a later milestone.
