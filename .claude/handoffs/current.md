---
session: 2026-06-12-dryrun-complete
status: in-progress
updated: 2026-06-12T19:00:00Z
---
# Handoff: transcend-harness — live dry run done, M4 next

## Goal (carved task)
Build transcend-harness per the approved plan (~/.claude/plans/dynamic-stargazing-tarjan.md).
M0–M3 done; live /transcend-init dry run done. Next carve: **M4 (more stacks +
catalog wiring via /transcend-catalog)**.

## Done
- M0–M2 — spine, enforcement (commits 2b564db, e8b9652).
- M3 — audit engine: drift verifier, apply plans, generator merge mode
  (commit 4b1794f). Tests: `sh tests/test-verify-manifest.sh`.
- Live /transcend-init dry run (commit 2a57484): scaffolded vite react-ts app in
  /tmp, ran detect → interview (batches A–C, E; D correctly skipped on docs
  appetite) → plan preview → transcend-generator. Output: manifest self-verified
  (14/14 ok), settings.json + scripts + handoffs/README byte-identical to
  golden, handoff hook verified live (silent on done, injects on in-progress).
  Fixes applied: pointer-skill template (core/templates/pointer-skill.SKILL.md.tmpl
  is now the contract) and Step-2 reconciliation of command vars vs
  has_*_script detector signals (vite template has no test/typecheck script).

## Next (do these in order)
1. M4: python-fastapi + go-service stack profiles, detector signals
   (signals.python.sh / signals.go.sh, score in detect.sh), catalog wiring via
   /transcend-catalog. Catalog needs non-react entries or M4 stacks get an empty
   batch E.
2. M5: idempotent re-init merge (reuse M3 merge-mode machinery), monorepo
   scoping, AUTHORING docs, second golden fixture (strict appetite).
   IMPORTANT M5 design note from the dry run: rule/CLAUDE.md fragments contain
   LLM-filled sections, so byte-diff against golden fixtures can NOT pass
   run-to-run. Either make fragments fully deterministic or make golden
   comparison structural (file set + frontmatter + key invariants + the
   byte-stable subset: settings.json, scripts, handoffs/README, manifest shape).

## Open questions / blockers
- None.

## Context pointers (read these, not the whole repo)
- docs/ARCHITECTURE.md (layers, manifest, audit/merge semantics, roadmap)
- core/detectors/detect.sh + signals.node.sh (pattern M4 extends)
- core/stacks/node-ts-react.yaml + _schema.yaml (profile shape)
- core/catalog/catalog.yaml + skills/transcend-catalog/SKILL.md (M4 wiring target)
- skills/transcend-init/SKILL.md Step 2 (command-var reconciliation) + Step 7.5
  (pointer-skill template contract)

## Do NOT
- Don't reference ${CLAUDE_PLUGIN_ROOT} in generated project settings.json —
  copy scripts instead.
- Don't put a "_transcend" provenance key inside hook JSON; provenance lives in
  .transcend/manifest.json.
- Don't pass JSON to python via stdin when the program is also on stdin.
- Don't let merge mode trust the audit's drift report — re-hash at write time.
- Don't flag handoffs/current.md drift in audits — that churn is the loop working.
- Don't freestyle pointer skills — render core/templates/pointer-skill.SKILL.md.tmpl.
