# migration-safety — database migration review

**What:** Reviews new/changed schema migrations for hazards: destructive
operations (drops, truncates, type narrowing), missing or broken downgrade
paths, lock-heavy DDL on large tables, and drift between ORM models and the
migration chain (e.g. Alembic autogenerate diffs that were hand-pruned).

**When to use:** Every PR that adds or edits a migration, especially against a
shared/production database.

**Wiring when selected:**
- Adds a line to `CLAUDE.md` → "Specialized workflows".
- Adds a checklist step to `.claude/rules/quality-gates.md`: run
  `migration-safety` on migration PRs.
- Drops a thin pointer skill at `.claude/skills/migration-safety/SKILL.md`
  documenting invocation. (Replace the pointer with the real skill/plugin when
  available.)

**Invocation:** `/migration-safety` against the current diff or a specific
migration file.
