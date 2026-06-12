# a11y-audit — accessibility heuristics

**What:** Checks interactive UI for roles/labels, color contrast, focus order, and
keyboard navigability against common accessibility heuristics.

**When to use:** Any user-facing web UI; especially new interactive components.

**Wiring when selected:**
- Adds a line to `CLAUDE.md` → "Specialized workflows".
- Adds a checklist step to `.claude/rules/quality-gates.md`: run `a11y-audit` on
  new interactive components.
- Drops a thin pointer skill at `.claude/skills/a11y-audit/SKILL.md`.

**Invocation:** `/a11y-audit` against the current diff or a target component.
