---
title: Agents
description: The three subagents — stack-detector, generator, and auditor — that keep heavy work out of the main context.
---

<!-- adapted from agents/*.md frontmatter -->

The skills delegate heavy or noisy work to three subagents so the main session's context stays light — the same [context frugality](../../philosophy/) principle the generated harnesses enforce.

| Agent | Model | Access | Role |
|-------|-------|--------|------|
| `transcend-stack-detector` | haiku | read-only (Read, Bash, Glob, Grep) | Detect the project's stack profile |
| `transcend-generator` | inherit | read-write (Read, Write, Edit, Bash) | Materialize the harness files |
| `transcend-auditor` | inherit | read-only (Read, Bash, Glob, Grep) | Inspect and critique an existing harness |

## transcend-stack-detector

Runs the read-only detector scripts (`core/detectors/detect.sh`), sanity-checks the result against the manifests actually present (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, lockfiles), loads the matched stack profile, and returns a compact stack-profile JSON with resolved command variables. Invoked by `/transcend-init`.

## transcend-generator

Materializes a harness into the target project's `.claude/` from a fully resolved set of choices and variable bindings — `CLAUDE.md`, path-scoped rules, `settings.json` hooks, copied hook scripts, the handoff scaffold, catalog wiring, and the manifest. It never re-runs the interview or changes choices.

Runs in one of two modes:

- **generate** — from `/transcend-init`: write the harness exactly as specified.
- **merge** — from `/transcend-audit` and re-init/upgrade: apply safe fixes (`create` / `regenerate` / `append` / `settings-merge`) while re-hashing each target at write time, so hand-edited and untracked files are never overwritten.

## transcend-auditor

Read-only inspector for `/transcend-audit`. Runs the manifest drift verifier, then critiques across the audit dimensions: provenance/drift, missing pillars, over/under-enforcement, stale handoffs, size/import health, portability, and catalog drift. Returns findings JSON with machine-applicable fix plans the generator's merge mode can execute.

For how the three fit together, see [Architecture](../../internals/architecture/).
