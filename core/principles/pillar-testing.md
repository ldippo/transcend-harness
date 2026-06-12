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
