---
title: Review & Quality Gates
description: Lint and typecheck gates, pre-PR self-review checklists, and an optional reviewer subagent — the checks between "it compiles" and "it's mergeable".
sidebar:
  order: 5
---

<!-- adapted from core/principles/pillar-review-quality.md -->

The checks that stand between "it compiles" and "it's mergeable."

## Gates offered (combinable)

- **Lint + typecheck gate** — `lint_cmd` and `typecheck_cmd` must pass. Cheap, high-signal; advisory on edit and/or blocking on push.
- **Pre-PR self-review** — a checklist the agent runs against its own diff before opening a PR (scope, tests, naming, leftover debug code).
- **Agent review gate** — a `reviewer` subagent reviews the diff for correctness and convention adherence before merge.

## How it's wired

transcend wires the chosen gates into `rules/quality-gates.md` and, when an agent reviewer is chosen, generates a project-local `reviewer` subagent. At Tier 2, `lint-on-edit.sh` checks the touched file as you go; at Tier 3, `push-gate.sh` blocks pushes until lint and typecheck pass — see [Enforcement Tiers](../../concepts/enforcement-tiers/).

[Specialized catalog skills](../specialized-workflows/) (e.g. UX audit) can attach themselves as extra review steps.
