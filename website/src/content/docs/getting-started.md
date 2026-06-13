---
title: Getting Started
description: Install transcend-harness and generate a bespoke .claude/ harness for your project.
---

<!-- adapted from README.md -->

transcend-harness is a meta-framework for [Claude Code](https://code.claude.com): run it inside any project and it **interviews you, detects the stack, and generates a bespoke, committed `.claude/` harness** — then helps maintain and improve it over time.

## Install

transcend-harness works two ways from the **same files** (no duplication):

### As a plugin

Install via the bundled marketplace. Skills and agents are discovered from `skills/` and `agents/`, and `${CLAUDE_PLUGIN_ROOT}` resolves to the repo so the CORE library under `core/` is readable.

```sh
# in Claude Code
/plugin marketplace add ldippo/transcend-harness
/plugin install transcend-harness
```

### As a plain repo

Clone or symlink so the skills are discovered (e.g. under `~/.claude` or a project `.claude/`). Skills resolve `TRANSCEND_ROOT` by falling back to the repo's root when `$CLAUDE_PLUGIN_ROOT` is unset.

```sh
git clone https://github.com/ldippo/transcend-harness.git
```

## Generate your harness

Inside the target project, run the spine:

```
/transcend-init
```

The interview walks through:

1. **Stack detection** — read-only probes score your manifests (`package.json`, `pyproject.toml`, `go.mod`, …) against stack profiles such as `node-ts-react`, `python-fastapi`, and `go-service`, with an `unknown` fallback.
2. **Scope & appetite** — confirm the detected stack, choose repo/subpath/workspace scope, and set your overall enforcement appetite (docs-only, advisory, or strict).
3. **Pillar options** — pick a convention per pillar: architecture style, testing strategy, handoff mechanisms, git workflow, quality gates.
4. **Per-rule tiers** — decide for each rule whether it's documented, nudged, or blocked (see [Enforcement Tiers](../concepts/enforcement-tiers/)).
5. **Catalog** — accept or skip [specialized workflows](../reference/catalog/) recommended for your stack.
6. **Plan preview → generate** — nothing is written before you confirm the plan.

The result is a committed `.claude/` directory: `CLAUDE.md`, path-scoped `rules/`, `settings.json` hooks, a handoff scaffold, and a manifest that makes re-init and audit safe (hand-edited files are never overwritten — see [Architecture](../internals/architecture/)).

## Day-to-day commands

| Command | What it does |
|---------|--------------|
| `/transcend-init` | Interview + generate the harness (the spine). |
| `/transcend-handoff` | Write a session handoff before you stop. |
| `/transcend-resume` | Manually reload the latest handoff. |
| `/transcend-audit` | Critique an existing harness and propose improvements. |
| `/transcend-catalog` | Browse / add specialized workflow skills. |

Full details on each: [Skills & Commands](../reference/skills/).

## Where to go next

- [Philosophy](../philosophy/) — the framework's standing opinions.
- [The Seven Pillars](../pillars/architecture/) — what each pillar covers and the options offered.
- [Enforcement Tiers](../concepts/enforcement-tiers/) — docs vs. advisory vs. blocking.
- [Authoring guides](../guides/authoring-pillars/) — extend the framework with your own pillars and stacks.
