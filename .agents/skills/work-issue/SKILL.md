---
name: work-issue
description: Implement a refined issue following the git flow main → branch → implementation → PR. Use when asked to work on or implement an issue.
---

# work-issue

Implement the target issue (its number on GitHub or key on Jira — provided as the argument, or stated by the user) following the contract in `workflow/git-flow.md`. This is the canonical playbook: Codex runs it directly and the Claude Code `/work-issue` command delegates to it. The detailed rules live in `workflow/`.

1. Read `workflow/rules.md`, `workflow/principles.md`, `workflow/git-flow.md`, `workflow/epics.md`, `workflow/pr-review.md` (for the self-review), and `workflow/issue-tracker.md`.
2. Run the full **Preflight checks** from `workflow/git-flow.md` before touching anything. They're read-only — if one fails, stop and report the fix. These include `gh` auth and resolving the issue tracker.
3. With the tracker resolved, fetch and read the full refined issue, including its acceptance criteria and confirmed assumptions, then verify that it is refined. Check whether it has a **parent epic** (per `workflow/epics.md`) — that changes the base branch in steps 5 and 9. If it isn't refined, suggest the refine-issue skill; if the user insists, refine it minimally on the spot.
4. Pull the latest main (`git checkout main && git pull --ff-only`).
5. Create the working branch `<type>/<n>-<slug>`. No parent → cut from `main`. Child of an epic → cut from the epic's integration branch `epic/<epicN>-<slug>`, creating it lazily from `main` if this is the first child (see `workflow/epics.md`).
6. Get your bearings first: start from the issue's most concrete anchor and trace only the owning path and nearest tests until you can state the expected behavior, smallest plausible change, and a focused check. Then **post the plan in the chat and wait for explicit approval** before writing code — understanding of the acceptance criteria, files to touch, steps, test plan, open questions (trivial change: confirm it in one sentence instead; see `workflow/git-flow.md` step 4).
7. Implement the approved plan — the minimum that satisfies the full refined issue, including its acceptance criteria. Small, descriptive commits. Run the lint and test-with-coverage commands from the **Quality gate** in `docs/ARCHITECTURE.md`; coverage must meet the threshold, and note any new or changed file below it.
8. **Self-review** (`workflow/git-flow.md` step 5): have a fresh agent with a clean context review `git diff <base>...HEAD` following `workflow/pr-review.md` in local diff mode. Fix blockers, re-run lint and tests, review once more. If blockers remain, stop and report — don't open the PR.
9. Push and open the PR with `gh pr create --base <main | epic/<epicN>-<slug>>`. Reference: `Closes #<n>` (standalone) or `Refs #<n>` (child of an epic — closed later by finish-epic) on GitHub, or the key `[<KEY>]` in the title/body on Jira. The body has a **Verification** section listing every gate as pass or n/a with the reason — never omit one, never report one you didn't run — and an **Out of scope / follow-ups** section.
10. **Offer follow-ups** (`workflow/git-flow.md` step 7): if the work left real loose ends, propose them as issues and create only the ones the user approves, following `workflow/issue-creation.md`. If there are none, say so.
11. Don't merge. Leave the PR open and return its link. If this was the last child of an epic, suggest the finish-epic skill.

If any step fails, stop the flow and report. Don't improvise destructive workarounds or use `--force`.
