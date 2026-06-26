# Principle: context-as-environment (recursive language models)

When a task is too big for one context window — a sweeping audit, a 1000-row
backlog, a transcript longer than the window — the failure mode is to pour
everything into the prompt and watch quality collapse. The recursive-language-model
(RLM) move is the opposite: treat the model's context as a *programmable
environment*, not a bucket. Large data lives on disk or in a child session; the
orchestrator holds only references and declared outputs.

Three commitments make this real:

- **Externalize the corpus.** Big context is filesystem / REPL / variable state.
  Agents `grep`, `sed`, `split`, and `cat` against files instead of pasting content
  inline; the orchestrator sees metadata (length, type, head), not tokens. State
  stays symbolic — held in variables and files, never accumulated in one window.
- **Bindings discipline.** A sub-agent's full transcript must never re-enter the
  parent. Only *declared outputs* cross the boundary — in a Workflow script, a
  `schema:`-validated object; for a `Task` sub-agent, a final message that *is* the
  binding ("return JSON fields X, Y; do not narrate"). The moment you paste a
  sub-agent's prose into the next prompt unchanged, the discipline is broken and the
  context is polluted.
- **The model picks the decomposition.** The decisive line between a true RLM and a
  plain map-reduce is that a **scout** agent *emits* the work-list at runtime, rather
  than the script carrying a hardcoded array of units. The decomposition is data the
  model produces, not a literal baked into the code.

Recursion is bounded, deliberately. Depth-1 self-delegation is enough in practice;
deeper rarely pays. Every recursive or background fan-out carries a five-part safety
envelope — depth, total calls, token budget, wall-clock timeout, and verified
preconditions (assert the CLIs/MCP a child needs exist *before* dispatch; fail fast
in the orchestrator, not in a doomed child). And because parallel sub-agents are
cheap, **adversarial verification is the default, not a luxury**: each finding faces
an independent skeptic prompted to refute it, and survives only if it holds.

This principle is the spine of the delivery pipeline and of any Workflow the project
authors. The `recursive-workflows` and `golden-session` skills carry the operational
detail; the 5-point RLM rubric (executable environment, externalized prompt,
code-calls-model, model-picks-decomposition, symbolic state) is the checklist for
whether a workflow actually earns the name.
