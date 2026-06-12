# Golden fixture: node-ts-react, strict appetite

Expected /transcend-init output for a node-ts-react project with appetite =
strict: testing and review-quality at Tier 2+3 (advisory + blocking hooks),
project-git at Tier 3 (protect-main + permissions.deny), architecture at
Tier 1, full handoff loop, impeccable + visual-regression wired.

Complements `tests/golden/node-ts-react/` (docs appetite — no enforcement
hooks). Validated structurally by `tests/test-golden-structure.sh`; rendered
prose sections are NOT byte-stable run-to-run (see docs/ARCHITECTURE.md), so
only deterministic artifacts (scripts, settings shape, manifest invariants)
are checked exactly.
