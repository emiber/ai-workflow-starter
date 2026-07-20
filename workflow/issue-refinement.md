# Issue refinement

Guide for `/refine-issue <n>`. The goal: take a raw issue and make it clear enough to implement without guessing.

## Before starting: resolve the tracker

Determine whether the project uses GitHub or Jira following `workflow/issue-tracker.md` (check `.workflow-config`; it ships preset to GitHub). Make sure the tracker CLI is authenticated first — `gh auth status` for GitHub, `jira me` for Jira. The concrete commands below depend on that.

## Steps

### 1. Fetch the issue

- **GitHub**: `gh issue view <n> --json title,body,labels,comments`
- **Jira**: `jira issue view <KEY>`

If it doesn't exist, say so and offer to create it with `/create-issue` (see `workflow/issue-creation.md`), or directly with `gh issue create` / `jira issue create`.

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

Ask the user **all** the questions needed to close those ambiguities. In small groups. Don't proceed on assumptions. If the user answers "use your judgment", propose a concrete decision and confirm it.

Apply Ponytail: don't inflate the scope. If the issue asks for something small, keep it small. Detect and flag over-engineering in the original request.

### 4. Write the refined issue

Update the issue with the structure in `docs/ISSUE_TEMPLATE.md`:

- **GitHub**: `gh issue edit <n> --body-file <file>` and add the `refined` label with `gh issue edit <n> --add-label "refined"`.
- **Jira**: `jira issue edit <KEY>` with the refined body, and leave a comment noting it was refined (`jira issue comment add <KEY>`). If the project uses a label/status for this, apply it.

### 5. Output

Confirm to the user that the issue is refined and show them the result. Suggest running `/work-issue <n>` when they want to implement it.

## When NOT to refine so much

For a typo fix or a one-line change, the full ritual isn't needed. Say so, confirm the scope in one sentence, and continue. The phase discipline (BMAD) is for real work, not for bureaucratizing trivial changes.
