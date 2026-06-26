# recursive-workflows — dynamic Workflow authoring & multi-agent orchestration

**What:** The conventions for writing good `Workflow` scripts and orchestrating
sub-agents, distilled from the Recursive Language Models (RLM) work and Anthropic's
dynamic-workflows feature. Covers the one principle (context-as-environment), the
bindings discipline (a sub-agent's transcript never re-enters the parent — only
declared `schema:` outputs cross the boundary), the bounded-recursion guardrail
envelope (depth / calls / budget / timeout), tools-as-verified-preconditions, the
6 dynamic-workflow patterns, and the 5-point RLM rubric — whose decisive test is #4:
a scout agent *emits* the work-list at runtime rather than the script carrying a
hardcoded array.

**When to use:** Before authoring any Workflow script, fanning out parallel
sub-agents, or designing a recursive / background / multi-agent decomposition.

**Wiring when selected:**
- Adds a line to `CLAUDE.md` → "Specialized workflows".
- Adds a checklist step to `.claude/rules/delivery-pipeline.md`: when a step fans out
  subagents, use declared outputs only, let the scout emit the work-list, and apply
  the depth/calls/budget/timeout guardrails.
- Drops a thin pointer skill at `.claude/skills/recursive-workflows/SKILL.md`
  documenting invocation. (Replace the pointer with the real skill/plugin when
  available.)

**Invocation:** `/recursive-workflows` while designing or reviewing a Workflow
script or a multi-agent fan-out.
