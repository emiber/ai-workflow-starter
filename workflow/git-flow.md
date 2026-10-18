# Git flow — contract

Guide for `/work-issue <n>`. Defines the `main → branch → implementation → PR` cycle. This contract is **strict**: don't modify it unless the user asks. Issues that belong to an epic add an integration-branch layer on top of this cycle (child branches target the epic's branch, not `main`) — see `workflow/epics.md`.

## Preflight checks

Run these **before touching anything**. They're read-only — if one fails, stop and report the fix; never modify the workspace to force a pass.

| Check | How | If it fails |
|---|---|---|
| `git` installed | `git --version` | Install Git and retry. |
| Inside a Git repo | `git rev-parse --is-inside-work-tree` | Run `git init` (or `cd` into the repo) first. |
| `main` branch exists | `git show-ref --verify refs/heads/main` | Create it, or tell the agent your default branch name. |
| `origin` remote set | `git remote get-url origin` | `git remote add origin <url>` — needed for push/PR. |
| `gh` authenticated | `gh auth status` | `gh auth login`. The PR always goes to GitHub, whatever the issue tracker. |
| `gh` supports sub-issues (≥ 2.94) | `gh --version` (compare to 2.94.0) | Upgrade `gh`; or, on older `gh` / GitHub Enterprise Server, use the REST fallback in `workflow/issue-tracker.md` for parent detection and sub-issue links. Step 1 reads an issue's `parent` to detect epics, so this is required whenever epics are in play. |
| Working tree clean | `git status --porcelain` is empty | Commit, stash, or discard changes before starting. |
| Tracker resolved | see `workflow/issue-tracker.md` | Defaults to GitHub via `.workflow-config`. |
| Tracker authenticated | Jira only: `jira me` (GitHub already covered above) | Authenticate the Jira CLI and retry. |

## Steps

### 1. Fetch and verify the issue

Fetch the issue using the selected tracker and read the full refined issue, including its acceptance criteria and any confirmed assumptions. Verify
that it is refined per `workflow/issue-refinement.md`. If it isn't, suggest refining
it first; if the user insists, refine it minimally on the spot.

Also check whether the issue has a **parent epic** — determine this from structured data,
not a guess:

- **GitHub**: `gh issue view <n> --json parent` — a non-null `.parent` means the issue is a
  child of that epic (`gh` ≥ 2.94; see `workflow/issue-tracker.md`).
- **Jira**: it has an Epic Link / parent field.

If it does, this is a child of an epic and uses the **integration-branch flow** — steps 3
and 6 change as noted below (see `workflow/epics.md`). If it has no parent, the flow is
exactly as written.

### 2. Pull the latest main

```bash
git checkout main
git pull --ff-only origin main
```

If the pull fails due to conflicts or divergence, stop and warn the user. Don't force it.

### 3. Create the working branch

Branch name derived from the issue. Convention:

```
<type>/<n>-<short-slug>
```

where `<type>` is `feat`, `fix`, `chore`, `refactor`, `docs`, etc., and `<short-slug>` is a kebab-case summary of the title.

**No parent epic (the common case):** branch off `main`.

```bash
git checkout -b feat/<n>-<slug>
```

**Issue has a parent epic:** branch off the epic's integration branch instead of
`main`, and create that branch **lazily** from `main` if this is the first child (see
`workflow/epics.md`).

```bash
# epicN / epic-slug come from the parent epic
git fetch origin
if ! git show-ref --verify --quiet refs/heads/epic/<epicN>-<slug> \
   && ! git ls-remote --exit-code --heads origin epic/<epicN>-<slug> >/dev/null; then
  # first child → create the integration branch from the latest main and publish it
  git checkout main && git pull --ff-only origin main
  git checkout -b epic/<epicN>-<slug>
  git push -u origin epic/<epicN>-<slug>
fi
git checkout epic/<epicN>-<slug> && git pull --ff-only origin epic/<epicN>-<slug>
git checkout -b feat/<n>-<slug>       # child branch, cut from the epic branch
```

### 4. Implement

- **Model**: this phase is implementation → use the execution model (Sonnet). See `workflow/model-strategy.md`. If you're coming from planning with Opus, switch with `/model sonnet` or let `opusplan` do it on its own.
- **Get your bearings first.** Start from the issue's most concrete anchor and trace only the owning code path, its immediate callers and data flow, and the nearest tests. Stop exploring once you can state the expected behavior, the smallest plausible change, and a focused check that could disprove it. Keep this pass read-only; use plain reading and search, and don't add tooling for it.
- **Plan approval — before writing any code.** Post the plan in the chat and wait for the user's explicit approval ("go ahead", "approved", …). A question or a vague comment is not approval: answer it and ask again. The plan covers:
  - **Understanding** — the goal and each acceptance criterion, one line each.
  - **Files** — what you'll create or change.
  - **Steps** — in order.
  - **Test plan** — the tests you'll add or update, and the edge cases they cover.
  - **Open questions** — anything that blocks correctness. Ask instead of guessing.

  A **trivial** change (a typo, a one-line fix, a docs tweak with no behavior change) skips the full plan: state the change in one sentence and get a yes. If the user adjusts the plan, implement the adjusted version.
- Follow `workflow/principles.md`: the minimum that satisfies the full refined issue, including its acceptance criteria.
- Keep the change scoped to this one issue: one PR = one issue. If you spot unrelated work, don't expand this PR: list it under **Out of scope / follow-ups** in the PR body and offer it as an issue in step 7.
- Never stage or commit secrets or credentials. Keep them in gitignored `.env` files; add placeholders to `.env.example` when config is needed.
- Small, descriptive commits. Suggested format (Conventional Commits):

```
<type>(<area>): <short description>

Refs #<n>
```

- Every new component ships with unit tests, and test coverage must meet the threshold in `docs/ARCHITECTURE.md` (default 85% — see `workflow/principles.md`).
- **Run the quality gate locally**: the lint and test-with-coverage commands recorded in the **Quality gate** section of `docs/ARCHITECTURE.md` — the same ones CI runs. If the file doesn't list them (a project initialized before they were recorded), detect them from the project (package scripts, `pyproject.toml`, `.github/workflows/ci.yml`), use them, and propose recording them as a follow-up (step 7). If something fails or coverage is below the threshold, fix it before going on.
- **Check the coverage of what you touched**, not just the total: a change can keep the global number above the threshold while its own new code is barely tested. List any new or changed source file below the threshold in the PR's **Verification** section, and add tests unless there's a real reason (say which).

### 5. Self-review — before the PR

With the quality gate green and the work committed, get an independent review before anyone else sees the change. Your context is full of your own assumptions; a reviewer that sees only the issue and the diff catches what they hide.

1. **Review in a clean context.** Start a fresh agent (on Claude Code, a subagent on the execution model) and give it only: the issue number, the base branch (`main`, or `epic/<epicN>-<slug>` for an epic child), and the instruction to review `git diff <base>...HEAD` following `workflow/pr-review.md` in **local diff mode**. Don't pass your plan or your reasoning. It reports; it doesn't edit. If you can't start a separate agent, run the same review yourself and say so in Verification ("inline").
2. **Triage what comes back:**
   - **Blockers** → fix them, commit the fixes (the review only sees committed work), re-run the quality gate, and run the review **once more**. If blockers remain after that second review, stop: don't open the PR — report them to the user with your proposed way forward.
   - **Suggestions** within the issue's scope → apply the cheap, clearly-right ones; list the rest on the Self-review line of the PR's Verification section.
   - Anything **outside the issue's scope** → a follow-up (step 7), not a change to this PR.
3. Record the outcome on the **Self-review** line of the PR's Verification section.

A **trivial** change (see step 4) may skip the separate agent: check the diff against the same contract inline and note it in Verification.

### 6. Push and PR

The PR always goes to GitHub. Two things depend on whether the issue has a parent epic:
the **base branch** and the **issue reference**.

- **Base branch**: `main` normally; the epic's integration branch (`epic/<epicN>-<slug>`)
  if the issue is a child of an epic.
- **Issue reference** (GitHub):
  - No parent → `Closes #<n>` so the issue closes when the PR merges into `main`.
  - Child of an epic → `Refs #<n>`, **not** `Closes`. A closing keyword only fires when the
    PR merges into the default branch, and this PR targets the epic branch. Children are
    closed later, all at once, by the `/finish-epic` PR into `main` (see `workflow/epics.md`).
- **Issue reference** (Jira): include the key in the title (e.g. `[ABC-123] <title>`) and
  mention it in the body. Closing the Jira issue is handled by a human or Jira automation,
  not this flow — same regardless of epics.

```bash
git push -u origin feat/<n>-<slug>
gh pr create \
  --base <main, or epic/<epicN>-<slug> for a child> \
  --title "<type>: <title>" \
  --body "<issue reference: 'Closes #<n>' (standalone) / 'Refs #<n>' (child) on GitHub, '[ABC-123]' on Jira>

## What it does
...

## Verification
- Lint: <command> — pass
- Tests: <command> — pass
- Coverage: <total>% (threshold <t>%); new/changed files below threshold: none | <file — reason>
- Self-review: <blockers found and fixed, or none>; suggestions not applied: <list, or none> (separate agent | inline)
- Security: pass | no security surface touched
- Docs: updated <files> | not needed (<reason>)

## Out of scope / follow-ups
None | - <item>"
```

A long body is easier to pass with `--body-file <file>` (and avoids shell-quoting trouble, especially in PowerShell).

**Verification rules.** Every gate gets a line. A gate that doesn't apply (e.g. no tests for a docs-only change) is `n/a` with the reason — never dropped. Never report a gate as passed unless you ran it in this session. A failing gate never appears in a PR: it stops the flow until it's fixed (or you report to the user) — the PR opens only with every gate passing or `n/a`.

### 7. Offer follow-ups

If the work surfaced **real** loose ends — unrelated bugs you noticed, scope deliberately left out, self-review findings outside the issue's scope, a deliberate TODO — list them and **offer** to create them as issues. Nothing is created until the user approves; they may edit or drop items.

- Create each approved item following `workflow/issue-creation.md` (it checks for duplicates first), referencing the source: `Follow-up of #<n>`. For a child of an epic, ask whether the follow-up belongs under the same epic.
- Then update the PR's **Out of scope / follow-ups** section with the new issue numbers (`gh pr edit <pr> --body-file <file>`).
- No real loose ends → say so and skip. Never invent follow-ups to look thorough.

### 8. Closing

- **Don't merge.** Leave the PR open for human review.
- Return the PR link to the user.

## Definition of Done

An issue isn't done until all of these hold. Check them before opening the PR:

- [ ] All applicable requirements in the refined issue are met, including its acceptance criteria.
- [ ] The plan was approved before implementing (or the change was confirmed as trivial).
- [ ] New components have unit tests; coverage meets the threshold in `docs/ARCHITECTURE.md` (default 85%), and any new or changed file below it is listed in Verification with the reason.
- [ ] Linter and tests pass locally, using the Quality gate commands in `docs/ARCHITECTURE.md`.
- [ ] The self-review (step 5) left no unresolved blockers.
- [ ] No secrets or credentials committed, and the change passes the Security checklist in `workflow/pr-review.md` (or touches no security surface).
- [ ] Docs updated if behavior or setup changed (`README` / `ARCHITECTURE` / etc.).
- [ ] The PR body's **Verification** section reports every gate — pass, or `n/a` with the reason — and **Out of scope / follow-ups** lists what was left out (or "None").
- [ ] PR opened and left open for review (not merged) — against `main`, or against the epic's integration branch if the issue is a child of an epic (see `workflow/epics.md`).

## Hard rules

- Never commit or push to `main` directly.
- Never `git commit` or `git push` unless the user explicitly asked for it (running `/work-issue` is an explicit request for its commit → push → PR flow). Don't commit or push on your own initiative.
- Never `git push --force` to shared branches.
- Never auto-merge.
- Never skip git hooks (`--no-verify`) or weaken tests just to get a green run.
- If any step fails, stop the flow and report; don't improvise destructive workarounds.
