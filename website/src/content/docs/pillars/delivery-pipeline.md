---
title: Delivery Pipeline
description: An opt-in multi-agent pipeline — PM, architect, coder, and research subagents driven by a local issue store and run through /loop until the roadmap is done.
sidebar:
  order: 7
---

<!-- adapted from core/principles/pillar-delivery-pipeline.md -->

The heaviest, most ambitious pillar — and strictly **opt-in** (`none` by default). It
turns a high-level goal into shipped, committed work without you hand-feeding every
task. Worth it when there's a backlog to grind; overkill for a one-off change.

## What it generates

Choosing **Full pipeline** writes four bespoke subagents into `.claude/agents/` and two
orchestration skills into `.claude/skills/`, each carved to your stack and rules.

| Component | Kind | Role |
|-----------|------|------|
| `pm` | agent | High-level goal → roadmap + ordered issues; files discovered followups |
| `architect` | agent | Per-issue system design + doc upkeep; hands a plan to the coder |
| `coder` | agent | Implements one issue against your rules; runs test/lint/typecheck |
| `research` | agent | Fills context gaps; training-data vs. live web-search judgment |
| `/pipeline-plan` | skill | Plan a goal via the `pm` agent, review the roadmap, approve |
| `/pipeline-loop` | skill | Execute one issue end-to-end; the `/loop` target |

The **research** agent has explicit judgment: it trusts training data for stable
language semantics and well-established patterns, but reaches for a live web search to
confirm version-specific APIs, post-cutoff facts, security advisories, current best
practice, or pricing.

## Orchestration discipline (context-as-environment)

The loop is a multi-agent recursion, so it follows the [context-as-environment
principle](../../philosophy/#8-context-as-environment-recursive-language-models) and the
`recursive-workflows` conventions:

- **Declared outputs only (bindings discipline).** Agents receive an issue *id*, read
  the issue file themselves, write their work into the issue body (Design /
  Implementation) and the workspace, and return a short conclusion — never a transcript
  dump. The orchestrator passes references, never pasted prose, so sub-agent context
  stays out of the loop's context.
- **The scout emits the work-list (RLM rubric #4).** The `pm` agent *emits* the ordered
  issues from the goal and the loop reads them from the committed issue store — the
  decomposition is produced, never a hardcoded array baked into the loop.
- **Adversarial verification by default.** Review is a separate skeptic (the `reviewer`
  agent or a fresh refuting pass against `.claude/rules/`), not the author grading
  itself.
- **Bounded recursion.** One issue per invocation is the depth cap; cap total
  delegations, pass explicit timeouts to shell steps, and assert a required CLI/MCP
  exists before dispatching the agent that needs it.

## The local issue store

The pipeline's only durable state is committed files — not conversation memory — so any
session, or any `/loop` restart, resumes from them plus the handoff:

- `.claude/roadmap.md` — a generated projection of the issues (never hand-edited).
- `.claude/issues/<NNNN>-<slug>.md` — one file per issue. Frontmatter: `id`, `title`,
  `status`, `milestone`, `kind`, `depends_on`, `discovered_by`.

A deterministic helper, `.claude/scripts/transcend/pipeline/issues.sh`, owns the
lifecycle — agents call it rather than hand-editing the `status` field:

```
issues.sh next                 # first ready issue whose deps are all done
issues.sh claim <id>           # ready -> in-progress, single-flight (one loop at a time)
issues.sh done <id>            # in-progress -> done
issues.sh block <id> "reason"  # -> blocked
issues.sh approve <id>         # proposed -> ready
issues.sh new <kind> <slug> --title "..." [--depends-on "NNNN,NNNN"] [--discovered-by NNNN]
issues.sh roadmap              # regenerate roadmap.md from the issue files
```

### Issue lifecycle

```
proposed --(you approve)--> ready --(loop claims; deps done)--> in-progress
in-progress --(review passes + commit)--> done
in-progress --(blocker)--> blocked --(unblocked)--> ready
```

Every issue is born `proposed`. The `pm` agent (and any agent that discovers work) files
issues as `proposed`; only **you** approve them to `ready`.

## How you run it

```
/pipeline-plan "<high-level goal>"   # PM drafts a roadmap + issues for review
# review the roadmap, approve the issues
/loop pipeline-loop                   # grind one issue per iteration until done
```

Each `/pipeline-loop` iteration resumes any in-progress issue (or claims the next ready
one), runs the pipeline as fresh `Task` subagents — research as needed → architect →
coder → review — verifies with your test/lint commands, marks the issue `done`, rewrites
`current.md` so a brand-new session could pick up cold, then returns so `/loop` calls it
again. When no ready issues remain it prints `PIPELINE DONE` and stops — never spinning
on an empty backlog.

## Followups, approved at the end

When an agent spots a bug, gap, or enhancement **outside** the current issue's scope, it
doesn't chase it — it files a `proposed` followup via `issues.sh new --discovered-by`.
These accumulate while the roadmap runs; at the end you review and `approve` the ones
worth doing, turning a single goal into a self-extending backlog.

## Design commitments

- **One issue at a time.** `issues.sh claim` is single-flight (a lockfile); never run two
  loops against the same repo. An interrupted iteration is *resumed*, not duplicated. To
  run more than one line of work at once, isolate each on its own **git worktree** (or a
  Workflow with `isolation: 'worktree'`) — never two unisolated loops on one tree.
- **Verify by evidence.** For user-visible behavior, the verify step captures an
  artifact — screenshot, transcript, or log — proving the issue's acceptance criteria are
  met, recorded in the issue so you approve from proof rather than assertion.
- **Cap unattended loops.** A `/loop` run left going while you're away carries an explicit
  stop envelope — token cap, iteration cap, and stop condition — so it can't burn the whole
  quota. Verifiable objectives may loop on their own signal; open-ended judgment objectives
  get a tighter cap and a review at the end.
- **Depends on the handoff loop.** The per-issue `current.md` rewrite relies on
  [task-carving and handoff-on-stop](../context-handoff/) — selecting the pipeline keeps
  them on.
- **Orthogonal to enforcement appetite.** The pipeline adds no blocking hooks. Discipline
  lives in the agents' instructions and the issue state machine, not in gates — so it
  works the same at Docs, Advisory, or Strict appetite. See [Enforcement Tiers](../../concepts/enforcement-tiers/).
