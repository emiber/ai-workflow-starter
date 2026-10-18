---
name: create-issue
description: Creates a new issue (GitHub or Jira) from a description, asking only what's needed to write a clear title and body.
---

# /create-issue

First read `.agents/skills/create-issue/SKILL.md`, then follow it step by step — it's the single source for this command's steps, shared with Codex. The issue to create is described in $ARGUMENTS (if empty, ask what it's about).

Claude Code specifics:
- This is a pre-implementation task → the planning model (Opus) is fine; see `workflow/model-strategy.md`. If you're not on `opusplan`, `/model opus`.
- Where the playbook says "the <name> skill", that's the `/<name>` command here.
