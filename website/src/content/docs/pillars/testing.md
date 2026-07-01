---
title: Testing
description: Make the testing strategy explicit — TDD, test-after, characterization, or spike-then-stabilize — and enforce it at the chosen tier.
sidebar:
  order: 2
---

<!-- adapted from core/principles/pillar-testing.md -->

Tests are the contract that lets agents change code confidently. transcend makes the strategy explicit and enforceable at the chosen tier.

## Strategies offered

- **TDD (strict)** — a failing test precedes implementation. Highest discipline; best for well-understood, high-stakes code.
- **Test-after** — implement, then cover behavior before the change ships. The pragmatic default for most app code.
- **Characterization** — for legacy/untested code: snapshot current behavior before refactoring, so you can refactor safely.
- **Spike-then-stabilize** — explore without tests, then stabilize with tests once the design settles. For genuinely exploratory work.

## Test level & the bug workflow

The strategies above answer *when* a test is written. Two orthogonal conventions answer *what* it exercises:

- **Repro-first bug fixing** — a bug fix starts by reproducing the defect end-to-end, as close to the real user's path as possible, *before* touching the fix. The failing reproduction is the definition of done. (Always-on in the rendered rule.)
- **Behavior over unit** — a **test-level preference** (behavioral-first / balanced / unit-first) sets whether the contract lives in end-to-end/integration paths or in unit tests. The preference tunes the default; it never bans unit tests for pure logic and edge cases.

## Enforcement

Whatever the strategy, transcend records the project's `test_cmd` so advisory and blocking gates ("push only on green") can run it:

| Tier | Rendering |
|------|-----------|
| 1 | `rules/testing.md`: "push only on green" |
| 2 | `untested-edit.sh` warns when source changed but no test changed |
| 3 | `push-gate.sh` blocks `git push` while tests are red |

See [Enforcement Tiers](../../concepts/enforcement-tiers/).
