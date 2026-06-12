---
paths:
  - "**/*"
---
# Git workflow — GitHub flow

A branch per change, a pull request to `main`, merge on green review. Work never
lands on `main` directly; a blocking hook (plus a permissions deny rule) stops
direct pushes.

## Rules
- Protected branch: `main` — never push directly to it.
- Create a short-lived branch per change (e.g. `feat/<slug>`, `fix/<slug>`).
- Every change reaches `main` via a pull request that has passed review and the quality gates.
- Commit messages: imperative mood, concise subject line (e.g. `feat: add handoff loader`); body explains why when non-obvious.

## Before opening a PR
- Rebase/merge latest `main`.
- Ensure review & quality gates pass (see @.claude/rules/quality-gates.md).

transcend never runs git for you. It generates these rules; you run the commands.
