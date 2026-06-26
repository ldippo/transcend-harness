---
name: transcend-init
description: Interview the developer and generate a bespoke, committed .claude/ harness tailored to this project's stack — architecture, testing, context/handoff, git workflow, review/quality gates, and specialized workflows. Use to set up or bootstrap Claude Code conventions for a project.
user-invocable: true
allowed-tools: Read, Bash, AskUserQuestion, Write, Edit, Task
---

# transcend-init

You are running transcend-harness's initialization. Your job: interview the developer,
then generate a bespoke `.claude/` harness in the **target project** and record a
manifest. Follow these steps in order. Do not write any harness files before the
plan-preview confirmation in Step 7.

## Step 0 — Resolve root & detect stack (already run below)

```!
TRANSCEND_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$CLAUDE_SKILL_DIR")/.." && pwd)}"
echo "TRANSCEND_ROOT=$TRANSCEND_ROOT"
echo "PROJECT_DIR=${CLAUDE_PROJECT_DIR:-$(pwd)}"
echo "--- stack detection ---"
sh "$TRANSCEND_ROOT/core/detectors/detect.sh" "${CLAUDE_PROJECT_DIR:-$(pwd)}"
echo "--- existing .claude ---"
if [ -d "${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude" ]; then ls -la "${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude"; else echo "NO_EXISTING_CLAUDE"; fi
if [ -f "${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude/.transcend/manifest.json" ]; then echo "TRANSCEND_MANIFEST_PRESENT"; fi
```

Read `TRANSCEND_ROOT`, `PROJECT_DIR`, the detected stack JSON, and whether a
`.claude/` already exists from the block output above.

## Step 1 — Existing-harness guard

- **`.claude/` exists but NO `TRANSCEND_MANIFEST_PRESENT`** → it's handcrafted. STOP.
  Tell the developer transcend won't overwrite a handcrafted harness and recommend
  running `/transcend-audit` instead. End here unless they explicitly insist.
- **`TRANSCEND_MANIFEST_PRESENT`** → **re-init/upgrade mode**:
  1. Run `sh "$TRANSCEND_ROOT/core/audit/verify-manifest.sh" "$PROJECT_DIR"` and
     read the manifest. Summarize for the developer: current profile, appetite,
     per-pillar options/tiers, catalog, and the drift counts (N pristine, N
     hand-edited, N missing).
  2. Ask (AskUserQuestion): **[Change choices / Upgrade in place / Cancel]**.
     - **Change choices** — continue to Steps 2–6 with the MANIFEST values (not
       the stack profile defaults) pre-selected everywhere; the developer edits
       only what they want changed.
     - **Upgrade in place** — keep all recorded choices; the change set is just
       files whose upstream source changed (compare copied scripts byte-wise
       against `core/scripts/`; treat rendered files as current unless their
       option/tier/vars changed — do not churn pristine prose for no reason).
  3. Compute the change set: every file whose generating inputs changed (option,
     tier, variable bindings, or upstream script). Unchanged inputs → leave the
     file alone even if pristine.
  4. Show the plan (Step 6 style): regenerate / create / delete-nothing, and —
     separately — every **hand-edited** target (drift `modified`) whose inputs
     changed: these are NEVER overwritten; they get diff-style suggestions.
  5. On confirmation, delegate to `transcend-generator` **merge mode** (same
     contract as transcend-audit: re-hash at write time, additive settings
     merge, suggestions for hand-edited/untracked). Additionally have it update
     the manifest's `pillars`/`appetite`/`catalog`/`stack.vars` to the new
     choices and bump `transcend_version` if it changed. Tier *downgrades* must
     remove the now-unwanted hook entries from `settings.json` — removal of a
     transcend-recorded hook entry is allowed in re-init ONLY when
     `settings.json` is pristine; otherwise emit the removal as a suggestion.
- **No `.claude/`** → fresh init. Continue.

## Step 2 — Confirm stack, scope, ownership, appetite (AskUserQuestion, batch A)

Read the detected `profile` from Step 0. Load `$TRANSCEND_ROOT/core/stacks/<profile>.yaml`
(fall back to `unknown.yaml`). Ask up to 4 questions:
1. "Detected stack: **<profile>** (<pkg>). Correct?" → [Yes / Choose another / It's a monorepo].
2. "Scope?" → [Whole repo / A subpath / Multiple workspaces].
3. "Ownership?" → [Commit to `.claude/` — team-shared (recommended) / Personal only].
4. "Overall enforcement appetite?" → [Docs only / Advisory nudges / Strict blocking gates]. This caps per-rule tiers (docs→T1, advisory→T2, strict→T3-eligible).

If the stack is wrong/unknown, ask which of the available `core/stacks/*.yaml`
profiles to use, or proceed with `unknown` and collect the test/lint/typecheck
commands by asking.

**Scope semantics.** The harness ALWAYS lives at the repo root
(`<repo>/.claude/`) — committed once, loaded for every session. Scope changes
what the rules apply to, not where they live:
- **Whole repo** — globs and commands as-is.
- **A subpath** — ask for the path (e.g. `packages/web`). Prefix every rule
  `paths:` glob and `module_boundary_root` with it; prefix commands that must
  run there (e.g. `cd packages/web && npm test`, or `npm test -w packages/web`
  when the root package.json declares workspaces). Manifest records
  `"scope": "subpath", "scope_path": "packages/web"`.
- **Multiple workspaces** — ask which workspaces get a harness now (detect
  candidates from `package.json` `workspaces`, `pnpm-workspace.yaml`, or top
  dirs containing their own `pyproject.toml`/`go.mod`). Run stack detection
  per workspace (`detect.sh <ws>`). Generate ONE shared CLAUDE.md (a short map
  listing workspaces + stacks) and per-workspace rule files
  (`rules/<ws-name>-<pillar>.md`) whose `paths:` globs are prefixed with that
  workspace's path; per-workspace commands in each rule. Hooks stay
  repo-global; their scripts take path prefixes from the matched rule's globs
  where applicable. Manifest records `"scope": "workspaces",
  "workspaces": [{"path": ..., "profile": ..., "vars": {...}}, ...]`. If the
  workspaces use different stacks, run the pillar pass (Step 3) once per
  DISTINCT profile, not once per workspace.

**Reconcile command vars with reality.** Even for a known profile, check the
detector signals: if `has_test_script` / `has_lint_script` /
`has_typecheck_script` is false for a command the profile vars reference (e.g.
vite's react-ts template ships no `test` or `typecheck` script), do NOT write a
command that doesn't exist into the rules. Ask for the real command (one extra
question, or the Other field of batch A), or — if the project genuinely has
none yet — set the var to the conventional command and have the generator mark
it in the affected rule: *"(script not present yet — add `"test": …` to
package.json scripts)"*.

## Step 3 — Pillar option pass (AskUserQuestion, batches B & C)

For each pillar, read `$TRANSCEND_ROOT/core/pillars/<pillar>/pillar.yaml`. Pre-select
the option from the stack profile's `pillar_defaults`. Present the pillar's
`options[].label`/`desc` as the choices.

- **Batch B (4 questions):** architecture, testing, project-git, review-quality
  (review-quality is multiSelect).
- **Batch C:** context-handoff (multiSelect — pre-check `handoff-on-stop` and
  `task-carving`; these are the centerpiece); `delivery-pipeline` (single-select,
  default `none` — the multi-agent PM→architect→coder loop, opt-in and heavy); and,
  if useful, whether to load handoffs on `resume` only or also on `clear`/`compact`
  (default `startup|resume`).

  **Dependency:** `delivery-pipeline: full-pipeline` requires the handoff loop. If
  the developer picks it, ensure context-handoff includes BOTH `handoff-on-stop` and
  `task-carving`; if either was deselected, re-confirm with a one-line note that the
  pipeline depends on them and default them back on. Surface this in the Step 6 preview.

## Step 4 — Per-rule tier selection (AskUserQuestion, batch D)

Only for conventions whose chosen option is `tier_eligible` for more than one tier
AND where the appetite (Step 2.4) permits a tier above 1. For each, default from
the option's `tier_default` adjusted by appetite. Typical questions:
- Testing enforcement → [Doc (T1) / Remind on untested edit (T2) / Block push if red (T3)].
- Protect `<protected_branch>` → [Doc / Remind / Block direct push].
- Module boundary (if architecture has one) → [Doc / Remind / Block cross-boundary edits].
- Lint/typecheck → [Doc / Remind on edit / Block push if failing].

If appetite is "Docs only", SKIP this step entirely (everything is Tier 1).
If a chosen tier's fragment does not exist on disk (not every option ships
hooks), record the intended tier in the manifest, generate the Tier-1 rule, and
tell the developer. Never invent a hook fragment.

## Step 5 — Specialized workflow catalog (AskUserQuestion, batch E)

Read `$TRANSCEND_ROOT/core/catalog/catalog.yaml`. Filter entries whose `stacks`
includes the chosen profile and whose `triggers` match the detector signals.
Present matches as a multiSelect ("Add <id> — <what>?"). Skip if no matches.

## Step 6 — Render plan preview

Compute the variable bindings (see "Variables" below). List EXACTLY the files you
will write and the tier of each enforcement rule. Print the list. Ask the developer
to confirm before writing anything. Do not proceed without confirmation.

## Step 7 — Generate

Write into `PROJECT_DIR/.claude/`. You MAY delegate this materialization to the
`transcend-generator` agent (pass it the resolved bindings + file plan) to keep the
main context clean; for a small harness, doing it inline is fine. Produce:

1. **`.claude/CLAUDE.md`** — render `core/templates/CLAUDE.md.tmpl`. Splice in each
   pillar's `claudemd.*` fragment (rendered with variables) as the
   `{*_summary}` slots. Keep the whole file under 200 lines — if it would exceed
   ~180, shorten summaries (detail already lives in rules/).
2. **`.claude/rules/<pillar>.md`** — for each pillar with a chosen `rule` fragment,
   render it. Expand `{src_globs_yaml}`/`{test_globs_yaml}` into indented YAML list
   items under `paths:`. Fill option-specific content (placement, dependency rules,
   module table, testing expectations) concretely from the chosen option's
   semantics + the detected stack. Always write `rules/task-carving.md` when
   `task-carving` was selected.
3. **`.claude/agents/<name>.md`** — for each chosen pillar option with an `agent`
   render (a single template string OR a list of templates), render each fragment.
   The output filename is the fragment's frontmatter `name:` (`agent.reviewer.md.tmpl`
   → `.claude/agents/reviewer.md`). Substitute the standard vars (`{stack_id}`,
   `{protected_branch}`, `{test_cmd}`, `{lint_cmd}`, `{typecheck_cmd}`); the
   frontmatter (name/description/tools/model/color) passes through verbatim. NEVER
   inject `${CLAUDE_PLUGIN_ROOT}` — generated agents reference `.claude/rules/*` and
   `.claude/scripts/transcend/*` by relative path only. Record each in manifest `files[]`.
4. **`.claude/skills/<id>/SKILL.md`** — for each chosen pillar option with a `skill`
   render (a list of `{id, template}` pairs), render each as a FULL bespoke skill
   (distinct from catalog pointer skills, which come from `catalog[]` and use the
   pointer template). Substitute the standard vars; keep self-contained (reference
   `.claude/...` and `.claude/scripts/transcend/...` only, never
   `${CLAUDE_PLUGIN_ROOT}`). Record in `files[]`. If a `skill` render needs the
   delivery-pipeline issue store, also copy `core/scripts/pipeline/issues.sh` into
   `.claude/scripts/transcend/pipeline/` (chmod +x; record in `files[]`) and create
   an empty `.claude/roadmap.md` + `.claude/issues/.gitkeep` (do NOT record those two
   in `files[]` — the issue store churns by design and is skipped by the verifier).
5. **`.claude/settings.json`** — start from `core/templates/settings.json.tmpl`.
   Each hook fragment is `{"event": "<HookEventName>", "entry": {...}}`: append the
   rendered `entry` to the `hooks.<event>` array, substituting `{script_ref}` and
   the command vars in `args` (see Variables), and copy the referenced scripts
   into `.claude/scripts/transcend/`. Add `permissions.deny` entries that
   belt-and-suspender a blocking hook (e.g. `"Bash(git push origin <branch>*)"`).
   Omit the `hooks` key entirely if appetite is Docs-only AND no handoff auto-load.
   NOTE: the SessionStart load-handoff + Stop nudge hooks are generated whenever
   `handoff-on-stop` is selected, regardless of appetite (they're context tooling,
   not enforcement).
6. **`.claude/handoffs/`** — write `README.md` (from `handoffs/README.md.tmpl`) and
   `current.md` (from `handoffs/current.md.tmpl`, status `done`).
7. **Catalog wiring** — for each chosen catalog entry: splice its `wiring.claudemd`
   line into the CLAUDE.md "Specialized workflows" section; append its
   `wiring.pillar_step.text` to the named pillar's rule; if `pointer_skill: true`,
   render `core/templates/pointer-skill.SKILL.md.tmpl` to
   `.claude/skills/<id>/SKILL.md` filling `{id}`/`{what}`/`{when}` from the
   catalog entry and `{pillar_rule_ref}` = `.claude/rules/<pillar's rule file>`.
   Do not freestyle pointer skills — the template is the contract.
8. **`.claude/.transcend/manifest.json`** — per `docs/ARCHITECTURE.md`: transcend_version
   (read from `$TRANSCEND_ROOT/.claude-plugin/plugin.json`), generated_at (use the
   timestamp from the shell block — run `date -u +%Y-%m-%dT%H:%M:%SZ` if you need
   it), stack (profile/confidence/key vars), scope, ownership, script_mode,
   appetite, per-pillar option+tier, catalog list, and `files[]` with each written
   file's path + `sha256:` of its content (compute with
   `shasum -a 256 <file>` or `python3`).
9. **`.gitignore`** — append `core/templates/gitignore.snippet` (skip if already
   present). Write personal bits to `.claude/settings.local.json` from
   `settings.local.json.tmpl` if ownership is personal or there are personal allows.

Do NOT git-commit. After writing, print a summary and the suggested commands:
`git add .claude .gitignore && git commit -m "chore: add transcend harness"`.

## Variables (for fragment substitution)

Resolve from the chosen stack profile `vars`, the interview answers, and computed
values. `{pkg}` is the detector's resolved package manager; expand command vars
like `{test_cmd}` = `"{pkg} test"` → e.g. `pnpm test`.

- `{transcend_version}` — from `.claude-plugin/plugin.json`.
- `{stack_id}`, `{pkg}`, `{test_cmd}`, `{lint_cmd}`, `{typecheck_cmd}`, `{build_cmd}`.
- `{protected_branch}` — from profile vars (default `main`).
- `{src_globs_yaml}` / `{test_globs_yaml}` — profile `src_globs`/`test_globs`
  rendered as indented YAML list lines (e.g. `  - "src/**/*.ts"`).
- `{architecture_label}`, `{architecture_description}`, `{architecture_one_liner}`,
  placement/dependency/module table — from the chosen architecture option + stack.
- `{testing_label}`, `{testing_description}`, `{testing_expectation}`,
  `{testing_one_liner}`, `{testing_tier_note}` — from chosen testing option + tier.
- `{gitflow_label}`, `{gitflow_description}`, branch/PR/commit rules.
- `{gates_list}`, `{gates_summary}`, `{quality_extra_checklist}`, `{quality_tier_note}`.
- `{workflows_list}` / `{workflows_summary}` — bullet list of chosen catalog
  entries' `wiring.claudemd` lines, or "None configured." if empty.
- `{pipeline_summary}` — the delivery-pipeline `claudemd` fragment if
  `full-pipeline` is chosen; empty string if `none` (the slot collapses).
- `{script_ref}` — ALWAYS `${CLAUDE_PROJECT_DIR}/.claude/scripts/transcend` (the
  literal string; Claude Code substitutes it at hook time). Copy the needed
  scripts (`lib/common.sh` plus each referenced event script, preserving the
  `lib/` relative layout since scripts source `../lib/common.sh`) from
  `$TRANSCEND_ROOT/core/scripts/` into `.claude/scripts/transcend/` and `chmod +x` them.
  Rationale: `${CLAUDE_PLUGIN_ROOT}` is only substituted for hooks a plugin
  itself defines — it does NOT resolve in a project's committed settings.json —
  and a team-shared harness must work for teammates who don't have transcend
  installed. The committed harness is self-contained.

## Principles to honor

Read `$TRANSCEND_ROOT/core/principles/00-philosophy.md` and
`$TRANSCEND_ROOT/core/principles/01-context-as-environment.md`. Keep CLAUDE.md terse,
push detail into rules/, block only what must not happen, and make the handoff loop
work. Treat context as an environment: when the delivery pipeline or any workflow
fans out subagents, carry declared outputs only, let the scout emit the work-list,
and bound recursion (depth/calls/budget/timeout). The generated harness is owned by
the project — generate clean, hand-editable files.
