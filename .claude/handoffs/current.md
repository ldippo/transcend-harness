---
session: 2026-06-12-m3-complete
status: in-progress
updated: 2026-06-12T18:30:00Z
---
# Handoff: fable-harness — M3 complete, M4 next

## Goal (carved task)
Build fable-harness per the approved plan (~/.claude/plans/dynamic-stargazing-tarjan.md).
M0–M3 are done and committed. Next carve: **M4 (more stacks + catalog wiring)**.
The live end-to-end dry run of /fable-init against a scratch project is still
outstanding and recommended before or during M4 (it shakes out the interview flow).

## Done
- M0/M1 — packaging, CORE library, skills/agents, handoff loop, golden fixture
  (commit 2b564db).
- M2 — layered enforcement: hooks, scripts, reviewer agent (commit e8b9652).
- M3 — audit engine (commit 4b1794f): `core/audit/verify-manifest.sh` drift
  verifier (behavior tests: `sh tests/test-verify-manifest.sh` — passing);
  fable-auditor emits apply plans (create/regenerate/append/settings-merge)
  only for pristine/new targets; fable-audit Step 3 safe-apply flow;
  fable-generator merge mode re-hashes at write time, never overwrites
  hand-edited/untracked files, stamps manifest `last_merge`. Acceptance-tested
  live: hand-edited rule preserved through a merge containing a hostile
  regenerate plan against it.

## Next (do these in order)
1. M4: python-fastapi + go-service stack profiles, detector signals for both
   (extend core/detectors/ with signals.python.sh / signals.go.sh, score in
   detect.sh), catalog wiring via /fable-catalog.
2. Live dry run: scaffold a scratch vite react app, run /fable-init end-to-end
   (interview → generate), compare output to tests/golden/node-ts-react/.
3. M5: idempotent re-init merge (reuse the M3 merge-mode machinery), monorepo
   scoping, AUTHORING-PILLARS/STACKS docs, second golden fixture (strict
   appetite — shows Tier-2/3 hooks in settings).

## Open questions / blockers
- None.

## Context pointers (read these, not the whole repo)
- docs/ARCHITECTURE.md (layers, manifest format incl. last_merge, audit/merge
  semantics, roadmap w/ status)
- core/audit/verify-manifest.sh + tests/test-verify-manifest.sh (drift contract)
- agents/fable-generator.md "Merge mode" (safety rules — re-hash at write time)
- core/detectors/detect.sh + core/stacks/_schema.yaml (what M4 extends)
- core/catalog/catalog.yaml + skills/fable-catalog/SKILL.md (M4 wiring target)

## Do NOT
- Don't reference ${CLAUDE_PLUGIN_ROOT} in generated project settings.json —
  it only resolves for plugin-defined hooks; copy scripts instead.
- Don't put a "_fable" provenance key inside hook JSON (schema rejects unknown
  keys); provenance lives in .fable/manifest.json.
- Don't pass JSON to python via stdin when the program is also on stdin.
- Don't let merge mode trust the audit's drift report — targets must be
  re-hashed at write time (audits go stale).
- Don't flag handoffs/current.md drift in audits — that churn is the loop working.
