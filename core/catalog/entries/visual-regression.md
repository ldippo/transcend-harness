# visual-regression — screenshot diffing

**What:** Captures screenshots of key views/components and compares them against
baselines to catch unintended visual changes.

**When to use:** Projects with visual UI that should not change unintentionally.

**Wiring when selected:**
- Adds a line to `CLAUDE.md` → "Specialized workflows".
- Adds a checklist step to `.claude/rules/quality-gates.md`: run
  `visual-regression` and review diffs before merging UI changes.
- Drops a thin pointer skill at `.claude/skills/visual-regression/SKILL.md`.

**Invocation:** `/visual-regression` to capture/compare; attach diffs to the PR.
