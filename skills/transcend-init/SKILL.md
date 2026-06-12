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
- **`TRANSCEND_MANIFEST_PRESENT`** → re-init/upgrade mode. Read the manifest; you'll
  merge (regenerate only changed choices, preserve hand-edited files — a file
  whose on-disk sha256 differs from the manifest's recorded hash is hand-edited:
  propose changes, do not overwrite). (Full merge logic is M5; for now, confirm
  with the developer before regenerating anything.)
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
  `task-carving`; these are the centerpiece) plus, if useful, ask whether to load
  handoffs on `resume` only or also on `clear`/`compact` (default `startup|resume`).

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
3. **`.claude/settings.json`** — start from `core/templates/settings.json.tmpl`.
   Each hook fragment is `{"event": "<HookEventName>", "entry": {...}}`: append the
   rendered `entry` to the `hooks.<event>` array, substituting `{script_ref}` and
   the command vars in `args` (see Variables), and copy the referenced scripts
   into `.claude/scripts/transcend/`. Add `permissions.deny` entries that
   belt-and-suspender a blocking hook (e.g. `"Bash(git push origin <branch>*)"`).
   Omit the `hooks` key entirely if appetite is Docs-only AND no handoff auto-load.
   NOTE: the SessionStart load-handoff + Stop nudge hooks are generated whenever
   `handoff-on-stop` is selected, regardless of appetite (they're context tooling,
   not enforcement).
4. **`.claude/handoffs/`** — write `README.md` (from `handoffs/README.md.tmpl`) and
   `current.md` (from `handoffs/current.md.tmpl`, status `done`).
5. **Catalog wiring** — for each chosen catalog entry: splice its `wiring.claudemd`
   line into the CLAUDE.md "Specialized workflows" section; append its
   `wiring.pillar_step.text` to the named pillar's rule; if `pointer_skill: true`,
   render `core/templates/pointer-skill.SKILL.md.tmpl` to
   `.claude/skills/<id>/SKILL.md` filling `{id}`/`{what}`/`{when}` from the
   catalog entry and `{pillar_rule_ref}` = `.claude/rules/<pillar's rule file>`.
   Do not freestyle pointer skills — the template is the contract.
6. **`.claude/.transcend/manifest.json`** — per `docs/ARCHITECTURE.md`: transcend_version
   (read from `$TRANSCEND_ROOT/.claude-plugin/plugin.json`), generated_at (use the
   timestamp from the shell block — run `date -u +%Y-%m-%dT%H:%M:%SZ` if you need
   it), stack (profile/confidence/key vars), scope, ownership, script_mode,
   appetite, per-pillar option+tier, catalog list, and `files[]` with each written
   file's path + `sha256:` of its content (compute with
   `shasum -a 256 <file>` or `python3`).
7. **`.gitignore`** — append `core/templates/gitignore.snippet` (skip if already
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

Read `$TRANSCEND_ROOT/core/principles/00-philosophy.md`. Keep CLAUDE.md terse, push
detail into rules/, block only what must not happen, and make the handoff loop
work. The generated harness is owned by the project — generate clean, hand-editable
files.
