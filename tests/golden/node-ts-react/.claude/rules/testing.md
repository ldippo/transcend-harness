---
paths:
  - "src/**/*.ts"
  - "src/**/*.tsx"
  - "**/*.test.ts"
  - "**/*.test.tsx"
  - "**/*.spec.ts"
---
# Testing — Test-after

Implement the change, then cover its behavior with tests before it ships.

## Commands
- Run tests: `pnpm test`

## Expectations
- Every behavioral change ships with a test that would fail without it.
- Tests live alongside the code they cover (`*.test.ts` / `*.test.tsx`).
- Prefer testing behavior through the public surface of a feature over internals.

This convention is documented (Tier 1). Push gating on green tests can be added by
re-running `/fable-init` with a higher enforcement appetite.
