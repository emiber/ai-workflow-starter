---
name: init-project
description: Interactive scaffolding of a new project. Asks the project type, defines components, suggests technologies, and generates the base.
---

# /init-project

Follow the playbook in `.agents/skills/init-project/SKILL.md` — it's the single source for this command's steps, shared with Codex. $ARGUMENTS (optional) may carry an initial project description; treat it as the playbook's starting description.

Claude Code specifics:
- This is the design phase → use the planning model (Opus); see `workflow/model-strategy.md`. If you're not on `opusplan`, switch with `/model opus`.
- Where the playbook says "the <name> skill", that's the `/<name>` command here.
