---
name: work-issue
description: Implements a refined issue following the git flow main → branch → implementation → PR.
---

# /work-issue

You implement issue $ARGUMENTS following the contract in `workflow/git-flow.md`.

1. Read `workflow/rules.md`, `workflow/principles.md`, `workflow/git-flow.md`, `workflow/model-strategy.md`, and `workflow/issue-tracker.md`. This is the implementation phase → use the execution model (Sonnet). If you're not on `opusplan`, switch with `/model sonnet`.
2. Run the full **Preflight checks** from `workflow/git-flow.md` before touching anything. They're read-only — if one fails, stop and report the fix. These include `gh` auth and resolving the issue tracker (GitHub/Jira) per `workflow/issue-tracker.md`.
3. With the tracker resolved, fetch issue $ARGUMENTS, verify that it is refined, and read its acceptance criteria. If it isn't refined, suggest `/refine-issue $ARGUMENTS`; if the user insists, refine it minimally on the spot.
4. Pull the latest main (`git checkout main && git pull --ff-only`).
5. Create a new branch from main with the convention `<type>/$ARGUMENTS-<slug>`.
6. Implement the minimum that meets the acceptance criteria. Show the plan before writing non-trivial code. Small commits.
7. Run the linter and tests. Push and create the PR with `gh pr create`. Issue reference: `Closes #$ARGUMENTS` on GitHub, or the key `[$ARGUMENTS]` in the title/body if it's Jira.
8. **Don't merge.** Return the PR link.

If any step fails, stop the flow and report. Don't improvise destructive workarounds or use `--force`.
