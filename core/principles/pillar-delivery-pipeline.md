# Principle: multi-agent delivery pipeline

The pipeline turns a high-level goal into shipped work without the developer
hand-feeding every task. It is opt-in and heavy — only worth it when there is a
backlog to grind, not for a one-off change.

Four bespoke subagents, each carved to the project's stack and rules:

- **pm** — takes a high-level goal, produces a roadmap and an ordered set of
  issues, and during execution files followup work (bugs, gaps, enhancements) it
  discovers as `proposed` issues for the developer to approve at the end.
- **architect** — does the system design for one issue, keeps the project docs
  current, and hands a concrete plan to the coder.
- **coder** — implements one issue against the architecture/testing/quality rules.
- **research** — fills context gaps with judgment: trusts training data for stable
  language semantics and well-established patterns, but reaches for a live web
  search to confirm version-specific APIs, post-cutoff facts, security advisories,
  current best practice, or pricing.

Two design commitments keep it honest:

- **The issue store is the only durable state.** Roadmap and issues are committed
  files (`.claude/roadmap.md`, `.claude/issues/`), not conversation memory. Any
  session — or any `/loop` restart — resumes from them plus the handoff.
- **One issue at a time, fresh context per step.** The loop claims a single issue
  (single-flight), runs the steps as fresh subagents, then rewrites the handoff so
  the next iteration starts clean. This is the handoff loop scaled to a backlog —
  it depends on `task-carving` and `handoff-on-stop`.

The pipeline adds no enforcement hooks; it is orthogonal to the project's
enforcement appetite. Discipline lives in the agents' instructions and the issue
state machine, not in blocking gates.
