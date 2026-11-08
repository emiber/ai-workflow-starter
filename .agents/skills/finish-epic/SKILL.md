---
name: finish-epic
description: Open the integration PR (epic branch → main) when an epic's children are done. Use when asked to finish, close out, or ship an epic. Logic lives in workflow/epics.md.
---

# finish-epic

Close out the target epic (its number on GitHub or key on Jira — provided as the argument, or stated by the user) by opening its integration PR, following the contract in `workflow/epics.md`. This is the canonical playbook: Codex runs it directly and the Claude Code `/finish-epic` command delegates to it.

1. Read `workflow/rules.md`, `workflow/principles.md`, `workflow/epics.md`, and `workflow/issue-tracker.md`.
2. Run the preflight from `workflow/epics.md` (`/finish-epic` section). It's read-only — if one fails, stop and report the fix. It confirms the target really is an epic and finds its integration branch by number: the one branch matching the `epic/<n>-` prefix, locally or on `origin`, never a slug re-derived from the title. None, more than one, or a failed lookup stops the flow. Every later step uses the resolved branch.
3. Fetch the epic and its children, and use that list only once the listing command has succeeded — with the REST fallback, every page (see `workflow/epics.md` step 1 and `workflow/issue-tracker.md`). If the listing fails, even after printing some children, discard its output and stop: report the epic and the error, before any sync, push, `Closes` line, or PR. Then list the PRs into the resolved epic branch (`gh pr list --base <epic branch> --state all`; see `workflow/epics.md` step 2) and check every child on the list. A child's PRs are those whose head branch matches `*/<childN>-*`, and the child is done when one of them is **merged** — the child *issue* may still be open (that's the recommended default). If any child is missing (no PR into the epic branch), still open, or closed without merging, or the lookup fails, **stop and report them and do not open the integration PR** — there is no "proceed anyway".
4. Sync the resolved epic branch with the latest `main`, as in `workflow/epics.md` step 3: fetch and check it out; stop and report if the local epic branch has commits that aren't on `origin`, ahead or diverged (the ancestry check); otherwise fast-forward it from `origin`, then merge `main` into it (`git merge origin/main`), resolve conflicts, and push. Never reset, rebase, or force-push the epic branch.
5. Open the PR from the resolved epic branch to `main` with `gh pr create --base main`. Body aggregates `Closes #<n>` plus one `Closes #<child>` per child on step 3's list, each exactly once (GitHub), so merging closes the whole tree; on Jira, put the Epic key in the title and list child keys.
6. **Don't merge.** Leave the PR open for human review and return its link.

If any step fails, stop and report. Don't improvise destructive workarounds or use `--force`.
