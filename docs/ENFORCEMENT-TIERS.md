# Enforcement tiers

Every convention fable codifies can be rendered at one of three tiers. The tier is
chosen per-rule during the interview, defaulting from the option's `tier_default`
in `pillar.yaml` adjusted by the project's overall enforcement appetite.

| Tier | Mechanism | Blocks? | Renders |
|------|-----------|---------|---------|
| 1 — DOCS | `CLAUDE.md` summary + `.claude/rules/<x>.md` (path-scoped via `paths:`) | no | `rule.*` + `claudemd.*` fragment |
| 2 — ADVISORY | non-blocking `PostToolUse` / `Stop` hook that prints a reminder | no | + `hook.advisory.*` block & script |
| 3 — BLOCKING | `PreToolUse` hook that returns `permissionDecision: deny` (exit 2) | yes | + `hook.blocking.*` block & script |

Tier 1 is always emitted. Tier 2 and Tier 3 are additive. A single convention may
be both Tier 2 and Tier 3 (e.g. nudge on every untested edit AND hard-block the
push).

## Appetite → default mapping

The interview asks for an overall appetite once, which caps and seeds per-rule
defaults:

- **docs-only** → cap at Tier 1 (no hooks generated).
- **advisory** → cap at Tier 2; `tier_default` of 3 is clamped to 2.
- **strict** → allow Tier 3; bump each option's `tier_default` up one where the
  option is `tier_eligible` for the higher tier.

The developer can still override any individual rule's tier in the per-rule pass.

## Representative mappings

| Convention | Tier 1 | Tier 2 | Tier 3 |
|------------|--------|--------|--------|
| Tests green before push | `rules/testing.md`: "push only on green" | `untested-edit.sh` warns when src changed, no test changed | `push-requires-green.sh` on `Bash(git push *)` |
| No direct push to `main` | `rules/git-workflow.md` | `Stop` reminds if on `main` with commits | `protect-main.sh` on `Bash(git push origin main*)` |
| Module boundary | `rules/architecture.md` boundary table | warns on cross-boundary import | `module-boundary.sh` denies cross-boundary import |
| Lint/typecheck clean | `rules/quality-gates.md` | `lint-on-edit.sh` (touched file only) | `push-requires-lint.sh` |

## Hook portability

Scripts are POSIX `sh` (no bashisms), parse JSON via `python3` (present on
macOS/Linux) rather than `jq`, and avoid `realpath`/`sed -i`. Windows users need a
POSIX shell (Git Bash / WSL); a `.cmd` shim is deferred to a later milestone.
