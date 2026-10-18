---
name: refine-issue
description: Refine and clarify an issue (GitHub or Jira) by asking every question needed until it's implementable. Use when asked to refine or clarify an issue before implementing it.
---

# refine-issue

Refine the target issue (its number on GitHub or key on Jira — provided as the argument, or stated by the user). This is the canonical playbook: Codex runs it directly and the Claude Code `/refine-issue` command delegates to it. The detailed rules live in `workflow/`.

1. Read `workflow/rules.md`, `workflow/principles.md`, `workflow/issue-refinement.md`, and `workflow/issue-tracker.md`.
2. Resolve the issue tracker per `workflow/issue-tracker.md` — `.workflow-config` ships preset to GitHub, so only ask if the file is missing or has no `issue_tracker`, then save the choice. Make sure the tracker CLI is authenticated (`gh auth status` for GitHub, `jira me` for Jira).
3. Fetch the issue with the matching tracker command (number on GitHub, key on Jira).
4. List its ambiguities: goal, scope, behavior, data, dependencies, acceptance criteria, non-functional.
5. Ask the user the questions needed to close them, in small groups. Don't proceed on unconfirmed assumptions. If the user delegates a decision, propose and confirm a concrete choice, record it under **Assumptions**, and reflect its effects in every applicable issue section.
6. Write the refined issue following `docs/ISSUE_TEMPLATE.md` and update it with the tracker command (`gh issue edit` / `jira issue edit`). Mark it as refined (label on GitHub, comment/status on Jira).
7. Confirm the result and suggest running the work-issue skill.

Don't inflate scope. If the issue is trivial, say so and confirm in one sentence instead of running the full ritual.
