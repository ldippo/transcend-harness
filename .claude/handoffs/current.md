---
session: 2026-06-12-m2-complete
status: in-progress
updated: 2026-06-12T17:30:00Z
---
# Handoff: fable-harness — M2 complete, M3 next

## Goal (carved task)
Build fable-harness per the approved plan (~/.claude/plans/dynamic-stargazing-tarjan.md).
M0–M2 are done and committed. Next carve: **M3 (fable-audit apply/merge)** — or,
if preferred, a live end-to-end dry run of /fable-init against a scratch project
first (recommended before M3; it shakes out the interview flow).

## Done
- M0 — packaging skeleton (commit 2b564db).
- M1 — CORE library (6 pillars, 2 stack profiles, node detector, catalog,
  templates), 5 skills, 3 agents, working handoff loop, golden fixture
  (commit 2b564db).
- M2 — layered enforcement: 6 hook scripts + 8 fragments + reviewer agent
  template, all behavior-tested (commit e8b9652).
- Review fixes: self-contained copied scripts (CLAUDE_PLUGIN_ROOT doesn't
  resolve in project settings), fable_json_get stdin bug, once-per-session
  advisory hooks, protect-main bare-push heuristic.

## Next (do these in order)
1. Live dry run: scaffold a scratch vite react app, run /fable-init end-to-end
   (interview → generate), compare output to tests/golden/node-ts-react/.
2. M3: fable-audit safe-apply/merge — generator `--merge` respecting manifest
   hash provenance (hand-edited files become suggestions, never overwrites).
3. M4: python-fastapi + go-service stack profiles, detector signals for both,
   catalog wiring via /fable-catalog.
4. M5: idempotent re-init, monorepo scoping, AUTHORING-PILLARS/STACKS docs,
   second golden fixture (strict appetite — shows Tier-2/3 hooks in settings).

## Open questions / blockers
- None. (User decision pending: dry-run-first vs straight to M3 — ask.)

## Context pointers (read these, not the whole repo)
- docs/ARCHITECTURE.md (layers, FABLE_ROOT, manifest format, roadmap w/ status)
- docs/ENFORCEMENT-TIERS.md (tier model, fragment {event,entry} format)
- skills/fable-init/SKILL.md (the generation contract — Step 7 + Variables)
- tests/golden/node-ts-react/ (canonical expected output)

## Do NOT
- Don't reference ${CLAUDE_PLUGIN_ROOT} in generated project settings.json —
  it only resolves for plugin-defined hooks; copy scripts instead.
- Don't put a "_fable" provenance key inside hook JSON (schema rejects unknown
  keys); provenance lives in .fable/manifest.json.
- Don't pass JSON to python via stdin when the program is also on stdin.
