---
name: work-issue
description: Implement a refined issue following the git flow main → branch → implementation → PR. Use when asked to work on or implement an issue.
---

# work-issue

Implement the target issue (its number on GitHub or key on Jira — provided as the argument, or stated by the user) following the contract in `workflow/git-flow.md`. Mirrors the Claude Code `/work-issue` command; the logic lives in `workflow/`.

1. Read `workflow/rules.md`, `workflow/principles.md`, `workflow/git-flow.md`, and `workflow/issue-tracker.md`.
2. Run the preflight checks from `workflow/git-flow.md` before touching anything. They're read-only — if one fails, stop and report the fix. These include `gh` auth and resolving the issue tracker.
3. With the tracker resolved, fetch the issue, verify that it is refined, and read its acceptance criteria. If it isn't refined, suggest the refine-issue skill; if the user insists, refine it minimally on the spot.
4. Pull the latest main (`git checkout main && git pull --ff-only`).
5. Create a branch from main with the convention `<type>/<n>-<slug>`.
6. Implement the minimum that meets the acceptance criteria. Show the plan before writing non-trivial code. Small, descriptive commits.
7. Run the linter and tests, verifying coverage meets the project threshold. Push and open the PR with `gh pr create`. Reference: `Closes #<n>` on GitHub, or the key `[<KEY>]` in the title/body on Jira.
8. Don't merge. Leave the PR open and return its link.

If any step fails, stop the flow and report. Don't improvise destructive workarounds or use `--force`.
