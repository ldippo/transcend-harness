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

## Evidence over assertion

"Tests pass" is a claim; **evidence** is proof. When a change ships, the strongest
gate is an artifact that demonstrates the change does what its *original intent*
asked — a screenshot or short capture for UI, a command transcript or log for
behavior, the actual output for a data change — attached to the PR alongside the
result text. Evidence turns review from "trust the author's summary" into "see it
work," and it is what lets a reviewer (human or agent) approve without re-deriving
the whole change. transcend offers an **evidence-on-PR** convention (advisory: a
reminder when a PR opens without one).

## Review depth scales with risk

Reviewing every diff at full depth is the bottleneck that caps how much an agent
crew can ship. The escape is to **tier review by risk**: a low-risk change (docs, a
localized refactor with green tests, a config tweak) gets a light pass, while a
high-risk change (auth, data migrations, money, shared APIs, anything hard to
reverse) gets a deep diff read plus an independent adversarial reviewer prompted to
*refute* it. This is the same deliberate-tiering instinct as enforcement (Tier
1/2/3) applied to attention: spend the scarce human/skeptic review where a missed
bug actually costs, and let the cheap changes flow. A reviewer that hits a genuinely
**ambiguous product decision** (not a bug — a "which behavior did you want?") escalates
it to the developer rather than guessing.
