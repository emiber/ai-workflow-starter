---
name: finish-epic
description: Open the integration PR (epic branch → main) when an epic's children are done. Use when asked to finish, close out, or ship an epic. Logic lives in workflow/epics.md.
---

# finish-epic

Close out the target epic (its number on GitHub or key on Jira — provided as the argument, or stated by the user) by opening its integration PR, following the contract in `workflow/epics.md`. This is the canonical playbook: Codex runs it directly and the Claude Code `/finish-epic` command delegates to it.

1. Read `workflow/rules.md`, `workflow/principles.md`, `workflow/epics.md`, and `workflow/issue-tracker.md`.
2. Run the preflight from `workflow/epics.md` (`/finish-epic` section). It's read-only — if one fails, stop and report the fix. It confirms the target really is an epic and that its integration branch `epic/<n>-<slug>` exists.
3. Fetch the epic and its children. A child is done when its PR into the epic branch is **merged** — the child *issue* may still be open (that's the recommended default). If any child's PR is missing, still open, closed without merging, or merged against the wrong base, **stop and report them and do not open the integration PR** — there is no "proceed anyway".
4. Sync the epic branch with the latest `main` (merge `origin/main` into it, resolve conflicts, push). Never force-push the epic branch.
5. Open the PR `epic/<n>-<slug> → main` with `gh pr create --base main`. Body aggregates `Closes #<n>` plus `Closes #<each child>` (GitHub) so merging closes the whole tree; on Jira, put the Epic key in the title and list child keys.
6. **Don't merge.** Leave the PR open for human review and return its link.

If any step fails, stop and report. Don't improvise destructive workarounds or use `--force`.
