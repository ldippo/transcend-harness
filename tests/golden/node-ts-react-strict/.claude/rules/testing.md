---
paths:
  - "src/**/*.ts"
  - "src/**/*.tsx"
  - "**/*.test.ts"
  - "**/*.test.tsx"
  - "**/*.spec.ts"
---
# Testing — Test-after

Implement, then cover the new behavior with tests before the change ships. Tests
are written after the code, but in the same session/PR — untested behavioral
changes do not merge.

## Commands
- Run tests: `pnpm test`

## Expectations
- Every behavioral change is covered by tests before it ships.
- Tests live alongside the code they cover (`*.test.ts`, `*.test.tsx`, `*.spec.ts`).
- A behavioral change ships with a test that would fail without it.

Enforcement: Tier 3 (strict). Editing source files without touching any test
triggers a one-time advisory reminder per session, and `git push` is blocked
unless `pnpm test` passes.
