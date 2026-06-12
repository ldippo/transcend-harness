---
title: Context & Handoff
description: The centerpiece pillar — compact handoff documents, auto-load on session start, and task carving keep context light across sessions.
sidebar:
  order: 3
---

<!-- adapted from core/principles/pillar-context-handoff.md -->

The centerpiece pillar. Three complementary mechanisms keep context light across sessions.

## Handoff documents

A compact (&lt;120 line) markdown doc per session, stored in `.claude/handoffs/`. It records, in order:

1. The carved **Goal**
2. What's **Done**
3. The ordered **Next** steps
4. **Open questions / blockers**
5. **Context pointers** — the few files worth reading
6. A **Do NOT** list — anti-scope-creep plus expensive operations to avoid

A stable `current.md` pointer always references the latest handoff so `CLAUDE.md` can import a fixed path.

## Auto-load on session start

A `SessionStart` hook (matcher `startup|resume`) reads `current.md`; if its `status` is not `done`, it injects the handoff as the session's initial context — so the new session resumes from the **Next** list and respects **Do NOT** without re-reading the codebase.

## Task carving

Each session is scoped to one module/feature task. The handoff's "Context pointers" list is the *only* required reading. This is the lever that keeps context light: agents start from the pointers, not a repo-wide scan.

## The loop

```
carve task → work → /transcend-handoff captures Next + pointers
          → next SessionStart re-injects → resume cheaply
```

An advisory `Stop` hook reminds you to write the handoff if files changed but `current.md` wasn't updated this session. The commands involved — `/transcend-handoff` and `/transcend-resume` — are documented in [Skills & Commands](../../reference/skills/).
