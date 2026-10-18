# PR review

Guide for `/review-pr <n>`. Reviews an open PR against its linked issue(s)' acceptance criteria and the Definition of Done from `workflow/git-flow.md`. The output is a structured report with **blockers** (must fix before merge) and **suggestions** (improvements worth considering).

This is a **read-only command**: it never commits, pushes, or modifies files.

The same contract runs in two modes: against an **open PR** (`/review-pr <n>`, steps below) and in **local diff mode**, the self-review `/work-issue` runs before a PR exists (`workflow/git-flow.md` step 5).

## Local diff mode (self-review before the PR)

Same checks, different inputs. You're given an issue number and a base branch:

- **Skip** the Preflight's PR check and step 1's PR fetch. The PR shape is known from the base: `main` → standalone, `epic/<epicN>-<slug>` → epic child.
- **Linked issue** = the issue you were given; fetch it with step 2's commands.
- **Diff** = `git diff <base>...HEAD`. Read the changed files in full, not only the hunks.
- **Skip** the Definition of Done rows that need an open PR (target branch, Verification section) — they're checked once the PR exists.
- **Output** the same report (Intent, Blockers, Suggestions, Summary). Still read-only: report, don't fix.

## Before starting: resolve the tracker

Determine whether the project uses GitHub or Jira following `workflow/issue-tracker.md` (check `.workflow-config`). The issue is fetched from the configured tracker; the PR is always on GitHub.

## Preflight

Run these before anything else. They are read-only — if one fails, stop and report.

| Check | How | If it fails |
|---|---|---|
| `gh` authenticated | `gh auth status` | `gh auth login` |
| `gh` supports `parent` (≥ 2.94) | `gh --version` (compare to 2.94.0) | Upgrade `gh`; or on older `gh` / GitHub Enterprise Server, read the linked issue's parent via the REST fallback in `workflow/issue-tracker.md`. Step 2 uses `parent` to classify the PR against its base branch. |
| PR exists and is open | `gh pr view <n> --json state` | Report status and stop — if merged/closed, there is nothing to review. |

## Steps

### 1. Fetch the PR

```bash
gh pr view <n> --json number,title,body,baseRefName,headRefName,state,additions,deletions,changedFiles,author
```

**Classify the PR** from its head/base branches (and the linked issues' `parent`, from step 2). There are three valid shapes:

- **Standalone** — feature branch → `main`; the linked issue has no `parent`; closed with `Closes`.
- **Epic child** — feature branch → `epic/<epicN>-<slug>`; the linked issue's `parent` is that epic; referenced with `Refs`.
- **Epic integration** — head `epic/<epicN>-<slug>` → base `main`; opened by `/finish-epic`. Its linked issues are the epic itself **plus** its children — the one explicit exception to "one PR = one issue" (see `workflow/epics.md`). Its child issues are correctly targeted here; do **not** flag them as mis-based.

Anything that fits none of these (e.g. a child branch pointing at `main`, or a mixed set of unrelated issues) → flag for manual validation.

### 2. Find and fetch the linked issue(s)

Resolve the linked issue **deterministically** — don't bind the review to the first `#<n>` you happen to see.

- **GitHub**: prefer the references GitHub itself parsed from the PR's closing keywords:
  ```bash
  gh pr view <n> --json closingIssuesReferences --jq '.closingIssuesReferences[].number'
  ```
  This is authoritative for a PR into the default branch that uses a closing keyword (`Closes`/`Fixes`/`Resolves #<n>`). If it returns nothing — the normal case for an **epic child PR** (non-default base, references its issue with `Refs`) or any link-only PR — fall back to scanning the PR body for **keyworded references only**: `Closes`/`Fixes`/`Resolves #<n>` and `Refs #<n>`. Collect **every** match; a PR may legitimately link more than one issue. A **bare `#<n>` with no keyword is not an authoritative link** — treat it at most as "possibly related", never as the reviewed issue. Fetch each resolved issue with:
  ```bash
  gh issue view <issueN> --json title,body,labels,comments,parent
  ```
  The `parent` field (`gh` ≥ 2.94; see `workflow/issue-tracker.md`) tells a child issue — part of an epic — from a standalone one, which the target-branch check in step 4 relies on.
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

Then write the **PR intent** in one line: what the change is for and what it deliberately leaves alone (take it from the linked issue's Scope). It's the ruler for every scope call below: a real defect *inside* the intent can block; a valid concern *outside* it is a suggestion or a follow-up, never a reason to expand the PR.

### 4. Check the Definition of Done

Go through each item from `workflow/git-flow.md`. Mark each as **pass**, **fail** (blocker), or **warn** (unverifiable from diff alone).

| Item | How to check |
|---|---|
| Acceptance criteria met | Compare the diff against each AC in every linked issue (see step 2); verify each one has corresponding code or is not applicable. Missing coverage of an AC is a blocker. |
| Tests exist for new components | For each new non-trivial file, look for a corresponding test file. A new component with no tests is a blocker. |
| Security checklist | Apply the [Security checklist](#security-checklist) below. Any blocker it lists — including a committed secret — is a blocker. |
| Docs updated if needed | If behavior, setup, or public interface changed, check that `README` / `docs/ARCHITECTURE.md` / inline docs were updated in the same PR. |
| Target branch is correct | Check against the PR type from step 1: **standalone** → base `main`; **epic child** → base `epic/<epicN>-<slug>`; **epic integration** (`epic/** → main`) → base `main` is correct and its child issues are **not** mis-targeted. A base that doesn't match the PR's type is a blocker. |
| Linter and tests pass | Not verifiable from the diff alone — flag as **warn** and note that the author should confirm locally before requesting review. Escalate to blocker if there are obvious syntax or style violations in the diff. |
| Coverage meets threshold | Not verifiable from the diff alone — flag as **warn** if new code paths have no visible tests, or if Verification lists new/changed files below the threshold without a reason. |
| Verification reported | The PR body has a **Verification** section with a line for every gate in `workflow/git-flow.md` (lint, tests, coverage, self-review, security, docs), each pass or `n/a` with a reason, plus an **Out of scope / follow-ups** section. Missing section or missing gates → **warn**. A gate reported as passed that the diff contradicts (e.g. "tests: pass" with a test file deleted) → blocker. Not applicable to an epic integration PR (its children carry it). |

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

Output a structured review with the following sections:

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
