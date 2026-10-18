---
name: create-issue
description: Create a new issue (GitHub or Jira) from a description, asking only what's needed to write a clear title and body. Use when asked to create, open, or file a new issue.
---

# create-issue

Create a new issue from the description the user gives (as the argument or in their message). This is the canonical playbook: Codex runs it directly and the Claude Code `/create-issue` command delegates to it. The detailed rules live in `workflow/`.

1. Read `workflow/rules.md`, `workflow/principles.md`, `workflow/issue-creation.md`, `workflow/epics.md`, and `workflow/issue-tracker.md`.
2. Resolve the issue tracker per `workflow/issue-tracker.md` — `.workflow-config` ships preset to GitHub, so only ask if it's missing. Make sure the tracker CLI is authenticated (`gh auth status` for GitHub, `jira me` for Jira).
3. Understand the request. If it's empty, ask what the issue is about. Ask only what's missing to write a clear title and body — this is capture, not refinement.
4. Check for duplicates (per `workflow/issue-creation.md`): search open issues for the same problem. If one plausibly matches, show it and ask whether to add to it instead or create a new issue anyway.
5. Assess size and placement (propose-and-confirm, per `workflow/epics.md`): if it's epic-sized, ask whether to create an epic or a single issue; if it fits an existing open epic, propose linking it as a child. Skip this for a plain, self-contained issue (the common case).
6. Draft a concise issue (short imperative title + a body with the problem and known context). Show it and confirm before creating.
7. Create it with the tracker command (`gh issue create` / `jira issue create`), applying the `epic` label or the child sub-issue/Epic Link if step 5 decided so.
8. Confirm with the issue number/key and URL, and suggest running the refine-issue skill to make it implementable.

Don't over-specify. Don't invent scope, acceptance criteria, or a solution — that's the refine-issue skill's job.
