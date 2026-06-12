---
title: Project & Git
description: Branch and PR workflow models — trunk-based, GitHub flow, or stacked PRs — with the trunk protected at the tier you choose.
sidebar:
  order: 4
---

<!-- adapted from core/principles/pillar-project-git.md -->

How work flows from idea to merged code. transcend codifies the branch/PR model and protects what must not be touched directly.

## Models offered

- **Trunk-based** — short-lived branches (or direct-to-trunk with gates), frequent integration. Best with strong CI.
- **GitHub flow** — a branch per change, PR to `main`, merge on green review. The common default.
- **Stacked PRs** — dependent PRs for large efforts split into reviewable slices.

## Protecting the trunk

Across all models, `main` (or the trunk) is protected: direct pushes are documented as forbidden (Tier 1), reminded (Tier 2 — `on-protected-branch.sh` nudges at session stop), or blocked (Tier 3 — `protect-main.sh` denies the push). See [Enforcement Tiers](../../concepts/enforcement-tiers/).

transcend never commits or pushes on your behalf — it generates the rules, you run git.
