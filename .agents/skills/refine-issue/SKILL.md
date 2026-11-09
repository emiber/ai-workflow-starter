---
name: refine-issue
description: Refine and clarify an issue (GitHub or Jira) by asking every question needed until it's implementable. Use when asked to refine or clarify an issue before implementing it.
---

# refine-issue

Refine the target issue (its number on GitHub or key on Jira — provided as the argument, or stated by the user). This is the canonical playbook: Codex runs it directly and the Claude Code `/refine-issue` command delegates to it. The detailed rules live in `workflow/`.

**Where to read files.** This skill may run from a copy of the workflow installed outside the repository you're working in, such as a plugin. Read **workflow files** from the **workflow root**: `workflow/*.md` and `docs/ISSUE_TEMPLATE.md`, including every such path one guide gives for another. The workflow root is the directory that holds this skill's `.agents/` folder, `../../..` from the folder this `SKILL.md` is in. Read **project files** from the current repository: `.workflow-config`, `docs/ARCHITECTURE.md`, the source, the CI config and git. In a repository created from the template, both are the same directory. If a workflow file can't be read from the workflow root, stop and report its path; never use a same-named file from the current repository instead.

1. Read `workflow/rules.md`, `workflow/principles.md`, `workflow/issue-refinement.md`, and `workflow/issue-tracker.md`.
2. Resolve the issue tracker per `workflow/issue-tracker.md` — `.workflow-config` ships preset to GitHub and is required. Only if it's missing or has no `issue_tracker`, ask (an empty answer means GitHub), write the answer to the file, and tell the user to commit it: CI's workflow integrity check fails until it's committed. Make sure the tracker CLI is authenticated (`gh auth status` for GitHub, `jira me` for Jira).
3. Fetch the issue with the matching tracker command (number on GitHub, key on Jira).
4. List its ambiguities: goal, scope, behavior, data, dependencies, acceptance criteria, non-functional.
5. Ask the user the questions needed to close them, in small groups. Don't proceed on unconfirmed assumptions. If the user delegates a decision, propose and confirm a concrete choice, record it under **Assumptions**, and reflect its effects in every applicable issue section.
6. Follow step 4 of `workflow/issue-refinement.md`, in this order:
   - **Draft** the refined issue following `docs/ISSUE_TEMPLATE.md`.
   - **Show** the user the complete draft and what will mark it refined: the `refined` label on GitHub; the refinement comment and any label or status on Jira.
   - **Approve**: wait for the user's explicit approval. A question or a vague reply isn't approval: answer it and ask again. On a change request, revise the draft and show it again. If the user declines, write nothing and say the issue is unchanged. An explicit instruction in the user's request to publish without review is approval given in advance: skip **Show** and the wait, and record the decisions you made yourself under **Assumptions** as "delegated, not confirmed". Silence or "I'm away" is not approval.
   - **Re-fetch** the issue with the same tracker command as in step 3 above, right before writing. If the body or comments changed since you last read it, show the change and get explicit approval on a revised draft, even with approval given in advance (it covers only the issue as you read it). Never overwrite from a stale copy.
   - **Write** the body with the tracker command (`gh issue edit` / `jira issue edit`).
   - **Mark** it as refined (label on GitHub, comment/status on Jira); if applying the `refined` label fails because it doesn't exist, follow **Workflow labels** in `workflow/issue-tracker.md`.
7. Confirm the write with the issue URL (GitHub) or key (Jira) and suggest running the work-issue skill. If it was published on approval given in advance, say it was published unreviewed.

Don't inflate scope. If the issue is trivial, say so and confirm in one sentence instead of running the full ritual. That skips the questions, not step 6: any rewrite of the body is still shown and approved before it's written.
