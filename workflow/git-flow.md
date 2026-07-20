# Git flow — contract

Guide for `/work-issue <n>`. Defines the `main → branch → implementation → PR` cycle. This contract is **strict**: don't modify it unless the user asks.

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

### 2. Pull the latest main

```bash
git checkout main
git pull --ff-only origin main
```

If the pull fails due to conflicts or divergence, stop and warn the user. Don't force it.

### 3. Create a new branch from main

Branch name derived from the issue. Convention:

```
<type>/<n>-<short-slug>
```

where `<type>` is `feat`, `fix`, `chore`, `refactor`, `docs`, etc., and `<short-slug>` is a kebab-case summary of the title.

```bash
git checkout -b feat/<n>-<slug>
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

The PR always goes to GitHub. The reference to the issue depends on the tracker:

- **GitHub**: include `Closes #<n>` in the body so the issue closes on merge.
- **Jira**: include the key in the title (e.g. `[ABC-123] <title>`) and mention it in the body. Closing the Jira issue is handled by a human or Jira automation, not this flow.

```bash
git push -u origin feat/<id>-<slug>
gh pr create \
  --base main \
  --title "<type>: <title>" \
  --body "<issue reference: 'Closes #<n>' on GitHub, '[ABC-123]' on Jira>

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
- [ ] PR opened against `main` and left open for review (not merged).

## Hard rules

- Never commit or push to `main` directly.
- Never `git commit` or `git push` unless the user explicitly asked for it (running `/work-issue` is an explicit request for its commit → push → PR flow). Don't commit or push on your own initiative.
- Never `git push --force` to shared branches.
- Never auto-merge.
- Never skip git hooks (`--no-verify`) or weaken tests just to get a green run.
- If any step fails, stop the flow and report; don't improvise destructive workarounds.
