---
name: fable-resume
description: Manually reload the latest session handoff into context mid-session (the same handoff the SessionStart hook auto-loads). Use to re-orient after a /compact, after wandering off-task, or when you want to re-read the carved Goal, Next steps, and Do-NOT list.
user-invocable: true
allowed-tools: Read, Bash
---

# fable-resume

Reload the current handoff so you can re-orient on the carved task.

```!
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
HANDOFF="$PROJECT_DIR/.claude/handoffs/current.md"
if [ -f "$HANDOFF" ]; then cat "$HANDOFF"; else echo "NO_CURRENT_HANDOFF — run /fable-handoff to create one, or /fable-init if this project has no harness."; fi
```

Read the handoff above. Resume from the **Next** list, read only the files under
**Context pointers** (do not re-scan the whole repo), and respect **Do NOT**. If
there is no handoff, tell the developer how to create one.
