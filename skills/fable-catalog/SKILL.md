---
name: fable-catalog
description: Browse fable-harness's curated catalog of specialized workflow skills (frontend/UX audit, visual-regression, a11y, etc.) and wire chosen ones into this project's harness. Use to add a specialized workflow to an existing fable harness after init.
user-invocable: true
allowed-tools: Read, Bash, AskUserQuestion, Write, Edit
---

# fable-catalog

Browse the curated catalog and wire selected entries into the project's harness.

```!
FABLE_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$CLAUDE_SKILL_DIR")/.." && pwd)}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
echo "--- catalog ---"; cat "$FABLE_ROOT/core/catalog/catalog.yaml"
echo "--- this project's stack/manifest ---"; cat "$PROJECT_DIR/.claude/.fable/manifest.json" 2>/dev/null || sh "$FABLE_ROOT/core/detectors/detect.sh" "$PROJECT_DIR"
echo "--- already-wired skills ---"; ls "$PROJECT_DIR/.claude/skills" 2>/dev/null || echo "none"
```

## Steps

1. From the catalog above, filter entries relevant to this project's stack and not
   already wired. Present them with `AskUserQuestion` (multiSelect): "Add <id> —
   <what>?".
2. For each chosen entry, apply its `wiring` (idempotently — skip anything already
   present):
   - splice `wiring.claudemd` into the CLAUDE.md "Specialized workflows" section;
   - append `wiring.pillar_step.text` to the named pillar's rule file;
   - if `pointer_skill: true`, write `.claude/skills/<id>/SKILL.md` from the
     entry doc (`core/catalog/entries/<id>.md`) describing invocation;
   - if `kind: external-plugin`, add its `settings_plugin` ref to the project's
     `settings.json`.
3. Update `.claude/.fable/manifest.json` `catalog` list. Report what was wired. Do
   not commit unless asked.
