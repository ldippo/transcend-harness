---
title: Specialized Workflows
description: A curated catalog of stack-specific skills — UX audit, visual regression, a11y, contract tests — wired into the workflow at the right moment.
sidebar:
  order: 6
---

<!-- adapted from core/principles/pillar-specialized-workflows.md -->

Beyond the universal pillars, most stacks benefit from a few specialized skills wired into the workflow at the right moment. transcend maintains a curated **catalog** and recommends entries based on the detected stack.

## Examples

- **impeccable** — frontend design critique & UX auditing for component-based UIs.
- **visual-regression** — screenshot capture + perceptual diff to catch unintended UI changes.
- **a11y-audit** — accessibility heuristics for web UIs.
- **api-contract-audit** — contract review for services exposing HTTP/gRPC APIs.
- **migration-safety** — database migration review for destructive operations and drift.

The full list, including per-entry wiring details, lives in the [Workflow Catalog reference](../../reference/catalog/).

## How entries are wired

Chosen entries are attached to the harness in up to four ways:

1. A line in `CLAUDE.md`'s "Specialized workflows" section.
2. An optional checklist step in the relevant pillar rule (e.g. "run `impeccable` on UI changes" in quality-gates).
3. A thin pointer skill at `.claude/skills/<id>/SKILL.md` documenting invocation.
4. For external plugins — an entry in the project's `settings.json` so the team gets them.

Add entries after init at any time with `/transcend-catalog` — see [Skills & Commands](../../reference/skills/).

## Provenance & trust

The catalog is deliberately **curated and first-party**. A skill or plugin can instruct the agent to run arbitrary commands, so a malicious or careless one can exfiltrate secrets or source, and even a benign one can *degrade* results by spending more tokens for worse outcomes. **Popularity is not evidence of quality** — a high star count measures reach, not rigor. Prefer the curated catalog; treat any third-party skill/plugin as untrusted until reviewed, and adopt it only after seeing what it actually does — never on stars alone. External entries carry a `provenance` note so the choice stays auditable.
