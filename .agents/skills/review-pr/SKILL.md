---
name: review-pr
description: Review an open PR against its linked issue(s) and the Definition of Done. Use when asked to review a pull request. Read-only. Logic lives in workflow/pr-review.md.
---

# review-pr

Review the target open PR (its number — provided as the argument, or stated by the user) against its linked issue(s) and the Definition of Done, following the contract in `workflow/pr-review.md`. This is the canonical playbook: Codex runs it directly and the Claude Code `/review-pr` command delegates to it. This is **read-only**: never commit, push, or modify files.

1. Read `workflow/rules.md`, `workflow/principles.md`, `workflow/pr-review.md`, `workflow/git-flow.md` (for the Definition of Done), and `workflow/issue-tracker.md`.
2. Run the preflight from `workflow/pr-review.md`. It's read-only — if one fails, stop and report the fix. It confirms `gh` is authenticated and the PR exists and is open (if merged/closed, stop — there's nothing to review).
3. Fetch the PR, find and fetch its linked issue(s) (GitHub `Closes/Refs #<n>`, or a Jira key), and read the diff. Write the PR intent — what it's for and what it deliberately leaves alone — and judge scope against it.
4. Check each Definition of Done item from `workflow/git-flow.md`, including the **Security checklist** and the PR's **Verification** section: mark **pass**, **fail** (blocker), or **warn** (unverifiable from the diff alone).
5. Report the structured review: **Intent**, **Blockers**, **Suggestions**, and a **Summary**. Report blockers and unverifiable items; never recommend or make the merge decision — that belongs to the human reviewer.

Never commit, push, modify files, approve, or merge. If any step fails, stop and report.
