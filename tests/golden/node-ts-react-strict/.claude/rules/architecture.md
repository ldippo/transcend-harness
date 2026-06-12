---
paths:
  - "src/**/*.ts"
  - "src/**/*.tsx"
---
# Architecture — Feature-sliced

Code is grouped by feature under `src/features/<feature>`: each feature owns its
components, hooks, state, and tests. Cross-cutting code (UI primitives, utilities,
shared types) lives in the shared layer, and features must not reach into each
other's internals.

## Where code lives
- New feature code goes in `src/features/<feature>/` (components, hooks, state, and tests together). Cross-cutting utilities, UI primitives, and shared types go in `src/shared/`. App wiring (routing, providers, entry point) stays at the app level, outside individual features.

## Dependency rules
- A feature may import from `src/shared/` and external packages — never from another feature's internals under `src/features/*`.
- Cross-module imports go through the declared shared/public surface only.

## Module boundaries
| Module | May depend on | Must NOT import |
|--------|---------------|-----------------|
| `src/features/<feature>` | `src/shared`, external packages | other `src/features/*` internals |
| `src/shared` | external packages | `src/features/*` |

When adding code, place it according to the structure above rather than inventing
a new layout. If a genuinely new kind of module is needed, note it in the handoff
and keep the boundary table updated.
