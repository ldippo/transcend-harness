# transcend-harness philosophy

These are the framework's standing opinions. The generator splices short
summaries of the relevant ones into a project's `CLAUDE.md`; the full text lives
here.

## 1. Context frugality

Context is the scarcest resource. A session should read the *minimum* needed to do
its carved task — the handoff's "Context pointers", the relevant `rules/` file,
and the files it actually edits. Re-scanning the whole repo each session is the
default failure mode transcend exists to prevent.

## 2. Handoff-first

Work is carried across sessions by a compact **handoff document**, not by a long
conversation. Each session ends by updating the handoff; each session starts by
auto-loading it. The handoff is the durable, low-token bridge across `/clear`,
`/compact`, and brand-new sessions.

## 3. Carve small tasks

A session targets ONE module-scoped task with a clear definition of done. Smaller
carves mean lighter context, cleaner handoffs, and fewer half-finished threads.

## 4. Layered enforcement, chosen deliberately

Conventions are documented (Tier 1), nudged (Tier 2), or hard-blocked (Tier 3).
The right tier is a deliberate per-rule choice, not a global default. Block only
what genuinely must not happen; nudge the rest; document everything. Friction is a
cost — blocking hooks are scoped narrowly so they never fire on unrelated actions.

## 5. The harness is owned by the project

The generated `.claude/` is committed and shared by the team. It is a living
artifact: transcend can audit it, the team can hand-edit it, and transcend preserves those
edits rather than clobbering them.

## 6. Adapt, don't impose

The same core principles render differently per stack. transcend proposes sensible
defaults from a stack profile and the developer chooses — the output is bespoke,
not boilerplate.

## 7. Frugal tools, not just frugal context

Context frugality extends to *how* an agent reaches the outside world. The same
task costs wildly different amounts depending on the tool: a CLI like `gh` is
typically far cheaper in tokens and latency than the equivalent MCP server, and a
compact output format (a table, `--jq`-filtered fields, plain text) can cost a
fraction of a verbose JSON dump. The standing preferences: reach for a **CLI over
an equivalent MCP server** when it's cheaper, ask tools for **token-efficient
output** rather than raw JSON, and keep MCP for capabilities a CLI genuinely can't
provide. This is the tool-side of the same envelope the RLM principle already asks
for — assert the tool exists before you depend on it, and don't pay for tokens you
won't read.
