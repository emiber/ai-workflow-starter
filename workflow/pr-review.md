# PR review

Guide for `/review-pr <n>`. Reviews an open PR against its linked issue's acceptance criteria and the Definition of Done from `workflow/git-flow.md`. The output is a structured report with **blockers** (must fix before merge) and **suggestions** (improvements worth considering).

This is a **read-only command**: it never commits, pushes, or modifies files.

## Before starting: resolve the tracker

Determine whether the project uses GitHub or Jira following `workflow/issue-tracker.md` (check `.workflow-config`). The issue is fetched from the configured tracker; the PR is always on GitHub.

## Preflight

Run these before anything else. They are read-only — if one fails, stop and report.

| Check | How | If it fails |
|---|---|---|
| `gh` authenticated | `gh auth status` | `gh auth login` |
| PR exists and is open | `gh pr view <n> --json state` | Report status and stop — if merged/closed, there is nothing to review. |

## Steps

### 1. Fetch the PR

```bash
gh pr view <n> --json number,title,body,baseRefName,headRefName,state,additions,deletions,changedFiles,author
```

Note the base branch — it should be `main` or an epic integration branch (`epic/<epicN>-<slug>`).

### 2. Find and fetch the linked issue(s)

Resolve the linked issue **deterministically** — don't bind the review to the first `#<n>` you happen to see.

- **GitHub**: prefer the references GitHub itself parsed from the PR's closing keywords:
  ```bash
  gh pr view <n> --json closingIssuesReferences --jq '.closingIssuesReferences[].number'
  ```
  This is authoritative for a PR into the default branch that uses a closing keyword (`Closes`/`Fixes`/`Resolves #<n>`). If it returns nothing — the normal case for an **epic child PR** (non-default base, references its issue with `Refs`) or any link-only PR — fall back to scanning the PR body for **keyworded references only**: `Closes`/`Fixes`/`Resolves #<n>` and `Refs #<n>`. Collect **every** match; a PR may legitimately link more than one issue. A **bare `#<n>` with no keyword is not an authoritative link** — treat it at most as "possibly related", never as the reviewed issue. Fetch each resolved issue with:
  ```bash
  gh issue view <issueN> --json title,body,labels,comments
  ```
- **Jira**: look for a Jira key in the title or body (e.g. `[ABC-123]`). Fetch with:
  ```bash
  jira issue view <KEY>
  ```

Review the diff against **every** resolved issue. If none is found — no closing reference, no explicit `Refs`, no Jira key — add it as a blocker: a PR without a linked issue is untrackable (a bare `#<n>` mention alone doesn't count).

### 3. Fetch the diff

```bash
gh pr diff <n>
```

Read all changed files and understand what the PR actually does.

### 4. Check the Definition of Done

Go through each item from `workflow/git-flow.md`. Mark each as **pass**, **fail** (blocker), or **warn** (unverifiable from diff alone).

| Item | How to check |
|---|---|
| Acceptance criteria met | Compare the diff against each AC in every linked issue (see step 2); verify each one has corresponding code or is not applicable. Missing coverage of an AC is a blocker. |
| Tests exist for new components | For each new non-trivial file, look for a corresponding test file. A new component with no tests is a blocker. |
| No secrets committed | Scan the diff for hardcoded credentials, tokens, API keys, or private keys. Any hit is a blocker. |
| Docs updated if needed | If behavior, setup, or public interface changed, check that `README` / `docs/ARCHITECTURE.md` / inline docs were updated in the same PR. |
| Target branch is correct | Standalone issue → `main`. Child of an epic → `epic/<epicN>-<slug>`. A wrong base branch is a blocker. |
| Linter and tests pass | Not verifiable from the diff alone — flag as **warn** and note that the author should confirm locally before requesting review. Escalate to blocker if there are obvious syntax or style violations in the diff. |
| Coverage meets threshold | Not verifiable from the diff alone — flag as **warn** if new code paths have no visible tests. |

### 5. Report

Output a structured review with the following sections:

#### Blockers

Issues that must be resolved before the PR can be merged. Numbered list. For each item:
- What the problem is
- Where it is (file + line when applicable)
- What to do to fix it

If there are no blockers, write: **No blockers found.**

#### Suggestions

Improvements worth considering but not required for merge. Same format as blockers. Omit this section entirely if there are none.

#### Summary

One short paragraph: overall assessment, whether any blockers were found, what remains unverifiable from the diff alone, and the recommended next validation step. Do not state that the PR is "ready to merge" or recommend merging — that decision belongs to the human reviewer (see Hard rules).

## Output conventions

- Reference files with path and line number when possible.
- Be specific: "`src/auth.ts:42` hardcodes an API token" beats "possible secret found".
- Group issues that trace to the same root cause instead of listing them separately.
- Keep suggestions actionable. "Extract this into a helper to avoid duplication with `src/utils.ts:18`" is useful; "this code looks complex" is not.

## Hard rules

- Never commit, push, or modify files — this command is strictly read-only.
- Never auto-approve or recommend merging. Leave that decision to the human reviewer.
- If the PR is already merged or closed, stop immediately and report without further analysis.
