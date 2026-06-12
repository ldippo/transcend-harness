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
an entry in the project's `settings.json` so the team gets them on trust.
