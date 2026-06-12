# Principle: context & handoff management

The centerpiece pillar. Three complementary mechanisms keep context light across
sessions:

## Handoff documents

A compact (<120 line) markdown doc per session, stored in `.claude/handoffs/`. It
records, in order: the carved **Goal**, what's **Done**, the ordered **Next**
steps, **Open questions / blockers**, **Context pointers** (the few files worth
reading), and a **Do NOT** list (anti-scope-creep + expensive operations to
avoid). A stable `current.md` pointer always references the latest handoff so
`CLAUDE.md` can import a fixed path.

## Auto-load on session start

A `SessionStart` hook (matcher `startup|resume`) reads `current.md`; if its
`status` is not `done`, it injects the handoff as the session's initial context so
the new session resumes from the **Next** list and respects **Do NOT** — without
re-reading the codebase.

## Task carving

Each session is scoped to one module/feature task. The handoff's "Context
pointers" list is the *only* required reading. This is the lever that keeps
context light: agents start from the pointers, not a repo-wide scan.

## The loop

carve task → work → `transcend-handoff` captures Next + pointers → next `SessionStart`
re-injects → resume cheaply. An advisory `Stop` hook reminds you to write the
handoff if files changed but `current.md` wasn't updated this session.
