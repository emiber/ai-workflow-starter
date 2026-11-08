# Issue refinement

Guide for `/refine-issue <n>`. The goal: take a raw issue and make it clear enough to implement without guessing.

## Before starting: resolve the tracker

Determine whether the project uses GitHub or Jira following `workflow/issue-tracker.md` (check `.workflow-config`; it ships preset to GitHub). Make sure the tracker CLI is authenticated first — `gh auth status` for GitHub, `jira me` for Jira. The concrete commands below depend on that.

## Steps

### 1. Fetch the issue

- **GitHub**: `gh issue view <n> --json title,body,labels,comments`
- **Jira**: `jira issue view <KEY>`

If it doesn't exist, say so and offer to create it with `/create-issue` (see `workflow/issue-creation.md`), or directly with `gh issue create` / `jira --project ABC issue create --no-input --type <Type> --summary '<title>' --template <file>` (`ABC` being `jira_project`; see **Project selection** in `workflow/issue-tracker.md`).

### 2. Detect ambiguities

Read the issue and list everything that isn't clear. Categories to check:

- **Goal**: what problem does it solve? For whom?
- **Scope**: what's in and what's NOT in this issue?
- **Expected behavior**: normal, edge, and error cases.
- **Data**: what comes in, what goes out, what's persisted?
- **Dependencies**: does it block or depend on other issues?
- **Acceptance criteria**: how do we know it's done?
- **Non-functional**: performance, security, limits, permissions.

### 3. Ask

Ask the user **all** the questions needed to close those ambiguities. In small groups. Don't proceed on unconfirmed assumptions. If the user answers "use your judgment", propose a concrete decision and confirm it. Record any such confirmed judgment call in the issue's **Assumptions** section (see `docs/ISSUE_TEMPLATE.md`) so what the user originally stated remains separate from what you inferred and they confirmed. Also reflect each decision's effects in the relevant **Scope**, **Expected behavior**, **Data**, or **Acceptance criteria** section; **Assumptions** records provenance, not a substitute for implementable requirements.

Apply Ponytail: don't inflate the scope. If the issue asks for something small, keep it small. Detect and flag over-engineering in the original request.

### 4. Show the draft, get approval, then write

Draft the refined issue with the structure in `docs/ISSUE_TEMPLATE.md`. Nothing is written to the tracker until the user approves the draft (or approved publishing in advance, below):

1. **Show** the complete refined body, not a summary, and say what will mark it refined: the `refined` label on GitHub; the refinement comment, and any label or status the project uses, on Jira.
2. **Wait for explicit approval** ("ok", "go ahead", "approved", …). A question or a vague comment is not approval: answer it and ask again. If the user asks for changes, apply them, show the revised body, and wait again. If the user declines or aborts, write nothing, say the issue is unchanged, and stop.
3. **Re-fetch** the issue with the step 1 command right before writing. If the body changed or new comments arrived since you last read it, show what changed, revise the draft, show it again, and go back to 2. Never overwrite from a stale copy.

Only then write the body and mark the issue refined:

- **GitHub**: `gh issue edit <n> --body-file <file>` and add the `refined` label with `gh issue edit <n> --add-label "refined"`. If that fails because `refined` doesn't exist, follow **Workflow labels** in `workflow/issue-tracker.md`.
- **Jira**: `jira issue edit <KEY>` with the refined body, and leave a comment noting it was refined (`jira issue comment add <KEY>`). If the project uses a label/status for this, apply it.

**Approval given in advance.** If the user's request explicitly says to publish without review (e.g. "refine and publish these, don't ask me"), that is the approval: skip 1 and 2. It covers only the issue as you read it, so the re-fetch (3) still applies: if the issue changed, stop, show what changed and the revised draft, and wait for explicit approval; if it didn't, write without asking. Before writing, record the decisions you made yourself in the draft, under **Assumptions**, as "delegated, not confirmed". Silence or "I'm away" is not approval.

### 5. Output

Confirm that the issue was written and marked refined, and give its URL (GitHub) or key (Jira). If it was published on approval given in advance, say that it was published unreviewed. Suggest running `/work-issue <n>` when they want to implement it.

## When NOT to refine so much

For a typo fix or a one-line change, the full ritual isn't needed. Say so, confirm the scope in one sentence, and continue. That skips the questions, not step 4: any rewrite of the body is still shown and approved before it's written. The phase discipline (BMAD) is for real work, not for bureaucratizing trivial changes.
