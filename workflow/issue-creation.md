# Issue creation

Guide for `/create-issue`. The goal: turn a rough idea into a well-formed issue in
the tracker — clear enough that `/refine-issue` (or a human) can pick it up without
guessing what was meant.

This is **capture, not refinement**. Keep it light: a good title, a body that states
the problem and any known context, and the right tracker. Deep clarification (scope,
edge cases, acceptance criteria) is `/refine-issue`'s job — don't do it here unless
the user explicitly asks.

## Before starting: resolve the tracker

Determine whether the project uses GitHub or Jira following `workflow/issue-tracker.md`
(check `.workflow-config`; it ships preset to GitHub). Make sure the tracker CLI is
authenticated first — `gh auth status` for GitHub, `jira me` for Jira.

## Steps

### 1. Understand the request

Take the description the user gives (as the argument or in their message). If it's
empty, ask what the issue is about. Get just enough to write a clear title and a
short body:

- **What** — the problem, bug, or feature, in one line.
- **Why / context** — anything already known: where it happens, links, related issues.
- **Type** — bug, feature, chore, docs… (drives the title prefix / label if the
  project uses them).

Ask only what's missing — one or two questions, not the full refinement
interrogation. If the user gives a one-liner and says "just create it", create it.

### 2. Assess size and placement (epics)

Two quick checks before drafting. Both are **propose-and-confirm** — never decide the
structure silently, and never invent a parent. See `workflow/epics.md` for the how.

- **Is it epic-sized?** If the request clearly spans several deliverables or components,
  or would sensibly be more than one PR, it's probably an **epic**, not one issue. Say so
  and ask how to handle it:
  - create it as an **epic** (a parent issue), and capture children as separate issues
    (now or later), or
  - keep it as a **single issue** (it's smaller than it looks, or it'll be split during
    refinement).

  If epic: create the parent labeled `epic` (GitHub) / as an Epic type (Jira). Capturing
  the children now is optional — offer to, but don't force a full breakdown at capture time.

- **Does it belong under an existing epic?** For a normal (non-epic) issue, list open epics
  — GitHub `gh issue list --label epic --state open`, Jira the project's epics. If the new
  issue plausibly fits one, propose linking it as a child and confirm. If confirmed, create
  it and then link it as a child (GitHub sub-issue / Jira Epic Link — commands in
  `workflow/issue-tracker.md`). If nothing fits or the user declines, create it standalone.

If neither applies (a plain, self-contained issue with no matching epic), skip this and
carry on — this is the common case.

### 3. Draft the issue

Write a concise issue:

- **Title**: short, imperative, specific. E.g. "Contacts list not paginating past
  page 2", not "bug in contacts".
- **Body**: the problem and known context. Don't invent scope, acceptance criteria,
  or a solution — that's refinement. A short "Context / notes" section is enough.

Show the draft (title + body) to the user and confirm before creating.

### 4. Create it in the tracker

- **GitHub**: `gh issue create --title "<title>" --body-file <file>` (add
  `--label <type>` if the project uses type labels). Returns the issue URL/number.
- **Jira**: `jira issue create` with the summary, description, and the project's
  issue type. Returns the key.

If step 2 decided this is an **epic** or a **child**, apply the hierarchy now
(details in `workflow/epics.md`):

- **Epic**: add the `epic` label on GitHub (`--label epic`) / create it as an Epic type
  on Jira.
- **Child**: after creating it, link it to its parent — GitHub sub-issue / Jira Epic Link
  (commands in `workflow/issue-tracker.md`) — and confirm the link took.

### 5. Output

Confirm with the issue number/key and its URL. Suggest `/refine-issue <n>` to make it
implementable, then `/work-issue <n>` to build it.

## Keep it minimal

Creating an issue is cheap and reversible. Don't block on a perfect write-up — capture
the intent, create it, and let `/refine-issue` do the deep work. If the user already
handed you a full spec, don't strip it down: put it in the body as-is.
