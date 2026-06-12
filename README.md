# transcend-harness

A meta-framework that, run inside any project, **interviews the developer, detects the stack, and generates a bespoke, committed `.claude/` harness** — then helps maintain and improve it over time.

It is opinionated about six pillars and codifies your choices into the project's `.claude/` directory:

1. **Architecture** — layering / module boundaries, codified into `CLAUDE.md` + path-scoped `.claude/rules/`.
2. **Testing** — framework, coverage, TDD-vs-after, enforced at the chosen tier.
3. **Context & handoff** — the centerpiece: compact per-session handoff docs that auto-load at the next session so you resume cheaply and keep context light.
4. **Project / git** — branch & PR workflow, protected branches.
5. **Review & quality gates** — lint/typecheck/self-review, optional reviewer subagent.
6. **Specialized workflows** — a curated catalog (frontend/UX audit, visual-regression, a11y, …) wired in based on stack.

## Layered enforcement

Every convention can be rendered at one of three tiers, chosen per-rule during the interview:

| Tier | Mechanism | Example |
|------|-----------|---------|
| 1 — DOCS | `CLAUDE.md` + `.claude/rules/*.md` (path-scoped) | "Push only on green." |
| 2 — ADVISORY | non-blocking `PostToolUse`/`Stop` hooks that nudge | warn when src changed but no test changed |
| 3 — BLOCKING | `PreToolUse` hooks that `deny` | block `git push` when tests are red |

## Usage

Inside a target project:

- `/transcend-init` — interview + generate the harness (the spine).
- `/transcend-handoff` — write a session handoff before you stop.
- `/transcend-resume` — manually reload the latest handoff.
- `/transcend-audit` — critique an existing harness and propose improvements.
- `/transcend-catalog` — browse / add specialized workflow skills.

## Install modes

transcend-harness works two ways from the **same files** (no duplication):

- **As a plugin** — install via the bundled marketplace; skills/agents are discovered from `skills/` and `agents/`, and `${CLAUDE_PLUGIN_ROOT}` resolves to this repo so the CORE library under `core/` is readable.
- **As a plain repo** — clone/symlink so the skills are discovered (e.g. under `~/.claude` or a project `.claude/`); skills resolve `TRANSCEND_ROOT` by falling back to this repo's root when `$CLAUDE_PLUGIN_ROOT` is unset.

## Layout

```
.claude-plugin/   thin packaging (plugin.json, marketplace.json)
skills/           entry-point skills (transcend-init, transcend-handoff, transcend-audit, …)
agents/           subagents (stack-detector, generator, auditor)
core/             the stack-agnostic CORE library (pure data)
  principles/     framework opinions, imported into generated CLAUDE.md
  pillars/        per-pillar options + render fragments + pillar.yaml
  stacks/         stack profiles (node-ts-react, …, unknown fallback)
  detectors/      read-only stack detection shell snippets
  audit/          manifest drift verifier (read-only, JSON out)
  catalog/        curated specialized skills
  templates/      top-level scaffolds (CLAUDE.md, settings, handoffs)
  scripts/        hook implementations (POSIX sh)
docs/             authoring guides
tests/            behavior tests + golden/ expected output per stack
```

See `docs/ARCHITECTURE.md` for how the engine fits together.

## Status

All planned milestones (M0–M5) are built: the interview → generate → resume
spine, layered Tier-2/3 enforcement, audit with safe-apply merge, multi-stack
detection (node-ts-react, python-fastapi, go-service) with a curated catalog,
idempotent re-init, monorepo scoping, and structurally-validated golden
fixtures. See the roadmap in `docs/ARCHITECTURE.md` and the authoring guides
(`docs/AUTHORING-PILLARS.md`, `docs/AUTHORING-STACKS.md`).
