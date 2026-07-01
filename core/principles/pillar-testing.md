# Principle: testing strategy

Tests are the contract that lets agents change code confidently. transcend makes the
strategy explicit and enforceable at the chosen tier.

Strategies offered:

- **TDD (strict)** — a failing test precedes implementation. Highest discipline;
  best for well-understood, high-stakes code.
- **Test-after** — implement, then cover behavior before the change ships. The
  pragmatic default for most app code.
- **Characterization** — for legacy/untested code: snapshot current behavior
  before refactoring, so you can refactor safely.
- **Spike-then-stabilize** — explore without tests, then stabilize with tests once
  the design settles. For genuinely exploratory work.

Whatever the strategy, transcend records the project's `test_cmd` so advisory and
blocking gates ("push only on green") can run it.

## A second axis: test *level* and the bug workflow

The strategies above answer *when* a test is written. Two orthogonal conventions
answer *what* a test should exercise — offered separately in the interview:

- **Repro-first bug fixing.** A bug fix starts by reproducing the defect
  end-to-end, as close to the real user's path as possible, *before* touching the
  fix. The failing repro is the definition-of-done anchor: the fix is finished when
  that same reproduction passes. Reaching for a narrow unit test first tends to
  encode the bug's symptom, not the user-visible behavior that broke.
- **Behavior over unit.** Prefer tests that exercise real product behavior — the
  end-to-end or integration path a user actually takes — over unit tests that pass
  while the feature is broken at the seams. Unit tests still earn their place for
  pure logic and edge-case fan-out; the preference is about where the *contract*
  lives, not about banning unit tests. transcend offers a **test-level preference**
  (behavioral-first / balanced / unit-first) so the default matches the project.
