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

The commands below are those of **[`ankitpokhrel/jira-cli`](https://github.com/ankitpokhrel/jira-cli)** (the `jira` binary, v1.5+) — the specific CLI this workflow targets. Other tools also named `jira` have different command trees, so if you use a different one, map these operations to its equivalents. Install it (e.g. `brew install ankitpokhrel/jira-cli/jira-cli`, or a release binary from the repo), then run `jira init` to authenticate and select the default project.

- View issue: `jira issue view <KEY>` (e.g. `jira issue view ABC-123`)
- Edit/comment: `jira issue edit <KEY>` / `jira issue comment add <KEY>`
- Create issue: `jira issue create`
- Reference in PR: include the key in the PR title/body (e.g. `[ABC-123] ...`). Jira does **not** close the issue automatically via the GitHub PR unless there's an integration configured; assume closing is done by a human or Jira automation, not the flow.
- Requires: `ankitpokhrel/jira-cli` installed and initialized via `jira init` (`jira me` to verify authentication).

> Note on key vs. number: on GitHub the issue is a number (`42`); on Jira it's a key (`ABC-123`). When the user passes the argument, take it as-is: if the tracker is Jira, expect a key; if GitHub, a number.

### Parent/child (epics)

Both trackers can group issues under an epic. The full model — including the integration
branch — is in `workflow/epics.md`. This section is the **single source for the concrete
parent/child commands**; other guides reference it instead of repeating the syntax.

- **GitHub**: an epic is an issue with the `epic` label; children are native **sub-issues**.
  Modern `gh` (**≥ 2.94**) has first-class commands for the relationship — prefer them:

  ```bash
  gh issue list --label epic --state open                  # list open epics
  gh issue create --parent <epicN> --title "…" --body "…"  # create a child already linked
  gh issue edit <epicN> --add-sub-issue <childN>           # link an existing issue as a child
  gh issue edit <childN> --remove-parent                   # unlink a child
  gh issue view <n> --json parent,subIssues,subIssuesSummary
  #   .parent            → the parent issue (null if none); it's an epic only if it passes `workflow/git-flow.md` step 1
  #   .subIssues.nodes[] → an epic's children (use .number)
  #   .subIssuesSummary  → { total, completed, percentCompleted }
  ```

  **Fallback** (gh < 2.94, or GitHub Enterprise Server without these commands): use the REST
  API via `gh api`. **Quote every path** — the `{owner}/{repo}` braces break unquoted in
  PowerShell. All three operations have a fallback:

  ```bash
  # List an epic's children, every page (read the rules below before using the output):
  gh api "repos/{owner}/{repo}/issues/<epicN>/sub_issues" --paginate --jq '.[].number'

  # Link a child — two shell-neutral steps (avoid Bash-only command substitution).
  # 1) read the child's internal id (NOT its issue number):
  gh api "repos/{owner}/{repo}/issues/<childN>" --jq '.id'
  # 2) pass that id as <childId>:
  gh api --method POST "repos/{owner}/{repo}/issues/<epicN>/sub_issues" -F sub_issue_id=<childId>

  # Detect a child's parent — read the parent reference from the issue payload
  # (field name can vary by API version; adjust if empty):
  gh api "repos/{owner}/{repo}/issues/<n>" --jq '.parent.number // .parent_issue_url // empty'
  ```

  **Listing an epic's children (REST).** The endpoint returns the children one page at a
  time, so the list command needs `--paginate`: `gh` follows each next-page link until
  there is none and prints every child's number, one per line, open or closed. It prints
  each page as it arrives, so the output is the full list only if the whole command
  succeeds:

  - Check the exit status before using the output. Bash:
    `children=$(gh api … --paginate --jq '.[].number'); rc=$?`, and don't pipe `gh`
    into another command first (a pipeline returns its last command's status).
    PowerShell: `$children = gh api … --paginate --jq '.[].number'`, then read
    `$LASTEXITCODE` on the very next line. Output proves nothing: a failed run can still
    print numbers from earlier pages, or an error body.
  - **Non-zero exit** — any page failed (authentication, permission, rate limit,
    unsupported endpoint, network) or `--jq` failed → discard everything it printed, stop,
    and report the epic's number and the error, never a token. It's never an empty or a
    partial list. A retry lists again from the first page, under these same rules.
  - **Exit 0** → the list is complete; no output means the epic has no children. Count
    each number once. Completeness comes from the command finishing with no next link
    left, never from a page's size (30, 100, or any other).
  - If you already hold a trustworthy total of this epic's direct children (for example a
    sub-issue summary's `total` from a read you made anyway; don't fetch one for this) and
    it differs from the number of children listed, stop and list again from scratch.
    `completed` is not a total.
  - The pages aren't a snapshot: a child linked or unlinked while they're read, or a wrong
    next link from the server, can go unnoticed unless such a total is at hand.

  Last resort for parent detection, if the payload exposes no parent field on your API
  version: treat the issue as a child when it appears in some `epic`-labeled issue's
  `sub_issues` list. Read each list with the list command and the rules above: every page
  counts, so a match on a later page is found, and a list counts only once its command has
  succeeded. The issue has no epic parent only if every one of those lists was read
  successfully without it. If a list fails before a match is found, the parent lookup has
  failed — never "no parent": don't treat the issue as standalone or base its branch on
  `main` because of it; follow the calling guide's rule for a failed lookup. Only use
  these when the native commands aren't available.

  All these commands, like `gh issue view <n>` above, name issues by bare number in the
  current repository (`gh`'s default repository, which also fills `{owner}/{repo}`). Use
  them only where that is established as the issue's repository, as when `/work-issue`,
  `/create-issue` or `/refine-issue` acts on this project's own issues. An issue that may
  be in another repository, such as a PR's linked issue or its parent in `/review-pr`, is
  read by its URL instead (`gh issue view <issue-url>`; see `workflow/pr-review.md` step 2).
- **Jira**: an epic is the native **Epic** issue type; children carry the **Epic Link /
  parent** field. No label convention needed.

## What does NOT change between trackers

The git flow is identical in both cases: `main → branch → implementation → PR` (see `git-flow.md`). The PR always goes to GitHub. The only thing that changes is where the issue is read from / written to. Epics behave the same way across trackers too — same integration branch and `/finish-epic` flow (see `workflow/epics.md`); only how the parent/child link is stored differs (label + sub-issue on GitHub, Epic type + Epic Link on Jira).
