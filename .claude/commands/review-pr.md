---
name: review-pr
description: Reviews an open PR against its linked issue's acceptance criteria and the Definition of Done. Read-only. Reads workflow/pr-review.md.
---

# /review-pr

You review the open PR $ARGUMENTS against its linked issue and the Definition of Done, following the contract in `workflow/pr-review.md`. This command is **read-only**: never commit, push, or modify files.

1. Read `workflow/rules.md`, `workflow/principles.md`, `workflow/pr-review.md`, `workflow/git-flow.md` (for the Definition of Done), and `workflow/issue-tracker.md`. This is a review pass → the execution model (Sonnet) is fine.
2. Run the preflight from `workflow/pr-review.md`. It's read-only — if one fails, stop and report the fix. It confirms `gh` is authenticated and the PR exists and is open (if merged/closed, stop — there's nothing to review).
3. Fetch the PR, find and fetch its linked issue (GitHub `Closes/Refs #<n>`, or a Jira key), and read the diff.
4. Check each Definition of Done item from `workflow/git-flow.md`: mark **pass**, **fail** (blocker), or **warn** (unverifiable from the diff alone).
5. Report the structured review: **Blockers**, **Suggestions**, and a **Summary**. Report blockers and unverifiable items; never recommend or make the merge decision — that belongs to the human reviewer.

Never commit, push, modify files, approve, or merge. If any step fails, stop and report.
