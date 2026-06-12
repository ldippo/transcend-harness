---
name: transcend-resume
description: Manually reload the latest session handoff into context mid-session (the same handoff the SessionStart hook auto-loads), plus the current work-state delta. Use to re-orient after a /compact, after wandering off-task, or when you want to re-read the carved Goal, Next steps, and Do-NOT list.
user-invocable: true
allowed-tools: Read, Bash
---

# transcend-resume

Reload the current handoff so you can re-orient on the carved task.

```!
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
HANDOFF="$PROJECT_DIR/.claude/handoffs/current.md"
if [ -f "$HANDOFF" ]; then
  cat "$HANDOFF"
  echo ""
  echo "--- work-state delta (uncommitted changes since the handoff was written) ---"
  ( cd "$PROJECT_DIR" && git status --short 2>/dev/null | head -20 ) || echo "not a git repo"
  echo "--- recent commits ---"
  ( cd "$PROJECT_DIR" && git log --oneline -5 2>/dev/null )
  echo "--- archived handoffs ---"
  ls -t "$PROJECT_DIR/.claude/handoffs/archive" 2>/dev/null | head -5 || echo "none"
else
  echo "NO_CURRENT_HANDOFF — run /transcend-handoff to create one, or /transcend-init if this project has no harness."
fi
```

Read the handoff above, then orient:

1. **Check staleness.** If frontmatter `status: done`, or the work-state delta
   shows changes the handoff's "Done" section doesn't mention, say so — the
   handoff trails reality and the developer should `/transcend-handoff` after
   this session catches up. Dated handoffs in `archive/` are history; only
   `current.md` is authoritative.
2. **Resume from the Next list**, read only the files under **Context
   pointers** (do not re-scan the whole repo), and respect **Do NOT**.
3. If there is no handoff, tell the developer how to create one.
