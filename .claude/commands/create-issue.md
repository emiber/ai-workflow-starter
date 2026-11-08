---
description: Creates a new issue (GitHub or Jira) from a description, asking only what's needed to write a clear title and body.
---

# /create-issue

First read `.agents/skills/create-issue/SKILL.md`, then follow it step by step — it's the single source for this command's steps, shared with Codex. The issue to create is described in $ARGUMENTS (if empty, ask what it's about).

Claude Code specifics:
- This is a pre-implementation task → the planning model (Opus) is fine; see `workflow/model-strategy.md`. If you aren't running on Opus, tell the user once to run `/model opus` and to switch back with `/model opusplan` before `/work-issue` (`/model` also saves the choice as the default for new sessions), then continue without waiting. Don't suggest plan mode instead.
- Where the playbook says "the <name> skill", that's the `/<name>` command here.
