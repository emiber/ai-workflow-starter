---
name: create-issue
description: Creates a new issue (GitHub or Jira) from a description, asking only what's needed to write a clear title and body.
---

# /create-issue

You create a new issue from $ARGUMENTS (a description of what the issue is about).

1. Read `workflow/rules.md`, `workflow/principles.md`, `workflow/issue-creation.md`, `workflow/epics.md`, and `workflow/issue-tracker.md`. This is a pre-implementation task → the planning model (Opus) is fine; if you're not on `opusplan`, `/model opus`.
2. Resolve the issue tracker (GitHub/Jira) per `workflow/issue-tracker.md`: read `.workflow-config` — it ships preset to GitHub, so normally no need to ask. Make sure the tracker CLI is authenticated (`gh auth status` / `jira me`).
3. Understand the request from $ARGUMENTS. If it's empty, ask what the issue is about. Ask only what's missing to write a clear title and body — this is capture, not refinement.
4. Assess size and placement (propose-and-confirm, per `workflow/epics.md`): if it's epic-sized, ask whether to create an epic or a single issue; if it fits an existing open epic, propose linking it as a child. Skip this for a plain, self-contained issue (the common case).
5. Draft a concise issue (short imperative title + a body with the problem and known context). Show it and confirm before creating.
6. Create it with the tracker command (`gh issue create` / `jira issue create`), applying the `epic` label or the child sub-issue/Epic Link if step 4 decided so.
7. Confirm with the issue number/key and URL, and suggest `/refine-issue <n>` to make it implementable.

Don't over-specify. Don't invent scope, acceptance criteria, or a solution — that's `/refine-issue`'s job.
