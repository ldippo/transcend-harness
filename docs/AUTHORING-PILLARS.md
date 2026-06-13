# Authoring a pillar

A pillar is one axis of convention the interview covers (architecture, testing,
…). Each pillar directory under `core/pillars/<id>/` contains:

- `pillar.yaml` — the machine spec driving the interview.
- `fragments/*.tmpl` — the artifacts options render.

## 1. `pillar.yaml`

Model on `core/pillars/testing/pillar.yaml`. Fields:

- `id`, `title`, `question`, `header` — interview presentation. `header` must
  fit AskUserQuestion's 12-char chip.
- `multiSelect` — true when options are complementary (review-quality,
  context-handoff), false when exclusive (architecture, testing).
- `principle` — the `core/principles/pillar-<id>.md` essay; write it first, it
  forces clarity on what the pillar is *for*.
- `options[]` — 3–4 realistic choices. Each needs:
  - `id`, `label` (1–5 words), `desc` (one sentence, ends with the trade-off).
  - `renders` — fragment paths this option emits: `claudemd` (terse CLAUDE.md
    summary) and `rule` (the detailed `.claude/rules/` file) at minimum;
    `advisory_hook` / `blocking_hook` / `agent` when enforceable.
  - `tier_eligible` / `tier_default` — which enforcement tiers make sense (see
    `docs/ENFORCEMENT-TIERS.md`). An option with no hook fragments is
    `tier_eligible: [1]`.
- `default_selected` on options (multiSelect pillars only).

Stack profiles pre-select options via `pillar_defaults` — update every
`core/stacks/*.yaml` to name a default option for the new pillar.

## 2. Fragments

- `claudemd.*.md.tmpl` — ≤5 lines; one summary sentence + `Details:
  @.claude/rules/<file>` pointer. CLAUDE.md must stay under 200 lines total.
- `rule.*.md.tmpl` — starts with `paths:` frontmatter using
  `{src_globs_yaml}`/`{test_globs_yaml}`; states rules imperatively; ends with
  the tier note (`{*_tier_note}`).
- `hook.advisory.*.json.tmpl` / `hook.blocking.*.json.tmpl` — shape
  `{"event": "<HookEventName>", "entry": {...}}`; commands reference
  `{script_ref}/...` (the copied-scripts dir). The script itself goes in
  `core/scripts/advisory/` or `core/scripts/blocking/` — POSIX sh, source
  `../lib/common.sh`, never block on missing python, exit fast on
  non-matching input. Advisory hooks must be once-per-session
  (`transcend_once`) or scoped to the touched file; blocking hooks must be
  narrowly matched (`if:`/matcher) so they never fire on unrelated tool use.
- `agent.*.md.tmpl` — a generated subagent. Agent frontmatter
  (`name`/`description`/`tools`/`model`/`color`) passes through verbatim; the output
  filename is the `name:`. Rendered to `.claude/agents/<name>.md`. `renders.agent`
  may be a single template string or a list. Agents must be self-contained — they
  reference `.claude/rules/*` and `.claude/scripts/transcend/*` only, never
  `${CLAUDE_PLUGIN_ROOT}`.
- `skill.*.md.tmpl` — a generated FULL skill (distinct from catalog pointer skills).
  `renders.skill` is a list of `{id, template}` pairs, each rendered to
  `.claude/skills/<id>/SKILL.md`. Same self-containment rule. If a skill drives a
  helper script (e.g. the delivery-pipeline issue store), put the script in
  `core/scripts/<group>/` and have the generator copy it byte-identical (it joins the
  golden byte-check) — never template a copied script.

Placeholders use single braces (`{pkg}`, `{test_cmd}`); the full variable list
lives in `skills/transcend-init/SKILL.md` → "Variables". A fragment may also
declare option-specific slots the generator fills from the option's semantics —
keep those minimal: every freeform slot is a spot where regeneration output
varies (see the golden-fixture note in `docs/ARCHITECTURE.md`).

## 3. Wire into the interview

`skills/transcend-init/SKILL.md` Step 3 reads pillars generically — a new
pillar only needs to be assigned to batch B or C there (and to the Step 7 file
list if it renders something beyond the standard claudemd/rule/hook set).
Add the pillar to the auditor's "missing pillars" expectation
(`agents/transcend-auditor.md`) and to `core/templates/CLAUDE.md.tmpl` if it
gets its own summary slot.

## 4. Test it

Golden fixtures must include the new pillar's rule file —
`tests/test-golden-structure.sh` asserts the expected file set per fixture.
If the pillar ships hooks, exercise the scripts directly (feed them sample
hook JSON on stdin; assert deny/context output) the way M2 did.
