# Golden fixture: node-ts-react

Expected `.claude/` output of `/fable-init` for a Node + TypeScript + React project
(pnpm), used as a regression baseline and as a worked example of generator output.

## Scenario (interview answers)

| Question | Answer |
|----------|--------|
| Stack | node-ts-react (pnpm), confidence 0.9 |
| Scope / ownership | whole repo / team-shared (committed) |
| Enforcement appetite | **docs** (Tier 1 only) |
| Architecture | feature-sliced |
| Testing | test-after |
| Project/git | github-flow |
| Review/quality | lint-typecheck-gate + pre-pr-self-review |
| Context/handoff | handoff-on-stop + task-carving |
| Catalog | impeccable, visual-regression |
| Script mode | copy (`.claude/scripts/fable/`, referenced via `${CLAUDE_PROJECT_DIR}`) |

## What this demonstrates

- A complete Tier-1 harness: terse `CLAUDE.md` (31 lines) importing five
  path-scoped `rules/*.md`.
- The **context/handoff loop** fully wired even at docs appetite: the SessionStart
  load-handoff hook and the Stop nudge hook are present in `settings.json` (they're
  context tooling, not enforcement), with the handoff scaffold under `handoffs/`.
- **Self-contained hooks**: scripts are copied into `.claude/scripts/fable/` and
  referenced via `${CLAUDE_PROJECT_DIR}`, so teammates who clone the repo get
  working hooks without having fable installed (`${CLAUDE_PLUGIN_ROOT}` does not
  resolve in a project's committed settings.json).
- Catalog wiring: pointer skills under `skills/`, plus checklist lines appended to
  `rules/quality-gates.md` and bullets in CLAUDE.md's "Specialized workflows".
- A `.fable/manifest.json` recording every choice and a real sha256 per file, so
  `/fable-audit` can detect hand-edits as drift.

## Notes on higher appetites (M2)

At `advisory` or `strict` appetite, the generator additionally emits Tier-2/3
hooks (e.g. `push-requires-green`, `protect-main`, `lint-on-edit`) into
`settings.json`, adds a belt-and-suspenders `permissions.deny` for blocked
pushes, and records the per-rule tier in the manifest. Those fragments/scripts
land in M2; this fixture intentionally shows the docs-only baseline.

## Regenerating

If a template changes, regenerate this fixture and refresh the manifest hashes
(`python3` over `.claude/**` with `hashlib.sha256`). Keep `generated_at` and the
`current.md` `updated` timestamps fixed (`2026-06-12T00:00:00Z`) so diffs stay
stable.
