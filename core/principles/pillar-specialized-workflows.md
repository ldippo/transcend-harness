# Principle: specialized workflows

Beyond the universal pillars, most stacks benefit from a few specialized skills
wired into the workflow at the right moment. transcend maintains a curated **catalog**
(`core/catalog/`) and recommends entries based on the detected stack.

Examples:

- **impeccable** — frontend design critique & UX auditing for component-based UIs.
- **visual-regression** — screenshot capture + perceptual diff to catch unintended
  UI changes.
- **a11y-audit** — accessibility heuristics for web UIs.
- **api-contract-tests** — contract/consumer tests for services.

Chosen entries are wired into the harness: a line in CLAUDE.md's "Specialized
workflows" section, an optional checklist step in the relevant pillar rule (e.g.
"run `impeccable` on UI changes" in quality-gates), and — for external plugins —
an entry in the project's `settings.json` so the team gets them.

## Provenance & trust

The catalog is deliberately **curated and first-party**. A skill or plugin is not
inert markdown: it can instruct the agent to run arbitrary commands, which means a
malicious or careless one can exfiltrate secrets, credentials, or source to a third
party. And even a benign one can *degrade* results — an unevaluated skill often
spends more tokens for worse outcomes. **Popularity is not evidence of quality**: a
high star count measures reach, not whether the skill was ever rigorously measured.

So the standing stance: prefer the curated catalog; treat any third-party
skill/plugin as untrusted until reviewed. Adopt an external entry only after reading
what it actually does and, ideally, seeing a real evaluation of it — never on stars
alone. When the interview wires an `external-plugin` entry, its `provenance` note
records where it came from and what review it had, so the choice is auditable later.
