---
name: finish-epic
description: Opens the integration PR (epic branch → main) when an epic's children are done. Reads workflow/epics.md.
---

# /finish-epic

Follow the playbook in `.agents/skills/finish-epic/SKILL.md` — it's the single source for this command's steps, shared with Codex. The target epic is $ARGUMENTS (a number on GitHub, a key on Jira).

Claude Code specifics:
- This wraps up implementation → the execution model (Sonnet) is fine; see `workflow/model-strategy.md`.
- Where the playbook says "the <name> skill", that's the `/<name>` command here.
