---
description: Interactive scaffolding of a new project. Asks the project type, defines components, suggests technologies, and generates the base.
---

# /init-project

First read `.agents/skills/init-project/SKILL.md`, then follow it step by step — it's the single source for this command's steps, shared with Codex. $ARGUMENTS (optional) may carry an initial project description; treat it as the playbook's starting description.

Claude Code specifics:
- This is the design phase → use the planning model (Opus); see `workflow/model-strategy.md`. If you aren't running on Opus, tell the user once to run `/model opus` and to switch back with `/model opusplan` before `/work-issue` (`/model` also saves the choice as the default for new sessions), then continue without waiting. Don't suggest plan mode instead.
- Where the playbook says "the <name> skill", that's the `/<name>` command here.
