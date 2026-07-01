# Principle: architecture conventions

A project should have an explicit, written shape: where code lives, what may
depend on what, and how things are named. transcend codifies this as a short
architecture section in `CLAUDE.md` plus a path-scoped `rules/architecture.md`.

Key ideas transcend encodes:

- **Module boundaries** — declare which directories are modules and which
  cross-module imports are forbidden (e.g. `auth` must not import `billing`).
  Boundaries can be documented (Tier 1) or enforced (Tier 3).
- **Dependency direction** — higher layers depend on lower, never the reverse.
- **Naming & placement** — where new files of a given kind belong, so agents
  don't invent ad-hoc structure.

The architecture rule's `paths:` frontmatter scopes it to source globs from the
stack profile, so it loads only when relevant files are touched.

## Weigh the option, not the effort

When an agent weighs technical options it inherits a human bias from its training
data: it over-weights *implementation cost* and steers toward the "cheap" option —
which is often the low-quality, unscalable, or hard-to-maintain one. But an agent
can build the better option in minutes; the effort delta that matters to a human
rarely matters here. So the standing instruction is to **choose on correctness,
scalability, and maintainability first, and discount build effort** — pick the
design you'd want to live with, not the one that's fastest to type.
