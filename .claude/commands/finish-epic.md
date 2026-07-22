---
name: finish-epic
description: Opens the integration PR (epic branch → main) when an epic's children are done. Reads workflow/epics.md.
---

# /finish-epic

You close out epic $ARGUMENTS by opening its integration PR, following the contract in `workflow/epics.md`.

1. Read `workflow/rules.md`, `workflow/principles.md`, `workflow/epics.md`, and `workflow/issue-tracker.md`. This wraps up implementation → the execution model (Sonnet) is fine.
2. Run the preflight from `workflow/epics.md` (`/finish-epic` section). It's read-only — if one fails, stop and report the fix. It confirms `<n>` really is an epic and that its integration branch `epic/$ARGUMENTS-<slug>` exists.
3. Fetch the epic and its children. Check the children are done (issues closed, child PRs merged into the epic branch). If any aren't, warn, list them, and ask whether to proceed or wait — don't proceed silently.
4. Sync the epic branch with the latest `main` (merge `origin/main` into it, resolve conflicts, push). Never force-push the epic branch.
5. Open the PR `epic/$ARGUMENTS-<slug> → main` with `gh pr create --base main`. Body aggregates `Closes #$ARGUMENTS` plus `Closes #<each child>` (GitHub) so merging closes the whole tree; on Jira, put the Epic key in the title and list child keys.
6. **Don't merge.** Leave the PR open for human review and return its link.

If any step fails, stop and report. Don't improvise destructive workarounds or use `--force`.
