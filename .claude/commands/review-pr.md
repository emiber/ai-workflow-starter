---
name: review-pr
description: Reviews an open PR against its linked issue(s) and the Definition of Done. Read-only. Reads workflow/pr-review.md.
---

# /review-pr

Follow the playbook in `.agents/skills/review-pr/SKILL.md` — it's the single source for this command's steps, shared with Codex. The target PR is $ARGUMENTS. This command is **read-only**: never commit, push, modify files, approve, or merge.

Claude Code specifics:
- This is a review pass → the execution model (Sonnet) is fine; see `workflow/model-strategy.md`.
- Where the playbook says "the <name> skill", that's the `/<name>` command here.
