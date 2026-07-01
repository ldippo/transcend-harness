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

## Verify by evidence, not assertion

The loop's verify step does more than report "tests pass": for a change with
user-visible behavior it captures an **evidence artifact** — a screenshot, a
command transcript, a log — that shows the issue's acceptance criteria actually met,
and attaches it to the change. This is the review-quality *evidence-over-assertion*
convention applied inside the pipeline, and it is what lets the developer approve a
finished issue by looking at proof rather than re-running it. Ambiguous *product*
calls surfaced during review are escalated as `proposed` followups or a note, not
guessed by the coder.

## Parallelism needs filesystem isolation (opt-in)

The default loop is **single-flight** — one issue, one lock — precisely so two
agents never clobber the same working tree. When a developer deliberately wants to
run more than one line of work at once, the safe way is **filesystem isolation**: a
git worktree per concurrent agent, so their edits can't collide. (A Workflow script
gets this via `isolation: 'worktree'`; outside one, `git worktree add` a scratch
dir.) transcend keeps single-flight as the default and offers parallel worktrees as
an explicit opt-in — never two unisolated loops on one tree.

## Capped autonomous loops

When the pipeline runs unattended (via `/loop`), it must carry an explicit **stop
envelope**, the loop-shaped sibling of the recursion guardrails: a token cap, an
iteration cap, and a concrete stop condition — so an overnight run can't silently
burn the whole quota. Two objective shapes deserve different trust:
**verifiable objectives** (a measurable target — cut load time, raise coverage,
drive a metric) can loop on their own signal, while **trusted-judgment objectives**
(open-ended improvement where the agent applies reasonable taste) should loop with a
tighter cap and a review at the end. The stop condition is not optional decoration —
it is what makes "let it run while I sleep" safe rather than reckless.
