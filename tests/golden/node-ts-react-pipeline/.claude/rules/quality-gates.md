---
paths:
  - "src/**/*.ts"
  - "src/**/*.tsx"
---
# Review & quality gates

Gates enabled for this project: lint + typecheck, pre-PR self-review.

## Commands
- Lint: `pnpm run lint`
- Typecheck: `pnpm run typecheck`

## Self-review checklist (run against your own diff before a PR)
- Scope matches the carved task; no unrelated changes.
- Tests added/updated and green (`pnpm test`).
- No leftover debug logging, TODOs without owners, or commented-out code.
- Naming and placement follow @.claude/rules/architecture.md.
- Run `impeccable` on changes that touch UI components.
- Run `visual-regression` and review diffs before merging UI changes.

These gates are documented (Tier 1). Re-run `/transcend-init` with a higher appetite to
add advisory or blocking enforcement hooks.
