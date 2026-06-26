# golden-session — capture a successful run as a reusable workflow

**What:** Deconstructs a successful ("golden") Claude Code session into a
parameterized, runnable dynamic Workflow script. Reads the session transcript with
code (never pasting it into context), extracts the durable task spine (goal, the
action sequence that actually worked, decision points, verification), abstracts the
run-specific specifics into `args`, maps the spine onto the dynamic-workflow patterns
(scout-emits-worklist, adversarial-verify, classify-and-act, loop-until-done), and
emits a committed `.claude/workflows/<name>.js`. Pairs with `recursive-workflows`,
which defines the rules it follows.

**When to use:** After a run that worked well and should be repeatable —
"capture this session", "make this repeatable", "turn this run into a workflow".

**Wiring when selected:**
- Adds a line to `CLAUDE.md` → "Specialized workflows".
- Adds a checklist step to `.claude/rules/delivery-pipeline.md`: after a notably good
  run, consider capturing it as a reusable workflow.
- Drops a thin pointer skill at `.claude/skills/golden-session/SKILL.md` documenting
  invocation. (Replace the pointer with the real skill/plugin when available.)

**Invocation:** `/golden-session` against the current/just-finished session (or a
named `~/.claude/projects/<encoded-cwd>/<session>.jsonl`).
