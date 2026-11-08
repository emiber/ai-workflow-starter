---
description: Refines and clarifies an issue (GitHub or Jira) by asking all the necessary questions until it's implementable.
---

# /refine-issue

First read `.agents/skills/refine-issue/SKILL.md`, then follow it step by step — it's the single source for this command's steps, shared with Codex. The target issue is $ARGUMENTS (a number on GitHub, a key on Jira).

Claude Code specifics:
- This is the analysis phase → use the planning model (Opus); see `workflow/model-strategy.md`. If you aren't running on Opus, tell the user once to run `/model opus` and to switch back with `/model opusplan` before `/work-issue` (`/model` also saves the choice as the default for new sessions), then continue without waiting. Don't suggest plan mode instead.
- Where the playbook says "the <name> skill", that's the `/<name>` command here.
