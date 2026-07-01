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

## Evidence over assertion

"Tests pass" is a claim; **evidence** is proof. A change with user-visible behavior ships with an artifact — a screenshot/capture for UI, a command transcript or log for behavior, the actual output for data — that shows it works against its original intent, attached to the PR. Evidence turns review from "trust the summary" into "see it work" (advisory: a reminder when a PR opens without one).

## Review depth scales with risk

Reviewing every diff at full depth is the bottleneck that caps how much an agent crew can ship. transcend tiers review by risk: low-risk changes (docs, localized refactors with green tests, config) get a light pass; high-risk changes (auth, data migrations, money, shared APIs, anything hard to reverse) get a deep read plus an independent adversarial reviewer prompted to *refute* the diff. A reviewer that hits a genuinely ambiguous **product** decision escalates it to the developer instead of guessing.
