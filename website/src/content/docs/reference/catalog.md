---
title: Workflow Catalog
description: The curated catalog of specialized workflow skills — what each does, when to use it, and which stacks it applies to.
---

<!-- adapted from core/catalog/catalog.yaml and core/catalog/entries/*.md -->

The catalog is a curated list of specialized workflow skills. During `/transcend-init` the interview recommends entries matching the detected stack; `/transcend-catalog` browses and wires them at any time after.

Every selected entry is wired the same way: a line in `CLAUDE.md`'s "Specialized workflows" section, a checklist step in the relevant pillar rule (usually quality-gates), and a thin pointer skill at `.claude/skills/<id>/SKILL.md` documenting invocation. See the [Specialized Workflows pillar](../../pillars/specialized-workflows/) for the wiring model.

## impeccable — frontend design & UX audit

**Stacks:** `node-ts-react`

Critiques UI work for visual hierarchy, spacing/rhythm, component state coverage (loading/empty/error), responsive behavior, and accessibility heuristics. Run before merging any change that touches UI components.

**Invocation:** `/impeccable` against the current diff or a target component.

## visual-regression — screenshot diffing

**Stacks:** `node-ts-react`

Captures screenshots of key views/components and compares them against baselines to catch unintended visual changes. For projects with visual UI that should not change unintentionally.

**Invocation:** `/visual-regression` to capture/compare; attach diffs to the PR.

## a11y-audit — accessibility heuristics

**Stacks:** `node-ts-react`

Checks interactive UI for roles/labels, color contrast, focus order, and keyboard navigability against common accessibility heuristics. For any user-facing web UI, especially new interactive components.

**Invocation:** `/a11y-audit` against the current diff or a target component.

## api-contract-audit — API contract review

**Stacks:** `python-fastapi`, `go-service`

Compares the service's actual routes/handlers against its OpenAPI (or gRPC) contract: flags breaking changes (removed/renamed fields, narrowed types, changed status codes), undocumented endpoints, and request/response schema drift. For FastAPI it leans on the generated `openapi.json`; for Go, on the declared routes plus any committed spec.

**Invocation:** `/api-contract-audit` against the current diff, or a named router/handler package.

## migration-safety — database migration review

**Stacks:** `python-fastapi`

Reviews new or changed schema migrations for hazards: destructive operations (drops, truncates, type narrowing), missing or broken downgrade paths, lock-heavy DDL on large tables, and drift between ORM models and the migration chain. For every PR that adds or edits a migration, especially against a shared/production database.

**Invocation:** `/migration-safety` against the current diff or a specific migration file.

## recursive-workflows — dynamic Workflow authoring & multi-agent orchestration

**Stacks:** all (`node-ts-react`, `python-fastapi`, `go-service`, `unknown`)

The conventions for writing `Workflow` scripts and orchestrating sub-agents, distilled from the Recursive Language Models work and dynamic workflows: context-as-environment, the bindings discipline (a sub-agent's transcript never re-enters the parent — only declared `schema:` outputs cross), the bounded-recursion guardrail envelope (depth/calls/budget/timeout), the six dynamic-workflow patterns, and the 5-point RLM rubric — whose decisive test is #4: a scout *emits* the work-list at runtime rather than the script carrying a hardcoded array. Wires into the delivery-pipeline rule.

**Invocation:** `/recursive-workflows` while designing or reviewing a Workflow script or a multi-agent fan-out.

## golden-session — capture a successful run as a reusable workflow

**Stacks:** all (`node-ts-react`, `python-fastapi`, `go-service`, `unknown`)

Deconstructs a successful ("golden") session into a parameterized, runnable Workflow script: reads the transcript with code (never pasting it), extracts the durable task spine, abstracts specifics into `args`, maps onto the dynamic-workflow patterns, and emits a committed `.claude/workflows/<name>.js`. Pairs with `recursive-workflows`, which defines the rules it follows.

**Invocation:** `/golden-session` against the current/just-finished session.

## Adding your own entries

Catalog entries live in `core/catalog/catalog.yaml` with a human-readable doc per entry under `core/catalog/entries/`. Each entry declares its `stacks`, optional detector-signal `triggers`, and `wiring`. Stack profiles reference entry ids via `catalog_recommend` — see [Authoring Stacks](../../guides/authoring-stacks/).
