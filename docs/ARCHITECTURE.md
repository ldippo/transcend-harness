# fable-harness architecture

fable-harness has three layers:

- **CORE library** (`core/`) — pure data, never executed as a program. Principles,
  per-pillar option sets and render fragments, stack profiles, detectors, the
  curated catalog, hook scripts, and top-level templates.
- **Adaptation engine** — the `fable-init` skill. Drives an interview
  (`AskUserQuestion`), maps answers to chosen templates + enforcement tiers, and
  writes files into the target project's `./.claude/`. Heavy file materialization
  is delegated to the `fable-generator` agent.
- **Audit engine** — the `fable-audit` skill + `fable-auditor` agent. Inspects an
  existing harness via the drift verifier (`core/audit/verify-manifest.sh`),
  proposes diff-style improvements, and safe-applies the additive ones through
  `fable-generator` merge mode.

## FABLE_ROOT resolution

Skills must read `core/` regardless of install mode. Every entry skill resolves a
single `FABLE_ROOT` at startup:

```sh
FABLE_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$CLAUDE_SKILL_DIR")/.." && pwd)}"
```

- **Plugin mode** — `$CLAUDE_PLUGIN_ROOT` is set by Claude Code to this repo's root.
- **Plain-repo mode** — `$CLAUDE_PLUGIN_ROOT` is unset; we fall back to the parent
  of the skill directory's parent (`skills/<name>/` → repo root).

Hook scripts are ALWAYS copied into the target project
(`./.claude/scripts/fable/`, preserving the `lib/` layout) and referenced as
`${CLAUDE_PROJECT_DIR}/.claude/scripts/fable/...`. Two reasons:
`${CLAUDE_PLUGIN_ROOT}` is only substituted for hooks a plugin itself defines —
it does not resolve in a project's committed `settings.json` — and a team-shared
harness must work for teammates who don't have fable installed. The manifest
records `script_mode: "copy"` (other modes reserved for the future).

## Generated harness manifest

Every generated harness writes `./.claude/.fable/manifest.json` in the target
project. It is the source of truth for idempotent re-init and for audit
provenance. Shape:

```json
{
  "fable_version": "0.1.0",
  "generated_at": "2026-06-12T15:30:00Z",
  "stack": {
    "profile": "node-ts-react",
    "confidence": 0.9,
    "vars": { "pkg": "pnpm", "test_cmd": "pnpm test -- --run" }
  },
  "scope": "repo",
  "ownership": "team",
  "script_mode": "copy",
  "appetite": "strict",
  "pillars": {
    "architecture":    { "option": "feature-sliced", "tier": 1 },
    "testing":         { "option": "test-after",     "tier": 3 },
    "context-handoff": { "options": ["handoff-on-stop", "task-carving"] },
    "project-git":     { "option": "github-flow",    "tier": 3 },
    "review-quality":  { "options": ["lint-typecheck-gate", "pre-pr-self-review"], "tier": 2 }
  },
  "catalog": ["impeccable", "visual-regression"],
  "files": [
    { "path": ".claude/CLAUDE.md",            "hash": "sha256:..." },
    { "path": ".claude/rules/testing.md",     "hash": "sha256:..." }
  ],
  "last_handoff": ".claude/handoffs/2026-06-12-1530-auth.md"
}
```

`files[].hash` is the sha256 of the content fable wrote. On re-init/audit, a file
whose current hash differs from the recorded hash is treated as **hand-edited**:
it is preserved and any change becomes a suggestion, never an overwrite.

## Audit & safe-apply merge

`core/audit/verify-manifest.sh <project>` is the deterministic drift check: it
compares every manifest-recorded file's on-disk sha256 against the recorded hash
and emits `{summary, files[{path,status}], untracked[]}` with statuses `ok`
(pristine — safe to regenerate), `modified` (hand-edited — preserve, suggest
only), and `missing`. It skips `.fable/`, `handoffs/` (dated files churn by
design; `handoffs/current.md` will normally read `modified` — that's the loop
working), and `settings.local.json`. Behavior-tested by
`tests/test-verify-manifest.sh`.

`fable-audit` Step 3 routes confirmed fixes to `fable-generator` **merge mode**
with actions `create` / `regenerate` / `append` / `settings-merge` (additive
hooks/permissions only). The generator re-hashes each target at write time —
hand-edited and untracked files are never written, only suggested. Applied
merges refresh the affected `files[]` hashes and stamp a top-level
`last_merge` timestamp in the manifest; `generated_at` is never rewritten.

## Interview → generation flow

See `skills/fable-init/SKILL.md`. Summary: detect stack → guard against clobbering
an existing harness → confirm stack/scope/appetite → pillar option pass → per-rule
tier selection → catalog recommendation → plan preview → generate.

## Enforcement tiers

See `docs/ENFORCEMENT-TIERS.md`. Tier 1 always renders a rule + CLAUDE.md
fragment; Tier 2 adds an advisory hook; Tier 3 adds a blocking hook. A convention
can be both Tier 2 and Tier 3.

## Roadmap

- **M0** — skeleton & packaging. *(done)*
- **M1** — minimal end-to-end spine: node-ts-react + unknown profiles, node
  detector, `fable-init` covering all six pillars at Tier-1 docs, plus the full
  context/handoff loop (handoff template + `fable-handoff` + SessionStart load
  hook). Golden fixture. *(done — commit 2b564db)*
- **M2** — layered enforcement: Tier 2/3 hook recipes + `core/scripts/`, per-rule
  tier interview, merged `settings.json`. *(done — commit e8b9652)*
- **M3** — `fable-audit`: inventory/critique vs manifest, diff suggestions,
  safe-apply merge. *(done — commit 4b1794f)*
- **M4** — more stacks + catalog wiring + `fable-catalog`.
- **M5** — idempotent re-init/upgrade, monorepo support, `fable-resume` polish,
  more golden fixtures.
