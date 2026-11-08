# PR review

Guide for `/review-pr <n>`. Reviews an open PR against its linked issue(s)' acceptance criteria and the Definition of Done from `workflow/git-flow.md`. The output is a structured report with **blockers** (must fix before merge) and **suggestions** (improvements worth considering).

This is a **read-only command**: it never commits, pushes, or modifies files.

The same contract runs in two modes: against an **open PR** (`/review-pr <n>`, steps below) and in **local diff mode**, the self-review `/work-issue` runs before a PR exists (`workflow/git-flow.md` step 5).

## Local diff mode (self-review before the PR)

Same checks, different inputs. You're given an issue number and a base branch:

- **Skip** the Preflight's PR check and step 1's PR fetch. The PR shape is known from the branches: base `main` → standalone, a base starting with `epic/<parentN>-` (`<parentN>` is the issue's parent epic, whatever the slug) → epic child, and an epic branch (`epic/<epicN>-…`) reviewed against `main` → epic integration (see **Epic integration** below).
- **Linked issue** = the issue you were given, in the repository `/work-issue` is working in, which stands in for the PR's repository (step 1): `gh repo view --json url --jq .url` prints `https://<host>/<owner>/<repo>`, and the issue's URL is that plus `/issues/<n>`. Fetch it with step 2's commands.
- **Diff** = the committed change from `<base>` to `HEAD`, three-dot (from their merge base, like `git diff <base>...HEAD`), read as a **local snapshot**. Resolve both to full SHAs once, then use only those SHAs and only objects already in the repository:
  ```bash
  GIT_NO_LAZY_FETCH=1 git rev-parse --verify "<base>^{commit}"
  GIT_NO_LAZY_FETCH=1 git rev-parse --verify "HEAD^{commit}"
  GIT_NO_LAZY_FETCH=1 git merge-base <BASE_SHA> <HEAD_SHA>
  GIT_NO_LAZY_FETCH=1 git diff --no-ext-diff --no-textconv -M --name-status <MERGE_BASE_SHA> <HEAD_SHA>
  GIT_NO_LAZY_FETCH=1 git diff --no-ext-diff --no-textconv -M <MERGE_BASE_SHA> <HEAD_SHA>
  GIT_NO_LAZY_FETCH=1 git show --no-textconv "<HEAD_SHA>:<path>"
  ```
  The first three print `<BASE_SHA>`, `<HEAD_SHA>` and `<MERGE_BASE_SHA>`. Read each changed file in full with `git show`, never from disk: uncommitted changes aren't part of the snapshot. Pick paths by status, and apply the coverage limits, as in step 3: new paths at `<HEAD_SHA>`, old paths (a `D` file, the first path of an `R` line) at `<MERGE_BASE_SHA>`. `--no-ext-diff` and `--no-textconv` keep Git from running configured diff or text-conversion programs. Never fetch or pull: with `GIT_NO_LAZY_FETCH=1` (Git 2.44 or later), a partial clone reports a missing object instead of downloading it. If a revision or object is missing, stop and report it. There's no PR to recheck in step 5.
- **Skip** the Definition of Done rows that need an open PR (target branch, Verification section) — they're checked once the PR exists.
- **Output** the same report (Snapshot, Intent, Blockers, Suggestions, Summary). Still read-only: report, don't fix.
- **Epic integration** — the final-revision review `/finish-epic` runs before it pushes (`workflow/epics.md` step 4), so there's no PR yet. The linked issues are the epic and the children you were given, each fetched as above. `<base>` is `origin/main`, as given, never a local `main` (`/finish-epic` doesn't update it, so it may be stale). `<HEAD_SHA>` must be the candidate SHA you were given: if it isn't, stop and report it. Besides the Diff above, read the merge context you were given under the same local snapshot rules: resolve `origin/epic/<n>-<slug>` and `<merge>` to full SHAs (`<EPIC_SHA>`, `<MERGE_SHA>`) with `GIT_NO_LAZY_FETCH=1 git rev-parse --verify "<ref>^{commit}"`, then run `GIT_NO_LAZY_FETCH=1 git diff --no-ext-diff --no-textconv <EPIC_SHA> <HEAD_SHA>` and, if there's a merge commit, `GIT_NO_LAZY_FETCH=1 git show --no-ext-diff --no-textconv --cc <MERGE_SHA>`. Read each conflicted file you were given in full at `<HEAD_SHA>` (`GIT_NO_LAZY_FETCH=1 git show --no-textconv "<HEAD_SHA>:<path>"`): a resolution that keeps one side shows nothing in `--cc`. Review the conflict resolutions, the integration fixes, and how what `main` brought in meets the epic's changes, against the acceptance criteria of the epic and of the children they affect; don't re-review unchanged child work.

## Before starting: resolve the tracker

Determine whether the project uses GitHub or Jira following `workflow/issue-tracker.md` (check `.workflow-config`). The issue is fetched from the configured tracker; the PR is always on GitHub.

## Preflight

Run these before anything else. They are read-only — if one fails, stop and report.

| Check | How | If it fails |
|---|---|---|
| `gh` authenticated | `gh auth status` | `gh auth login` |
| `gh` supports `parent` (≥ 2.94) | `gh --version` (compare to 2.94.0) | Upgrade `gh`; or on older `gh` / GitHub Enterprise Server, read the linked issue's parent via the REST fallback in `workflow/issue-tracker.md`, addressed by the issue's own host and repository as in step 2. Step 2 uses `parent` to classify the PR against its base branch. |
| PR exists and is open | `gh pr view <n> --json state` | Report status and stop — if merged/closed, there is nothing to review. |

## Steps

### 1. Fetch the PR

```bash
gh pr view <n> --json number,url,title,body,baseRefName,headRefName,state,additions,deletions,changedFiles,author
```

The PR's `url` (`https://<host>/<owner>/<repo>/pull/<n>`) fixes **the PR's repository**: that host and `<owner>/<repo>`, the base repository the PR was opened in. Its issue URLs start with `https://<host>/<owner>/<repo>/issues/`. Take it from this `url` only — never from the local checkout, and, for a fork PR, never from the head (fork) repository. Step 2 addresses the PR by this URL, written `<pr-url>`.

**Pin the snapshot.** The whole review reads one fixed revision of the PR, its **snapshot**. Take `<PR_HOST>` (the host) and `<PR_REPO>` (`<owner>/<repo>`) from that `url`, and read the PR once more through the REST API. Send the request to that host, with an explicit GET, never to a host or repository inferred from the local checkout:
```bash
gh api --hostname <PR_HOST> --method GET "repos/<PR_REPO>/pulls/<n>" --jq '{state, base_repo: .base.repo.full_name, base_ref: .base.ref, base_sha: .base.sha, head_repo: .head.repo.full_name, head_ref: .head.ref, head_sha: .head.sha, changed_files}'
```
This one response is the snapshot: `<BASE_REPO>` and `<HEAD_REPO>` (each `owner/repo`; for a fork PR, `<HEAD_REPO>` is the fork), the base and head branches, `<BASE_SHA>` and `<HEAD_SHA>` (full SHAs, never shortened), and the number of changed files. From here on its values are the PR's: classify the PR by its branches, and read the diff and files at its SHAs (step 3). If `state` isn't `open`, stop, as in the Preflight. If `head_repo` is null, the head repository (usually a deleted fork) is gone: stop and report that the head revision can't be read.

**Classify the PR** from its head/base branches (and the linked issues' `parent`, from step 2). There are three valid shapes:

- **Standalone** — feature branch → `main`; the linked issue has no epic parent (no `parent`, or a parent that isn't an epic; see **Epic parent** below); closed with `Closes`.
- **Epic child** — feature branch → a base starting with `epic/<parentN>-`, where `<parentN>` is the linked issue's `parent` (whatever the slug) and that parent is an epic (see **Epic parent** below); referenced with `Refs`.
- **Epic integration** — head starting with `epic/<epicN>-` (whatever the slug) → base `main`; opened by `/finish-epic`. Its linked issues are the epic itself **plus** its children — the one explicit exception to "one PR = one issue" (see `workflow/epics.md`). Its child issues are correctly targeted here; do **not** flag them as mis-based.

**Epic parent.** For a feature-branch PR, the linked issue's parent decides between **Epic child** and **Standalone**: only a parent that is an epic makes it an epic child (the check is in step 2), and on GitHub only if the issue and its parent are both in the PR's repository (step 1). Any other parent makes the PR **Standalone** — except, on GitHub, a parent where the issue or the parent is outside the PR's repository, or one that can't be identified: **Repository boundary** below covers those. Don't ask — this review only reports: add a suggestion that names the parent (e.g. "<issue url>'s parent <parent url> isn't labeled `epic`; if it's meant to be an epic, label it and review again"), so a real epic that's missing its `epic` label doesn't go unnoticed. The **Epic integration** shape doesn't use this rule: it's classified by its `epic/<epicN>-*` → `main` branches, not by `parent`.

**Repository boundary (GitHub).** Branch names map only to issues in the PR's repository: `<parentN>` and `<epicN>` above are issue numbers there, and the shapes above classify only issues and parents there. A linked issue from another repository with no parent (`parent` null from a successful fetch) is a standalone issue of that repository: review it against its own ACs, but its number never maps to an `epic/<N>-*` branch. Any other relationship that leaves the PR's repository or can't be established doesn't classify the PR: a parent in another repository or on another host, any parent of an issue from another repository, or an **unknown** parent (step 2). Its number is never matched to an `epic/<N>-*` branch here (a parent `b/lib#7` says nothing about this repository's `epic/7-…`). Set the **Target branch** row (step 4) to **warn**, naming the issue and its parent by URL, and ask for manual validation of the base. Don't mark it pass, and don't turn it into a wrong-base blocker. Still review the issue's ACs.

Anything that fits none of these (e.g. a child branch pointing at `main`, or a mixed set of unrelated issues) → flag for manual validation.

### 2. Find and fetch the linked issue(s)

Resolve the linked issue **deterministically** — don't bind the review to the first `#<n>` you happen to see.

- **GitHub**: carry every issue as its **full identity** — host, owner, repository and number — in the form of its URL, `https://<host>/<owner>/<repo>/issues/<number>`. Never fetch, deduplicate, or report an issue by a bare number: issue 42 in another repository, or on another host, is a different issue.

  **Structured references first.** Read the references GitHub itself parsed from the PR's closing keywords, addressing the PR by its URL (step 1):
  ```bash
  gh pr view <pr-url> --json closingIssuesReferences --jq '.closingIssuesReferences[].url'
  ```
  If the command exits non-zero, stop and report the error: a failed query isn't an empty result and never triggers the fallback. If it prints any line, those references are the linked issues. They're authoritative and never merged with references from the body. Each line must be an accepted issue URL (see **Accepted references** below). A `null`, empty, or other line is a malformed reference (see **Unresolved references** below): never drop it, and never fall back because of it.

  **Keyword fallback, only after a successful empty result** — the normal case for an **epic child PR** (non-default base, references its issue with `Refs`) or any link-only PR. Scan the PR body for **keyworded references only**: a reference right after `Closes`, `Fixes`, `Resolves` or `Refs`, in any case, with or without a colon (`refs: #42`). `Refs` is this workflow's convention, not a GitHub closing keyword. Collect **every** match, because a PR may legitimately link more than one issue. Each reference needs its own keyword (`Closes #1, #2` links only #1). A reference takes one of three forms:
  - `#42` → issue 42 in the PR's repository. For a fork PR, that's the base repository, never the fork: `Refs #42` in a PR from `alice/app` into `org/app` links `org/app#42`.
  - `owner/repo#42` → issue 42 in `owner/repo`, on the PR's host.
  - `https://<host>/<owner>/<repo>/issues/42` → exactly that issue.

  A reference with no keyword — a bare `#<n>`, `owner/repo#<n>` or issue URL — **is not an authoritative link**: treat it at most as "possibly related", never as a reviewed issue.

  **Accepted references.** An issue URL is accepted only if all of these hold:
  - it has the form `https://<host>/<owner>/<repo>/issues/<number>` with a positive number, optionally followed by `/` or a `#fragment` (both dropped);
  - it has no credentials (`user:password@`) in it;
  - its host is the PR's host, or another host that `gh auth status` lists as logged in.

  Compare host, owner and repository case-insensitively. References with the same identity are one issue, fetched and reviewed once: in a PR in `github.com/a/app`, `#42`, `A/App#42` and `https://github.com/a/app/issues/42#issuecomment-1` all mean `https://github.com/a/app/issues/42`. Different repositories or hosts never collapse by number. In that PR, `Closes b/lib#42` links only `https://github.com/b/lib/issues/42`, never `a/app`'s issue 42. `Closes #42` together with `Closes b/lib#42` links two issues, each reviewed against its own ACs.

  **Fetch each issue by its URL** (or by its number with an explicit `--repo <host>/<owner>/<repo>`):
  ```bash
  gh issue view <issue-url> --json number,url,title,body,labels,comments,parent
  ```
  `gh issue view` returns no `repository` field, so check that the returned `url` has the identity you asked for. If it doesn't (for example, the issue was transferred), the reference is unresolved: don't review the returned issue in its place.
  The `parent` field (`gh` ≥ 2.94; see `workflow/issue-tracker.md`) is `{id, number, state, title, url}` or null, with no labels. Null from a successful fetch means no parent; a parent that can't be read is **unknown**, never null. A non-null parent is an **epic parent** only if the issue and the parent are both in the PR's repository (`.url` and `.parent.url` both start with the PR's `https://<host>/<owner>/<repo>/issues/` prefix, compared case-insensitively) and its labels, read by the parent's URL (never by bare number), include `epic`; check the repository first, and read labels only for a same-repository parent of a feature-branch PR:
  ```bash
  gh issue view <parent url> --json labels
  ```
  On older `gh` or GitHub Enterprise Server, read the issue through the REST fallback by its own identity, with `gh api --hostname <host> "repos/<owner>/<repo>/issues/<number>"`. Never use the `{owner}/{repo}` placeholders of `workflow/issue-tracker.md` here: they name the current repository. The REST payload has `parent_issue_url`, an API URL (`https://api.github.com/repos/<owner>/<repo>/issues/<parentN>`): check that its `repos/<owner>/<repo>/` is the PR's repository, on the PR's host, then read the labels with `gh api "<parent_issue_url>" --jq '[.labels[].name]'`. This decides, in step 1, between Epic child, Standalone, and a parent past the **Repository boundary**, which the target-branch check in step 4 relies on.

  **Unresolved references.** A reference is unresolved when:
  - it's malformed, including a structured line that isn't an accepted URL;
  - its host isn't accepted;
  - its issue can't be fetched (no access, not found, or any other error);
  - the fetch returns a different identity.

  Never retry it by number in the PR's repository, never skip it, never send it to a host that isn't accepted, and don't change `gh` authentication to reach it. Add a blocker that names it exactly: as written, with any `user:password@` part redacted, or by its position in `closingIssuesReferences` if it has no URL. Give the reason and what's needed: read access, a corrected reference, or a manual check of that issue's ACs. For example: "`Closes b/lib#42` → `https://github.com/b/lib/issues/42`: `gh issue view` failed (no access); grant read access or validate its ACs manually". Review the other issues as usual, but never report the ACs as verified while a reference is unresolved.
- **Jira**: look for a Jira key in the title or body (e.g. `[ABC-123]`). Fetch with:
  ```bash
  jira issue view <KEY>
  ```
  Its parent is an **epic parent** only if the parent's issue type is Epic; a sub-task's parent (a Story, a Task, …) is not.

If a parent lookup fails, or the parent's repository, labels, or type can't be read, don't guess, and don't treat it as no parent. On GitHub, the parent is **unknown** (see **Repository boundary** in step 1): report it and still review the issue's ACs. On Jira, stop and report.

Review the diff against **every** resolved issue. If none is found — no closing reference, no explicit `Refs`, no Jira key — add it as a blocker: a PR without a linked issue is untrackable (a bare `#<n>` mention alone doesn't count).

### 3. Fetch the diff

Read the diff, and every repository file you read to review the change (the changed files and the helpers or tests around them), from the snapshot (step 1). The workflow guides and `.workflow-config` are the exception: read them from the checkout. Never read the reviewed files from the local checkout, not even when your local `HEAD` is `<HEAD_SHA>`: the working tree can hold uncommitted edits. Don't use `gh pr diff <n>` either: it shows the PR's branches as they are now, not the snapshot. Use only the read-only requests below, all sent to `<PR_HOST>` with `--method GET` (without it, `gh api` sends a POST as soon as a field such as `-f` is given). Fill in the full SHAs from the snapshot, and `<BASE_OWNER>` and `<HEAD_OWNER>`, the owners in `<BASE_REPO>` and `<HEAD_REPO>`. Quote every endpoint. Keep each response in the command output; never redirect it into a file.

1. **Merge base.** A PR's diff is three-dot: from the merge base of its base and head, to its head. A fork PR uses the same requests, because a fork shares its base repository's network.
   ```bash
   gh api --hostname <PR_HOST> --method GET "repos/<BASE_REPO>/compare/<BASE_OWNER>:<BASE_SHA>...<HEAD_OWNER>:<HEAD_SHA>" --jq '.merge_base_commit.sha'
   ```
   It prints `<MERGE_BASE_SHA>`.
2. **File inventory and diff**, from `<MERGE_BASE_SHA>` to `<HEAD_SHA>`:
   ```bash
   gh api --hostname <PR_HOST> --method GET "repos/<BASE_REPO>/compare/<BASE_OWNER>:<MERGE_BASE_SHA>...<HEAD_OWNER>:<HEAD_SHA>" --jq '.files[] | {status, filename, previous_filename}'
   gh api --hostname <PR_HOST> --method GET "repos/<BASE_REPO>/compare/<BASE_OWNER>:<MERGE_BASE_SHA>...<HEAD_OWNER>:<HEAD_SHA>" -H "Accept: application/vnd.github.diff"
   ```
   The first prints one line per changed file; their number must equal the snapshot's `changed_files`. The second prints the diff.
3. **Full files.** Read every changed text file in full, not only its hunks, plus any unchanged file you need to understand it (a helper it calls, a test that should exist):
   ```bash
   gh api --hostname <PR_HOST> --method GET "repos/<SOURCE_REPO>/contents/<ENCODED_PATH>" -f "ref=<COMMIT_SHA>" -H "Accept: application/vnd.github.raw+json"
   ```
   - **New side:** `<SOURCE_REPO>` is `<HEAD_REPO>` and `<COMMIT_SHA>` is `<HEAD_SHA>`. For a fork PR, that's the fork. Unchanged files are read here too.
   - **Old side:** `<SOURCE_REPO>` is `<BASE_REPO>` and `<COMMIT_SHA>` is `<MERGE_BASE_SHA>`, never `<BASE_SHA>`: if the base moved on after the PR branched off, its tip has changes the PR didn't make.
   - **`<ENCODED_PATH>`:** percent-encode each path segment, every character except ASCII letters, digits, `-`, `.`, `_` and `~`, and keep the `/` between segments: `src/a b#1.ts` → `src/a%20b%231.ts`. This also keeps a file name from the PR from being read as shell syntax.

   Which paths to read depends on each file's `status` in the inventory:
   - `added`: `filename` at head. There's no old file.
   - `modified` (or `changed`): `filename` at head, and at the merge base when you need the old context.
   - `renamed` (or `copied`): `filename` at head, `previous_filename` at the merge base. A rename that the inventory shows as `removed` plus `added` is read as those two.
   - `removed`: `filename` at the merge base only. Don't request it at head: it's meant to be gone.

**Coverage limits.** Stop reading and report an **incomplete** review (see **Snapshot** in step 5) when:
- a request fails: no access, not found, a revision that isn't available, a rate limit or network error, or a file or diff too large for the API. A 404 doesn't prove that a file was deleted; only `removed` in the inventory does;
- the inventory lists 300 files, the compare API's cap (paging through commits doesn't lift it), or its count differs from `changed_files`;
- the diff, or a file you need, is missing or cut short. A changed file with no hunk in the diff isn't proof that its content didn't change.

Name the repository, SHA, and path or request involved, and what couldn't be verified. Don't retry in a loop, don't change `gh` authentication, and never fall back to local files or to the PR's current branches. Binary files, symlinks and submodules can't be reviewed as text: name each one as a limitation and review the rest. Reading a symlink through the API returns its target's content, not the link itself. A coverage limit isn't a code defect: don't turn it into a blocker, but never call the review complete, or the PR clean, while one stands.

With the diff and the files from the snapshot, understand what the PR actually does.

Then write the **PR intent** in one line: what the change is for and what it deliberately leaves alone (take it from the linked issue's Scope). It's the ruler for every scope call below: a real defect *inside* the intent can block; a valid concern *outside* it is a suggestion or a follow-up, never a reason to expand the PR.

### 4. Check the Definition of Done

Go through each item from `workflow/git-flow.md`. Mark each as **pass**, **fail** (blocker), or **warn** (unverifiable from diff alone).

| Item | How to check |
|---|---|
| Acceptance criteria met | Compare the diff against each AC in every linked issue (see step 2); verify each one has corresponding code or is not applicable. Missing coverage of an AC is a blocker. Report each issue's result by its URL. An unresolved reference (step 2) makes this row **fail**, never pass. |
| Tests exist for new components | For each new non-trivial file, look for a corresponding test file. A new component with no tests is a blocker. |
| Security checklist | Apply the [Security checklist](#security-checklist) below. Any blocker it lists — including a committed secret — is a blocker. |
| Docs updated if needed | If behavior, setup, or public interface changed, check that `README` / `docs/ARCHITECTURE.md` / inline docs were updated in the same PR. |
| Target branch is correct | Check against the PR type from step 1: **standalone** → base `main`; **epic child** → a base starting with `epic/<parentN>-`, where `<parentN>` is the linked issue's `parent`; **epic integration** (`epic/** → main`) → base `main` is correct and its child issues are **not** mis-targeted. A base that doesn't match the PR's type is a blocker. A linked issue past the **Repository boundary** (step 1) → **warn**, naming it and its parent by URL, with manual validation of the base: never pass, and never a wrong-base blocker on that account. |
| Linter and tests pass | Not verifiable from the diff alone — flag as **warn** and note that the author should confirm locally before requesting review. Escalate to blocker if there are obvious syntax or style violations in the diff. |
| Coverage meets threshold | Not verifiable from the diff alone — flag as **warn** if new code paths have no visible tests, or if Verification lists new/changed files below the threshold without a reason. |
| Verification reported | The PR body has a **Verification** section with a line for every gate in `workflow/git-flow.md` (lint, tests, coverage, self-review, security, docs), each pass or `n/a` with a reason, plus an **Out of scope / follow-ups** section. Missing section or missing gates → **warn**. A gate reported as passed that the diff contradicts (e.g. "tests: pass" with a test file deleted) → blocker. An epic integration PR reports it too, for the revision `/finish-epic` validated (`workflow/epics.md` step 5); links to its children's PRs don't replace it. |

Plan approval and the self-review leave no trace in the diff; the Verification section's self-review line is the only evidence of the latter — don't mark either as pass or fail on your own.

#### Security checklist

Applies to every review. First decide whether the diff touches a **security surface**: entry points (HTTP routes, handlers, CLI arguments, message consumers), authentication or permissions, data access, file handling, outbound calls, configuration or secrets, logging of user data. If it touches none, write one line — "Security: no security surface touched" — and move on; don't invent findings.

Otherwise, check each area. These are **blockers**:

| Area | Blocker when |
|---|---|
| Authorization | A new or changed entry point that reads or changes data has no server-side authorization check, or relies only on the client/UI to hide it. |
| Secrets | A credential, token, API key, private key, or connection string appears in code, config, tests, fixtures, or the PR text. |
| Input | Input from outside the process isn't validated at the boundary, or a query or shell command is built by concatenating that input instead of using parameters. |
| Data exposure | Responses, errors, or logs expose internals (stack traces, tokens, connection strings) or personal data beyond what the feature needs, or return whole internal records where a narrower shape is expected. |

Other concerns — an outbound call without a timeout, an unverified incoming webhook, a new dependency with a doubtful track record — are **suggestions**, unless they open a concrete exploit path; then they're blockers. For each finding give the file and line, the risk in one line, and the fix.

### 5. Report

**Recheck the snapshot first.** Run step 1's snapshot request again and compare the result with the snapshot. If `state` isn't `open`, or a repository, branch or SHA changed (a push or force-push to the head, a new commit on the base, a retargeted base), stop. Instead of the report below, report the captured snapshot and the current one, and say that the PR needs a fresh review. Don't present your findings as a review of the current PR, and don't start over on your own. If the recheck request fails, stop the same way and say the review couldn't be confirmed current. A match confirms that the snapshot was current when you checked, not that it will stay so.

Output a structured review with the following sections:

#### Snapshot

What was reviewed: the PR's URL; the base (`<BASE_REPO>`, its branch, `<BASE_SHA>`), the head (`<HEAD_REPO>`, its branch, `<HEAD_SHA>`) and `<MERGE_BASE_SHA>`, all as full SHAs. In local diff mode, it's a **local snapshot**: the base name with `<BASE_SHA>`, `<HEAD_SHA>` and `<MERGE_BASE_SHA>`, committed changes only. Then the coverage: **complete**, or **incomplete**, listing each limit from step 3 (repository, SHA, path, and what couldn't be verified).

#### Intent

The one-line PR intent from step 3.

#### Blockers

Issues that must be resolved before the PR can be merged. Numbered list. For each item:
- What the problem is
- Where it is (file + line when applicable)
- What to do to fix it

If there are no blockers, write: **No blockers found.**

#### Suggestions

Improvements worth considering but not required for merge. Same format as blockers. Omit this section entirely if there are none.

#### Summary

One short paragraph: overall assessment, whether any blockers were found, what remains unverifiable from the diff alone, and the recommended next validation step. If coverage is incomplete (see **Snapshot**), say so here, and don't describe the review as complete or the PR as clean. Do not state that the PR is "ready to merge" or recommend merging — that decision belongs to the human reviewer (see Hard rules).

## Output conventions

- Reference files with path and line number when possible, on the side they belong to: new or changed lines by their path at `<HEAD_SHA>`, removed or old lines by their merge-base path (`previous_filename` for a rename) at `<MERGE_BASE_SHA>`.
- Name each GitHub issue by its full URL (or `<host>/<owner>/<repo>#<n>`), never by a bare `#<n>`: in AC results, unresolved references, and parent findings alike.
- Be specific: "`src/auth.ts:42` hardcodes an API token" beats "possible secret found".
- Group issues that trace to the same root cause instead of listing them separately.
- Keep suggestions actionable. "Extract this into a helper to avoid duplication with `src/utils.ts:18`" is useful; "this code looks complex" is not.

## Hard rules

- Never commit, push, or modify files — this command is strictly read-only.
- Every read of the PR's code and diff is a read-only `gh` or `git` command. Other reads (the tracker, such as `jira issue view`, and the workflow guides and `.workflow-config` in the checkout) stay read-only too. Never check out, fetch, pull or clone the PR, add a worktree, write downloaded content to a file, run the PR's code or tests, change `gh` authentication, or write to GitHub.
- Never auto-approve or recommend merging. Leave that decision to the human reviewer.
- If the PR is already merged or closed, stop immediately and report without further analysis.
