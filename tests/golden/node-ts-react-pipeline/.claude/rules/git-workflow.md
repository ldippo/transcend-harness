---
paths:
  - "**/*"
---
# Git workflow — GitHub flow

A branch per change, opened as a PR against `main`, merged once review and quality
gates pass.

## Rules
- Protected branch: `main` — never push directly to it.
- Branch per change: `feature/<short-name>` or `fix/<short-name>`.
- Open a PR to `main`; merge only on green review + gates.
- Commit messages: conventional commits (`feat:`, `fix:`, `chore:`, …).

## Before opening a PR
- Rebase/merge latest `main`.
- Ensure review & quality gates pass (see @.claude/rules/quality-gates.md).

transcend never runs git for you. It generates these rules; you run the commands.
