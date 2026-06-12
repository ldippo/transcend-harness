---
session: 2026-06-12-rename-and-m4
status: in-progress
updated: 2026-06-12T20:00:00Z
---
# Handoff: transcend-harness — renamed + published + M4 done, M5 next

## Goal (carved task)
Build transcend-harness per the approved plan (~/.claude/plans/dynamic-stargazing-tarjan.md
— plan text still says "fable"; the project was renamed). M0–M4 done. Next
carve: **M5 (idempotent re-init, monorepo scoping, AUTHORING docs, second
golden fixture)**.

## Done
- M0–M3 + live dry run (commits 2b564db, e8b9652, 4b1794f, 2a57484).
- Renamed fable→transcend everywhere (commit 96ac34d): paths, TRANSCEND_ROOT,
  transcend_* helpers, .claude/.transcend/, plugin/marketplace names; golden
  manifest hashes recomputed. NOTE: the local dir is still
  ~/projects/fable-harness; GitHub repo is github.com/ldippo/transcend-harness
  (private).
- M4 (commit 262e064): signals.python.sh + signals.go.sh probes; detect.sh
  multi-profile scoring (node 90/60, fastapi 90/70, go 90/70, tie→node) with
  ranked candidates; python-fastapi + go-service stack profiles (pkg_run var
  for "uv run"/"poetry run" prefixes, documented in _schema.yaml);
  api-contract-audit + migration-safety catalog entries; /transcend-catalog
  gained a drift guard + template-rendered pointers + manifest hash refresh.
  Tests: sh tests/test-detect.sh (7 scenarios) + tests/test-verify-manifest.sh
  — both passing.

## Next (do these in order)
1. M5: idempotent re-init/upgrade in /transcend-init Step 1 (reuse the M3
   merge-mode machinery in transcend-generator; manifest hash provenance is
   already there).
2. M5: monorepo scoping (scope: subpath/workspaces answers currently dead-end),
   AUTHORING-PILLARS.md + AUTHORING-STACKS.md, /transcend-resume polish.
3. M5: second golden fixture (strict appetite, Tier-2/3 hooks in settings) AND
   the golden-comparison decision: fragments have LLM-filled sections so
   byte-diffs can't pass run-to-run — either make fragments deterministic or
   compare structurally (byte-check only settings.json, scripts,
   handoffs/README, manifest shape).
4. Consider a live /transcend-init dry run against a real fastapi or go scratch
   project (mirrors what the node dry run caught: missing-script reconciliation,
   pointer drift).

## Open questions / blockers
- None.

## Context pointers (read these, not the whole repo)
- docs/ARCHITECTURE.md (layers, manifest, audit/merge semantics, roadmap)
- agents/transcend-generator.md "Merge mode" (machinery M5 re-init reuses)
- skills/transcend-init/SKILL.md Step 1 (re-init guard to upgrade) + Step 2
  (command-var reconciliation)
- core/stacks/python-fastapi.yaml + go-service.yaml (new profile shapes)
- tests/test-detect.sh + tests/test-verify-manifest.sh (behavior contracts)

## Do NOT
- Don't reference ${CLAUDE_PLUGIN_ROOT} in generated project settings.json —
  copy scripts instead.
- Don't put a "_transcend" provenance key inside hook JSON; provenance lives in
  .transcend/manifest.json.
- Don't pass JSON to python via stdin when the program is also on stdin.
- Don't let merge/re-init trust a stale drift report — re-hash at write time.
- Don't flag handoffs/current.md drift in audits — that churn is the loop working.
- Don't freestyle pointer skills — render core/templates/pointer-skill.SKILL.md.tmpl.
- Don't reintroduce "fable" anywhere (grep before committing).
