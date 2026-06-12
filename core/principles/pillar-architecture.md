# Principle: architecture conventions

A project should have an explicit, written shape: where code lives, what may
depend on what, and how things are named. fable codifies this as a short
architecture section in `CLAUDE.md` plus a path-scoped `rules/architecture.md`.

Key ideas fable encodes:

- **Module boundaries** — declare which directories are modules and which
  cross-module imports are forbidden (e.g. `auth` must not import `billing`).
  Boundaries can be documented (Tier 1) or enforced (Tier 3).
- **Dependency direction** — higher layers depend on lower, never the reverse.
- **Naming & placement** — where new files of a given kind belong, so agents
  don't invent ad-hoc structure.

The architecture rule's `paths:` frontmatter scopes it to source globs from the
stack profile, so it loads only when relevant files are touched.
