---
name: visual-regression
description: Capture screenshots of key views/components and compare against baselines to catch unintended visual changes. Use for UI changes that should not alter appearance unintentionally; attach diffs to the PR.
user-invocable: true
---

# visual-regression (pointer)

Wired into this project's harness by fable-harness. Run `/visual-regression` to
capture and compare screenshots; attach diffs to the PR for UI changes.

> This is a thin pointer. Replace it with the real `visual-regression`
> skill/plugin when available; the harness references it from
> `.claude/rules/quality-gates.md`.
