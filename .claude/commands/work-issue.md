---
name: work-issue
description: Implements a refined issue following the git flow main → branch → implementation → PR.
---

# /work-issue

Follow the playbook in `.agents/skills/work-issue/SKILL.md` — it's the single source for this command's steps, shared with Codex. The target issue is $ARGUMENTS (a number on GitHub, a key on Jira).

Claude Code specifics:
- This is the implementation phase → use the execution model (Sonnet); see `workflow/model-strategy.md`. If you're not on `opusplan`, switch with `/model sonnet`.
- The self-review runs in a fresh subagent (Agent tool) that gets only the issue, the base branch, and the review instructions — not your plan or reasoning.
- Where the playbook says "the <name> skill", that's the `/<name>` command here.
