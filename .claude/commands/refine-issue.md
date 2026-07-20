---
name: refine-issue
description: Refines and clarifies an issue (GitHub or Jira) by asking all the necessary questions until it's implementable.
---

# /refine-issue

You refine issue $ARGUMENTS.

1. Read `workflow/rules.md`, `workflow/principles.md`, `workflow/issue-refinement.md`, `workflow/model-strategy.md`, and `workflow/issue-tracker.md`. This is the analysis phase → use the planning model (Opus). If you're not on `opusplan`, switch with `/model opus`.
2. Resolve the issue tracker (GitHub/Jira) per `workflow/issue-tracker.md`: read `.workflow-config` — it ships preset to GitHub, so normally no need to ask. Only ask if the file is missing or has no `issue_tracker`, then save the choice.
3. Fetch issue $ARGUMENTS with the matching tracker command (number on GitHub, key on Jira).
4. List ambiguities (goal, scope, behavior, data, dependencies, acceptance criteria, non-functional).
5. Ask the user all the necessary questions, in small groups. Don't proceed on assumptions.
6. Write the refined issue following `docs/ISSUE_TEMPLATE.md` and update it with the tracker command (`gh issue edit` / `jira issue edit`). Mark it as refined (label on GitHub, comment/status on Jira).
7. Confirm the result and suggest `/work-issue $ARGUMENTS`.

Don't inflate the scope. If the issue is trivial, say so and confirm in one sentence instead of running the full ritual.
