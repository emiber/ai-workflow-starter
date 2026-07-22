# Epics — parent/child issues and integration branches

Some work is too big for a single issue and one PR. An **epic** is a parent issue
that groups related **child issues**, each of which is still implemented and merged
on its own. This file is the single source of truth for how epics work; the issue
and git-flow guides point here.

Keep it to **two levels**: `epic → issue`. A child does not have its own children.
If a piece of work feels like it needs a third level, it's a sign the epic is too
big — split it into two epics instead. (Ponytail: the boring, minimal structure wins.)

Epics are **opt-in**. Most issues have no parent and follow the plain
`main → branch → PR` flow in `git-flow.md` unchanged. Everything here is additive and
only applies when an issue belongs to an epic.

## How the hierarchy is represented per tracker

### GitHub

There is no native "epic" issue type available in every repo (issue *types* are an
org-level feature), so an epic is:

- **A parent issue labeled `epic`.** The label is what makes epics listable and
  detectable (`gh issue list --label epic --state open`).
- **Linked to its children via native sub-issues.** GitHub has a real parent/child
  sub-issue relationship, but `gh` has no dedicated subcommand for it, so use `gh api`:

  ```bash
  # Link issue <childN> as a sub-issue of epic <epicN>.
  # NOTE: the endpoint takes the child's internal id, NOT its issue number.
  child_id=$(gh api "repos/{owner}/{repo}/issues/<childN>" --jq .id)
  gh api --method POST "repos/{owner}/{repo}/issues/<epicN>/sub_issues" \
    -F sub_issue_id="$child_id"

  # List an epic's children:
  gh api "repos/{owner}/{repo}/issues/<epicN>/sub_issues" --jq '.[].number'
  ```

  `{owner}/{repo}` is filled by `gh` automatically inside a repo, so you can write the
  paths literally as shown.

The label alone is enough to make the flow work; the sub-issue link adds the native
tree in GitHub's UI and lets the flow enumerate children reliably. Create both.

### Jira

Jira has a first-class **Epic** issue type. Create the parent as an Epic and link each
child with the **Epic Link / parent** field (`jira issue create` with the parent, or set
it on an existing issue with `jira issue edit`). No label convention is needed — the
Epic type and parent field are native.

## Integration branch model

An epic's children are **not** merged straight to `main` one by one. Instead:

```
main
 └── epic/<epicN>-<slug>              ← integration branch (one per epic)
      ├── feat/<child1N>-<slug>       → PR targets the epic branch
      ├── feat/<child2N>-<slug>       → PR targets the epic branch
      └── ...
 (when the epic is done) epic/<epicN>-<slug> ──PR──▶ main
```

- **One integration branch per epic**, named `epic/<epicN>-<slug>`.
- It is created **lazily** — the first time a child is worked (see `git-flow.md`), not
  when the epic issue is created. Nothing exists until it's needed.
- **Child branches** keep the normal `<type>/<childN>-<slug>` convention but are cut
  from the epic branch, and their PR targets the epic branch (`--base epic/<epicN>-<slug>`).
- When all children are done, `/finish-epic <epicN>` opens a single PR from the epic
  branch to `main`.

### Why child PRs use `Refs`, not `Closes` (GitHub)

GitHub only auto-closes an issue from a closing keyword (`Closes #n`) when the PR merges
into the **default branch** (`main`). A child PR merges into the *epic* branch, so
`Closes` there would do nothing. To avoid dead keywords and surprise, child PRs into the
epic branch reference their issue with **`Refs #<childN>`** (a link, no auto-close). The
children are closed all at once when the epic reaches `main`: the `/finish-epic` PR body
aggregates `Closes #<epicN>` **and** `Closes #<each childN>`, so merging it to `main`
closes the whole tree. This also matches the intent — a child isn't really "done" until
it ships in `main`.

This is the default because it needs zero extra machinery: the flow never merges (PRs are
left open for humans), so the only automatable close point is the epic's merge into `main`.
The tradeoff is that GitHub's sub-issue progress on the epic won't advance mid-flight — it
jumps to complete when the `/finish-epic` PR merges. If you want live progress, close each
child by hand when its PR merges into the epic branch (GitHub won't do it for you on a
non-default-branch merge); `/finish-epic` then closes whatever is still open. Leaving them
is fine and is the recommended default.

On Jira, GitHub PRs don't close issues automatically anyway (a human or Jira automation
does), so just reference the keys; the aggregation note is GitHub-specific.

## `/finish-epic <n>` — contract

Guide for the `/finish-epic` command. Opens the integration PR (`epic/<n>-<slug> → main`)
when an epic's children are done. Like `git-flow.md`, this is strict: the flow ends with
an **open PR**; never merge, never push to `main`.

### Preflight (read-only — if one fails, stop and report the fix)

| Check | How |
|---|---|
| `git` + inside a repo | `git --version`, `git rev-parse --is-inside-work-tree` |
| `main` exists, `origin` set, `gh` authenticated | as in `git-flow.md` |
| Tracker resolved | see `workflow/issue-tracker.md` |
| `<n>` is an epic | GitHub: has the `epic` label. Jira: is an Epic. If not, stop. |
| Integration branch exists | `epic/<n>-<slug>` exists locally or on `origin`. If it doesn't, no child was ever worked — say so and stop. |

### Steps

1. **Fetch the epic and its children.** GitHub: `gh api .../issues/<n>/sub_issues`.
   Jira: list issues with this Epic as parent.
2. **Check children are done.** List each child and its state. If any child is still
   open or its PR into the epic branch isn't merged, **warn and list them**, and ask the
   user whether to proceed anyway or wait. Don't silently proceed.
3. **Sync the epic branch with main.** Check out `epic/<n>-<slug>`, and merge the latest
   `main` into it so the PR diff is clean:
   ```bash
   git checkout epic/<n>-<slug>
   git fetch origin
   git merge origin/main        # resolve conflicts here if any; never force
   git push origin epic/<n>-<slug>
   ```
   If there are conflicts you can't resolve safely, stop and report.
4. **Open the integration PR.**
   ```bash
   gh pr create \
     --base main \
     --head epic/<n>-<slug> \
     --title "<type>: <epic title>" \
     --body "Closes #<n>
   Closes #<child1>
   Closes #<child2>
   ...

   ## Epic summary
   What this epic delivers, as a whole.

   ## Children
   - #<child1> <title>
   - #<child2> <title>"
   ```
   On Jira, drop the `Closes` lines, put the Epic key in the title (`[ABC-123] ...`), and
   list child keys in the body.
5. **Don't merge.** Leave the PR open for human review and return its link.

### Hard rules (same spirit as `git-flow.md`)

- Never merge or push to `main` directly; the epic ships via this open PR.
- Never `git push --force` to the epic branch (it's shared — children branch off it).
- Never auto-merge, never skip hooks, never weaken tests.
- If any step fails, stop and report; don't improvise destructive workarounds.
