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

#### Workflow labels

The workflow applies two labels that GitHub doesn't ship by default: `epic` (`/create-issue`
for a new epic, and `/work-issue` when the user approves labeling a parent as an epic) and
`refined` (`/refine-issue`). This is the single place that lists them with the command to
create each one; every step that applies one points here.

```bash
gh label create epic --color 5319E7 --description "Parent issue grouping child issues (see workflow/epics.md)"
gh label create refined --color 0E8A16 --description "Issue has been refined and is ready to implement"
```

**If the label is missing — create and retry.** Apply the label with the step's usual
command; never check for it first. Only if that command fails with an error containing
`'<label>' not found`, where `<label>` is `epic` or `refined`:

1. Run that label's `gh label create` command above, as written. Never add `--force`: it
   overwrites the color and description of a label that already exists.
2. Retry the original command once (the failed one changed nothing: `gh` checks labels
   before it writes), and continue the flow.

If the original command fails for any other reason, stop and report as usual, and create
nothing. If `gh label create` fails (e.g. not enough permission on the repo) or the retry
fails, stop and report what's done and what's missing:

- `/refine-issue`: the refined body is written; `refined` isn't applied. If `refined` still
  doesn't exist, someone with write access runs its command above; then it can be added by
  hand with `gh issue edit <n> --add-label "refined"`.
- `/create-issue`: the issue wasn't created. If `epic` still doesn't exist, show its command
  above: someone with write access must run it before the user re-runs `/create-issue`.

### Jira

The commands below are those of **[`ankitpokhrel/jira-cli`](https://github.com/ankitpokhrel/jira-cli)** (the `jira` binary, v1.5+) — the specific CLI this workflow targets. Other tools also named `jira` have different command trees, so if you use a different one, map these operations to its equivalents. Install it (e.g. `brew install ankitpokhrel/jira-cli/jira-cli`, or a release binary from the repo), then run `jira init` to authenticate. `jira init` also asks for a default project: that's jira-cli's own setting, and the workflow doesn't rely on it (see **Project selection** below).

- View issue: `jira issue view <KEY>` (e.g. `jira issue view ABC-123`)
- Edit/comment: `jira issue edit <KEY>` / `jira issue comment add <KEY>`
- Create issue: `jira --project ABC issue create --no-input --type <Type> --summary '<title>' --template <file>`, with `ABC` standing for `jira_project` (see **Project selection** below)
- Reference in PR: include the key in the PR title/body (e.g. `[ABC-123] ...`). Jira does **not** close the issue automatically via the GitHub PR unless there's an integration configured; assume closing is done by a human or Jira automation, not the flow.
- Requires: `ankitpokhrel/jira-cli` installed and initialized via `jira init` (`jira me` to verify authentication).

> Note on key vs. number: on GitHub the issue is a number (`42`); on Jira it's a key (`ABC-123`). When the user passes the argument, take it as-is: if the tracker is Jira, expect a key; if GitHub, a number.

#### Project selection

`jira_project` in `.workflow-config` is the repository's project. It decides where every
project-scoped command the workflow runs goes: creating an issue (any type, including an
Epic or a child created with its parent), the duplicate search, and the candidate-epic
search (`workflow/issue-creation.md` steps 2, 3 and 5). jira-cli's default project, chosen
at `jira init`, never does, not even when it's the same key: pass the repository's key
anyway. Never edit `.workflow-config`, rerun `jira init`, or change jira-cli's config to
make the two agree.

**Read the key** once the tracker resolves to Jira, before the first of those commands:
it's the value after `jira_project=` on an uncommented line (the shipped
`# jira_project=ABC` is a comment and doesn't count).

- Missing, empty, or only whitespace → stop before any search or creation and report that
  `.workflow-config` needs `jira_project=<KEY>`. Don't take the key from jira-cli's
  default or from an issue key, and don't write it into the file yourself. A missing
  `issue_tracker` is a different case, handled as in **How it's resolved** above.
- Leading or trailing whitespace, a quote (`'`, `"`, or any of `‘ ’ ‚ ‛`, which PowerShell
  reads as single quotes), a backslash, or a control character → stop and ask the user to
  correct the value: it can't be passed as a literal key, and it's never trimmed or
  rewritten into another key. Don't test the value against
  a key pattern either: whether the project exists is Jira's call.

**Scope each command twice.** Pass the key with jira-cli's global `--project` (`-p`) on
every project-scoped command, and start every raw JQL query (`--jql`, `-q`) with the same
key as `project = "ABC"`, followed by `AND` and the rest of the query in parentheses. Both
are needed: `--project` alone doesn't confine a raw query, because jira-cli drops its
implicit project filter whenever the `--jql` text contains the word `project`. So
`jira --project ABC issue list --jql 'project = "XYZ"'` searches XYZ, not ABC. The
workflow's own queries never name a project other than the configured one. With
`jira_project=ABC`:

```text
jira --project ABC issue create --no-input --type Task --summary 'Example summary' --template <file>
jira --project ABC issue list --plain --jql 'project = "ABC" AND (summary ~ "<key words>" AND statusCategory != Done)'
jira --project ABC issue list --plain --jql 'project = "ABC" AND (issuetype = "Epic" AND statusCategory != Done)'
```

- Put the configured key in both places, the same in each. `Task` and `Epic` are example
  names: use the project's own issue types. Create's `--type`, `--summary` and
  `--template` are `-t`, `-s` and `-T`. `--no-input` stops jira-cli from prompting.
- `--plain` prints the list as text; without it, `issue list` opens an interactive table.
- Alternatives go inside the parentheses, never beside the project predicate:
  `project = "ABC" AND (summary ~ "login" OR summary ~ "timeout")`.
- The key, the keywords and the summary are data, never shell or JQL syntax. The whole
  `--jql` value is one quoted shell argument, and each value in it a JQL string in double
  quotes; the summary is one single-quoted argument. Prefer plain words as keywords.
  Inside a JQL string, write `"` as `\"` and `\` as `\\`; escape the shell's own quote for
  the shell in use (in the single-quoted examples: Bash `'\''`; PowerShell `''`, and also
  each of `‘`, `’`, `‚` and `‛`, which PowerShell reads as single quotes too: `’` → `’’`).
  Quote
  the `--project` value too if the shell would read any of its characters as syntax.
- The body is Markdown, so it never goes on the command line (backticks and `$(…)` run
  inside double quotes). Write it to a file with your file-write tool, outside the working
  tree, and pass the path to `--template`, like GitHub's `--body-file`.

**Read the result** by exit status and message:

- **Exit 0** → the rows printed are the visible matches (for a create, the new key).
- **Exit 1 with the message `No result found for given query in project "ABC"`** → the
  search ran and found nothing; jira-cli reports an empty result this way. Treat it as no
  match and follow the calling guide's no-match path, with its usual confirmations. It
  doesn't prove that the project exists or that you can see it, and it never widens the
  search to another project.
- **Anything else** (a project Jira reports as invalid, nonexistent or inaccessible;
  authentication; permissions; JQL; an unsupported issue type; CLI metadata that doesn't
  fit the project; network) → stop the flow. Report the operation, the project key and
  jira-cli's message, never a token or credentials. A failed search is never "no match",
  so don't go on to create. Don't retry without `--project`, fall back to jira-cli's
  default project, run `jira init`, or probe which projects exist.

**Complete issue keys keep their own project.** `jira issue view XYZ-123`,
`jira issue edit XYZ-123` and `jira issue comment add XYZ-123` act on exactly XYZ-123,
also when `jira_project` is ABC: don't rewrite the prefix or check it against
`jira_project`. These commands don't need `jira_project`, so a missing one stops only
searches and creation. Bare numbers stay invalid inputs (see the note on key vs. number
above).

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
