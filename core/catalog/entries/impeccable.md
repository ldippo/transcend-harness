# impeccable — frontend design & UX audit

**What:** Critiques UI work for visual hierarchy, spacing/rhythm, component state
coverage (loading/empty/error), responsive behavior, and accessibility heuristics.

**When to use:** Before merging any change that touches UI components.

**Wiring when selected:**
- Adds a line to `CLAUDE.md` → "Specialized workflows".
- Adds a checklist step to `.claude/rules/quality-gates.md`: run `impeccable` on
  UI changes.
- Drops a thin pointer skill at `.claude/skills/impeccable/SKILL.md` documenting
  invocation. (Replace the pointer with the real skill/plugin when available.)

**Invocation:** `/impeccable` against the current diff or a target component.
