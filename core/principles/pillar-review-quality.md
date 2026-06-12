# Principle: review & quality gates

The checks that stand between "it compiles" and "it's mergeable."

Gates offered (combinable):

- **Lint + typecheck gate** — `lint_cmd` and `typecheck_cmd` must pass. Cheap,
  high-signal; advisory on edit and/or blocking on push.
- **Pre-PR self-review** — a checklist the agent runs against its own diff before
  opening a PR (scope, tests, naming, leftover debug code).
- **Agent review gate** — a `reviewer` subagent reviews the diff for correctness
  and convention adherence before merge.

transcend wires the chosen gates into `rules/quality-gates.md` and, when an agent
reviewer is chosen, generates a project-local `reviewer` subagent. Specialized
catalog skills (e.g. UX audit) can attach themselves as extra review steps.
