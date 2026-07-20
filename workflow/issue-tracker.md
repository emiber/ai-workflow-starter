# Issue tracker configuration

The issue flow supports **GitHub** (by default) and **Jira**. The choice is saved once per project.

## Where it's saved

In `.workflow-config` at the project root. Simple `key=value` format:

```
issue_tracker=github
```

or

```
issue_tracker=jira
jira_project=ABC
```

## How it's resolved when running an issue command

`.workflow-config` **ships with `issue_tracker=github`**, so by default the agent uses GitHub and never asks. To switch to Jira, edit that file (see below). Any command that touches issues (`/create-issue`, `/refine-issue`, `/work-issue`) resolves the tracker **before doing anything**:

1. Does `.workflow-config` exist with `issue_tracker`? → use that value, don't ask. (This is the normal case — the file ships preset to `github`.)
2. Only if the file is missing or has no `issue_tracker` → ask the user:
   > Which issue tracker do you use in this project? (github / jira) [default: github]
   Then save the answer in `.workflow-config` so it doesn't ask again.

If the user doesn't answer or answers empty, assume **github**.

## Commands per tracker

### GitHub (default)

- View issue: `gh issue view <n>`
- Edit issue: `gh issue edit <n>`
- Create issue: `gh issue create`
- Reference in PR: `Closes #<n>`
- Requires: `gh` authenticated (`gh auth status`).

### Jira

- View issue: `jira issue view <KEY>` (e.g. `jira issue view ABC-123`)
- Edit/comment: `jira issue edit <KEY>` / `jira issue comment add <KEY>`
- Create issue: `jira issue create`
- Reference in PR: include the key in the PR title/body (e.g. `[ABC-123] ...`). Jira does **not** close the issue automatically via the GitHub PR unless there's an integration configured; assume closing is done by a human or Jira automation, not the flow.
- Requires: `jira` CLI configured (`jira me` to verify).

> Note on key vs. number: on GitHub the issue is a number (`42`); on Jira it's a key (`ABC-123`). When the user passes the argument, take it as-is: if the tracker is Jira, expect a key; if GitHub, a number.

## What does NOT change between trackers

The git flow is identical in both cases: `main → branch → implementation → PR` (see `git-flow.md`). The PR always goes to GitHub. The only thing that changes is where the issue is read from / written to.
