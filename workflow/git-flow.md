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
| Working tree clean | `git status --porcelain` is empty | Commit, stash, or discard changes before starting. |
| Tracker resolved | see `workflow/issue-tracker.md` | Defaults to GitHub via `.workflow-config`. |
| Tracker authenticated | Jira only: `jira me` (GitHub already covered above) | Authenticate the Jira CLI and retry. |

## Steps

### 1. Fetch and verify the issue

Fetch the issue using the selected tracker and read its acceptance criteria. Verify
that it is refined per `workflow/issue-refinement.md`. If it isn't, suggest refining
it first; if the user insists, refine it minimally on the spot.

Also check whether the issue has a **parent epic** — determine this from structured data,
not a guess:

- **GitHub**: `gh issue view <n> --json parent` — a non-null `.parent` means the issue is a
  child of that epic (`gh` ≥ 2.94; see `workflow/issue-tracker.md`).
- **Jira**: it has an Epic Link / parent field.

If it does, this is a child of an epic and uses the **integration-branch flow** — steps 3
and 5 change as noted below (see `workflow/epics.md`). If it has no parent, the flow is
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
- Follow `workflow/principles.md`: the minimum that meets the issue's acceptance criteria.
- Keep the change scoped to this one issue: one PR = one issue. If you spot unrelated work, note it as a separate issue instead of expanding this PR.
- Before writing non-trivial code, show the plan and wait for confirmation.
- Never stage or commit secrets or credentials. Keep them in gitignored `.env` files; add placeholders to `.env.example` when config is needed.
- Small, descriptive commits. Suggested format (Conventional Commits):

```
<type>(<area>): <short description>

Refs #<n>
```

- Every new component ships with unit tests, and test coverage must meet the threshold in `docs/ARCHITECTURE.md` (default 85% — see `workflow/principles.md`).
- Run the linter and tests locally before the PR, and verify coverage meets that threshold. If something fails or coverage is below it, fix it before opening the PR.

### 5. Push and PR

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

## How it was tested
..."
```

### 6. Closing

- **Don't merge.** Leave the PR open for human review.
- Return the PR link to the user.

## Definition of Done

An issue isn't done until all of these hold. Check them before opening the PR:

- [ ] The issue's acceptance criteria are met.
- [ ] New components have unit tests; coverage meets the threshold in `docs/ARCHITECTURE.md` (default 85%).
- [ ] Linter and tests pass locally.
- [ ] No secrets or credentials committed.
- [ ] Docs updated if behavior or setup changed (`README` / `ARCHITECTURE` / etc.).
- [ ] PR opened and left open for review (not merged) — against `main`, or against the epic's integration branch if the issue is a child of an epic (see `workflow/epics.md`).

## Hard rules

- Never commit or push to `main` directly.
- Never `git commit` or `git push` unless the user explicitly asked for it (running `/work-issue` is an explicit request for its commit → push → PR flow). Don't commit or push on your own initiative.
- Never `git push --force` to shared branches.
- Never auto-merge.
- Never skip git hooks (`--no-verify`) or weaken tests just to get a green run.
- If any step fails, stop the flow and report; don't improvise destructive workarounds.
