---
name: refine-issue
description: Refine and clarify an issue (GitHub or Jira) by asking every question needed until it's implementable. Use when asked to refine or clarify an issue before implementing it.
---

# refine-issue

Refine the target issue (its number on GitHub or key on Jira — provided as the argument, or stated by the user). Mirrors the Claude Code `/refine-issue` command; the logic lives in `workflow/`.

1. Read `workflow/rules.md`, `workflow/principles.md`, `workflow/issue-refinement.md`, and `workflow/issue-tracker.md`.
2. Resolve the issue tracker per `workflow/issue-tracker.md` — `.workflow-config` ships preset to GitHub, so only ask if it's missing. Make sure the tracker CLI is authenticated (`gh auth status` for GitHub, `jira me` for Jira).
3. Fetch the issue and list its ambiguities: goal, scope, behavior, data, dependencies, acceptance criteria, non-functional.
4. Ask the user the questions needed to close them, in small groups. Don't proceed on assumptions.
5. Write the refined issue following `docs/ISSUE_TEMPLATE.md` and update it with the tracker command. Mark it as refined (label on GitHub, comment/status on Jira).
6. Confirm the result and suggest running the work-issue skill.

Don't inflate scope. If the issue is trivial, say so and confirm in one sentence instead of running the full ritual.
