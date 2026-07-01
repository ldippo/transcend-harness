---
title: Architecture
description: Module boundaries, dependency direction, and naming — codified into CLAUDE.md and a path-scoped rules file.
sidebar:
  order: 1
---

<!-- adapted from core/principles/pillar-architecture.md -->

A project should have an explicit, written shape: where code lives, what may depend on what, and how things are named. transcend codifies this as a short architecture section in `CLAUDE.md` plus a path-scoped `rules/architecture.md`.

## What transcend encodes

- **Module boundaries** — declare which directories are modules and which cross-module imports are forbidden (e.g. `auth` must not import `billing`). Boundaries can be documented (Tier 1) or enforced (Tier 3).
- **Dependency direction** — higher layers depend on lower, never the reverse.
- **Naming & placement** — where new files of a given kind belong, so agents don't invent ad-hoc structure.

## Choosing between options

When weighing technical options, an agent inherits a human bias from its training data: it over-weights *implementation cost* and steers toward the "cheap" option — often the low-quality, unscalable, or hard-to-maintain one. But an agent can build the better option in minutes. transcend's standing instruction: **choose on correctness, scalability, and maintainability first, and discount build effort.**

## Scoping

The architecture rule's `paths:` frontmatter scopes it to source globs from the stack profile, so it loads only when relevant files are touched — part of the [context frugality](../../philosophy/) principle.

## Enforcement

At Tier 3, `module-boundary.sh` denies cross-feature imports as a `PreToolUse` hook; at Tier 2 the same script warns instead. See [Enforcement Tiers](../../concepts/enforcement-tiers/) for the full mapping.
