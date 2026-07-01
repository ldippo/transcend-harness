---
title: Philosophy
description: The framework's standing opinions — context frugality, handoff-first work, small carved tasks, deliberate enforcement.
---

<!-- adapted from core/principles/00-philosophy.md and 01-context-as-environment.md -->

These are the framework's standing opinions. The generator splices short summaries of the relevant ones into a project's `CLAUDE.md`; the full text lives in the CORE library.

## 1. Context frugality

Context is the scarcest resource. A session should read the *minimum* needed to do its carved task — the handoff's "Context pointers", the relevant `rules/` file, and the files it actually edits. Re-scanning the whole repo each session is the default failure mode transcend exists to prevent.

## 2. Handoff-first

Work is carried across sessions by a compact **handoff document**, not by a long conversation. Each session ends by updating the handoff; each session starts by auto-loading it. The handoff is the durable, low-token bridge across `/clear`, `/compact`, and brand-new sessions. See [Context & Handoff](../pillars/context-handoff/).

## 3. Carve small tasks

A session targets ONE module-scoped task with a clear definition of done. Smaller carves mean lighter context, cleaner handoffs, and fewer half-finished threads.

## 4. Layered enforcement, chosen deliberately

Conventions are documented (Tier 1), nudged (Tier 2), or hard-blocked (Tier 3). The right tier is a deliberate per-rule choice, not a global default. Block only what genuinely must not happen; nudge the rest; document everything. Friction is a cost — blocking hooks are scoped narrowly so they never fire on unrelated actions. See [Enforcement Tiers](../concepts/enforcement-tiers/).

## 5. The harness is owned by the project

The generated `.claude/` is committed and shared by the team. It is a living artifact: transcend can audit it, the team can hand-edit it, and transcend preserves those edits rather than clobbering them.

## 6. Adapt, don't impose

The same core principles render differently per stack. transcend proposes sensible defaults from a stack profile and the developer chooses — the output is bespoke, not boilerplate.

## 7. Frugal tools, not just frugal context

Context frugality extends to *how* an agent reaches the outside world. The same task costs wildly different amounts by tool: a CLI like `gh` is typically far cheaper in tokens and latency than the equivalent MCP server, and compact output (a table, filtered fields, plain text) costs a fraction of a verbose JSON dump. The standing preferences: reach for a **CLI over an equivalent MCP server** when it's cheaper, ask tools for **token-efficient output** rather than raw JSON, and keep MCP for capabilities a CLI can't provide — assert the tool exists before you depend on it, and don't pay for tokens you won't read.

## 8. Context-as-environment (recursive language models)

When a task is too big for one context window — a sweeping audit, a long backlog, a transcript longer than the window — the failure mode is to pour everything into the prompt and watch quality collapse. The recursive-language-model move is the opposite: treat context as a *programmable environment*, not a bucket. Large data lives on disk or in a child session; the orchestrator holds only references and declared outputs. Three commitments make it real:

- **Externalize the corpus.** Big context is filesystem / REPL / variable state; agents `grep`/`split`/`cat` against files rather than pasting tokens inline.
- **Bindings discipline.** A sub-agent's transcript never re-enters the parent — only declared outputs cross the boundary (a `schema:`-validated object, or a final message that *is* the binding). Paste a sub-agent's prose into the next prompt and the discipline is broken.
- **The model picks the decomposition.** A **scout** agent *emits* the work-list at runtime; the script never carries a hardcoded array of units (the decisive line between a real recursive workflow and a plain map-reduce).

Recursion is bounded — depth-1 is enough in practice — and every fan-out carries a five-part envelope (depth, calls, budget, timeout, verified preconditions). Because parallel sub-agents are cheap, **adversarial verification is the default**: each finding faces an independent skeptic and survives only if it holds. This principle is the spine of the [Delivery Pipeline](../pillars/delivery-pipeline/) and of any workflow a project authors; the `recursive-workflows` and `golden-session` catalog skills carry the operational detail.
