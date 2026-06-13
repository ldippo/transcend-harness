---
paths:
  - "src/**/*.ts"
  - "src/**/*.tsx"
---
# Architecture — Feature-sliced

Code is grouped by feature. Each feature owns its components, hooks, state, and
tests; shared, cross-feature code lives in a dedicated shared layer.

## Where code lives
- Feature code: `src/features/<feature>/` (components, hooks, logic, tests).
- Cross-feature/shared code: `src/shared/` (ui primitives, utils, types).
- App shell / routing: `src/app/`.

## Dependency rules
- A feature may import from `src/shared` and its own folder.
- A feature must NOT import from another feature directly — extract to `src/shared`
  or expose a public surface instead.
- Cross-module imports go through the declared shared/public surface only.

## Module boundaries
| Module | May depend on | Must NOT import |
|--------|---------------|-----------------|
| `src/features/*` | `src/shared`, own folder | other `src/features/*` |
| `src/shared` | `src/shared` | any `src/features/*` |

When adding code, place it according to the structure above rather than inventing
a new layout. If a genuinely new kind of module is needed, note it in the handoff
and keep the boundary table updated.
