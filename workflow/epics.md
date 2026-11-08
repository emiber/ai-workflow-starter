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
  sub-issue relationship. The concrete commands to link a child, list an epic's children,
  and detect a child's parent — native `gh` (≥ 2.94), with a REST fallback for older `gh`
  or GitHub Enterprise Server — live in `workflow/issue-tracker.md` (Parent/child). Use
  them from there; this guide doesn't repeat the syntax.

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

- **One integration branch per epic**, named `epic/<epicN>-<slug>` and identified by its
  `epic/<epicN>-` prefix. The slug is cosmetic: it's chosen once, from the epic's title,
  when the branch is created, and never re-derived (a title can change, and two runs can
  slug it differently). Every lookup uses the prefix (see **Finding the integration
  branch** below), and every later `epic/<epicN>-<slug>` in this guide (written
  `epic/<n>-<slug>` in the `/finish-epic` section) means the branch that lookup resolved,
  never a slug re-derived from the title.
- It is created **lazily** — the first time a child is worked (see `git-flow.md`), not
  when the epic issue is created. Nothing exists until it's needed.
- **Child branches** keep the normal `<type>/<childN>-<slug>` convention but are cut
  from the epic branch, and their PR targets the epic branch (`--base epic/<epicN>-<slug>`).
- When all children are done, `/finish-epic <epicN>` opens a single PR from the epic
  branch to `main`.

### Finding the integration branch

Look the branch up by the epic's number, locally and on `origin`:

```bash
git fetch origin
git for-each-ref --format='%(refname:short)' "refs/heads/epic/<epicN>-*"   # local
git ls-remote --heads origin "refs/heads/epic/<epicN>-*"                     # origin
```

- If any of these commands exits non-zero (network, auth, missing remote), stop and
  report the error. Only a command that succeeds with empty output means "no match".
- Collect the distinct branch names from both outputs, after stripping `refs/heads/` from
  the `ls-remote` lines. The same name locally and on `origin` is one branch.
- **Exactly one** → that's the epic branch, whatever its slug. **More than one** (e.g.
  `epic/6-foo` locally and `epic/6-bar` on `origin`) → stop and ask the user which one is
  the epic's branch; never pick one silently. **None** → the epic has no branch yet:
  `/work-issue` creates it for the first child (`workflow/git-flow.md` step 3), and
  `/finish-epic` stops.
- The `-` after the number keeps other epics out (`epic/6-*` doesn't match `epic/60-…`),
  and the `refs/heads/` anchor stops `ls-remote` from also matching branches such as
  `backup/epic/6-old`.

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
| Working tree clean | `git status --porcelain` is empty. If not, the fix is: commit, stash, or discard changes before starting. Never stash or discard them on the user's behalf. |
| Tracker resolved | see `workflow/issue-tracker.md` |
| `<n>` is an epic | GitHub: has the `epic` label. Jira: is an Epic. If not, stop. |
| Integration branch exists | Find it by number, as in **Finding the integration branch** above. Exactly one → that's the epic branch, used by every later step. None → no child was ever worked: say so and stop. More than one → stop and ask the user which one is the epic's branch. A failed `git fetch` or `git ls-remote` → stop and report the error; it never means "no branch". |

### Steps

1. **Fetch the epic and its children.** GitHub: list the epic's children (parent/child
   commands in `workflow/issue-tracker.md`). Use the list only once the listing command
   has succeeded: check its exit status before reading its output; with the REST fallback,
   that means every page (rules in that guide). If it fails, discard whatever it printed,
   even children from pages that succeeded, and stop: report the epic and the error.
   Nothing below — the done check, the sync and push, the `Closes` lines, the PR — runs on
   a failed or partial list. Jira: list issues with this Epic as parent. The result is
   **the child list**, each child once; steps 2 and 5 both use it.
2. **Check children are done.** List the PRs into the epic branch once, where
   `<epic branch>` is the branch the preflight resolved:
   ```bash
   gh pr list --base <epic branch> --state all --limit 200 \
     --json number,headRefName,state,mergedAt
   ```
   If the command exits non-zero, stop and report the error; a failed query never means a
   child is missing. A PR belongs to child `<childN>` when its head branch matches
   `*/<childN>-*`, the `<type>/<childN>-<slug>` convention (`*/1-*` doesn't match
   `feat/12-…`). For each child in the child list (step 1):
   - **Done**: at least one of its PRs is `MERGED`, whether or not the child *issue* is
     still open. Leaving child issues open until the epic reaches `main` is the recommended
     default (see above), so an open child issue whose PR is already merged is **not**
     incomplete and must not warn.
   - **Missing**: no PR matches. Report it as "missing (no PR into the epic branch; it may
     have targeted another base)".
   - **Not merged**: it has matching PRs, but none is merged. Report each PR's state: open,
     or closed without merging.

   If the query returned exactly 200 PRs, the list may be truncated (it's newest first, so
   the oldest PRs drop out): report a child with no matching PR as "not found; the PR list
   may be truncated" instead of missing. If any child isn't done, **stop and report those
   children and do not open the integration PR** — there is no "proceed anyway". The epic
   ships only once every child's PR is merged into the epic branch, so step 5 (which closes
   the epic and all children) is reached only when the work is actually there.
3. **Sync the epic branch with main.** Bring the local epic branch up to date with
   `origin`, then merge the latest `main` into it so the PR diff is clean. Nothing is
   pushed here: step 4 validates the result first, and step 5 pushes it.
   ```bash
   git fetch origin
   git checkout epic/<n>-<slug>
   git merge-base --is-ancestor HEAD origin/epic/<n>-<slug>   # non-zero → stop and report
   git pull --ff-only origin epic/<n>-<slug>
   git merge origin/main        # resolve conflicts here if any; never force
   ```
   - The local copy is usually behind `origin` (it was last pulled when the last child's
     branch was cut, before that child's PR merged), so the pull fast-forwards it and
     step 5's push stays a fast-forward. With no local copy, the checkout creates one
     tracking `origin/epic/<n>-<slug>`, which the fetch has just updated.
   - **Ancestry check** (the `git merge-base --is-ancestor` line). It runs after the
     checkout, so that `HEAD` is the epic branch, and before the pull. Exit 0: the local
     branch is equal to or behind `origin`; go on. Non-zero: the local branch has commits
     that aren't on `origin` (it's ahead or has diverged, e.g. an unpushed merge commit
     from an earlier run), or the check couldn't run. Stop and report those commits
     (`git log --oneline origin/epic/<n>-<slug>..HEAD`) or the error; the user decides
     whether to push or drop them. Never reset, rebase, or force-push the shared epic
     branch. `git pull --ff-only` alone doesn't catch this: on a branch that is only ahead
     it reports "Already up to date" and exits 0, and step 5's push would then publish
     those commits. A pass in step 4 never waives this stop, even for commits an earlier
     run validated: it covers only what this run adds after the check.
   - A no-op isn't a failure: a pull or merge that reports "Already up to date" means
     there was nothing to bring in; go on. Step 4 still runs.
   - Resolve any conflicts and commit the merge before step 4: it validates a commit,
     never a half-merged tree. When the merge stops on conflicts, first record the
     **conflicted files** (`git diff --name-only --diff-filter=U`), before you resolve or
     `git add` anything: the list is empty afterwards, and step 4's review needs it. If
     there are conflicts you can't resolve safely, stop and report.
4. **Validate the final revision.** Each child's PR was checked on its own, but merging
   `main` can still break the combined result (e.g. `main` changed an interface a child
   uses). Before anything is pushed, check the exact commit step 5 will publish, in this
   run — also when step 3's merge was conflict-free or "Already up to date". A child's
   Verification, an earlier run, or green CI never counts as this check.
   - **Candidate.** `git status --porcelain` prints nothing (no unresolved conflict,
     nothing uncommitted) and `git rev-parse HEAD` gives the candidate SHA. Every result
     below holds for that SHA only.
   - **Quality gate**, as in `workflow/git-flow.md` step 4: the complete lint and
     test-with-coverage commands from the **Quality gate** section of
     `docs/ARCHITECTURE.md` — the ones CI runs, not just the tests near the conflicts —
     plus the other checks CI runs on a PR into `main` (e.g. the workflow integrity
     checks, `bash .github/scripts/check-workflow.test.sh` and
     `bash .github/scripts/check-workflow.sh`). If the commands aren't recorded, take
     them from the project's own scripts, configuration and CI, never from the
     template's examples. Total coverage must meet the recorded threshold (default 85%).
     List each new or changed source file in the epic's diff
     (`git diff origin/main...HEAD`) that is below it, with the reason, and add tests
     unless there's a real reason not to; a per-file reason never waives the total.
   - **Integration review**, read-only, following `workflow/pr-review.md` in local diff
     mode as an **epic integration**. As in `workflow/git-flow.md` step 5, give a fresh
     agent only the epic, its child list (step 1), the base `origin/main` (as fetched in
     step 3; never a local `main`, which this flow doesn't update), the candidate SHA and
     the merge context; if you can't start one, run the review yourself and record it as
     inline. The merge context is `git diff origin/epic/<n>-<slug> HEAD` (all this run
     adds to the published epic: what `main` brought in, the conflict resolutions, any
     fixes) and, if step 3 made a merge commit `<merge>`, the conflicted files recorded
     in step 3. The review reads each conflicted file's resolution in full, against both
     parents (`git diff <merge>^1 <merge> -- <file>`, `git diff <merge>^2 <merge> -- <file>`);
     where Git is 2.36 or newer, `git show --remerge-diff <merge>` also shows how each
     conflict was resolved. `git show --cc` isn't enough: it leaves out a resolution
     that keeps one side, such as dropping what `main` changed. The review
     checks these, and how they meet the epic's own changes, against the acceptance
     criteria of the epic and of the children they affect — correctness, security,
     docs — reading the affected files in full. It doesn't re-review unchanged child
     work.
     With no conflicts it still checks those interactions and records "no manual
     resolutions"; with nothing new from `main`, it records that. It reports; it
     doesn't fix.
   - **Any change starts the check again.** A fix for a gate failure or a review blocker
     (only within the epic's scope; anything else is reported, not fixed), or a file a
     formatter or hook changes, makes a new candidate: commit it on the epic branch and
     go back to **Candidate** — the full gate again, and the review refreshed for what
     changed. Results for an older SHA, or for a tree that differs from it, never
     authorize step 5.
   - **Stop before any push or PR** when a lint or test command fails, total coverage is
     below the threshold, an applicable gate couldn't run, conflicts are unresolved, or
     review blockers remain. Report the command or check, the failure or what kept it
     from running, and the next action. A gate that applies but can't be found or run
     (missing tool or dependency, sandbox limit, no coverage output, no time) is
     **blocked**, never passed and never `n/a`. `n/a` fits only a gate that doesn't
     apply to the whole integrated project, with the concrete reason (e.g. no
     application code yet, so no lint, test or coverage command exists; the checks CI
     does run still run); docs-only changes don't waive a configured check. Never weaken
     tests, lower the threshold, skip hooks, or reset, rebase or force-push. The merge
     and any fix commits stay local, so the next run stops at step 3's ancestry check
     until the user pushes or drops them; there's no automatic resume.
5. **Push and open the integration PR**, only for the commit step 4 validated:
   ```bash
   git status --porcelain       # must print nothing
   git rev-parse HEAD           # must be the SHA step 4 validated; if not, back to step 4
   git push origin epic/<n>-<slug>
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
   - #<child2> <title>

   ## Verification
   Validated revision: <SHA from step 4>
   - Lint: <command> — pass | n/a (<reason>)
   - Tests: <command(s)> — pass | n/a (<reason>)
   - Coverage: <total>% (threshold <t>%); new/changed files below threshold: none | <file — reason> | n/a (<reason>)
   - Self-review: integration review of <the conflicted files' resolutions | no manual resolutions>, <the integration fixes | no fixes> and what main brought in; blockers: <found and fixed | none>; suggestions not applied: <list | none> (separate agent | inline)
   - Security: pass (<what the integration touched>) | no security surface touched by the integration
   - Docs: updated <files> | not needed (<reason>)

   ## Out of scope / follow-ups
   None | - <item>"
   ```
   Write one `Closes #<child>` line per child in the child list (step 1), the same list
   step 2 checked: every child, each exactly once.

   **Verification** reports step 4 for the validated SHA, under the rules of
   `workflow/git-flow.md` step 6: every gate gets a line, a pass only if it ran in this
   run on that SHA, `n/a` only with its concrete reason. Put checks such as the workflow
   integrity checks on the Tests line. Security and Docs describe what the integration
   changed, not repeats of the children's reviews. Never paste credentials or sensitive
   output. The Children list links the children's work; it never replaces this evidence.
   - A push that reports "Everything up-to-date" isn't a failure: go on.
   - If the push is rejected (e.g. someone pushed to the epic branch after step 3's
     fetch), stop and report; don't open the PR, and never force-push. Anything that
     changes the candidate needs step 4 again before another push.
   - If `gh pr create` fails after the push, report it as it is: the branch is pushed,
     the PR isn't open. Don't undo the push.

   On Jira, drop the `Closes` lines, put the Epic key in the title (`[ABC-123] ...`), and
   list child keys in the body.
6. **Don't merge.** Leave the PR open for human review and return its link.

### Hard rules (same spirit as `git-flow.md`)

- Never merge or push to `main` directly; the epic ships via this open PR.
- Never `git push --force` to the epic branch (it's shared — children branch off it).
- Never push the epic branch or open the integration PR before step 4 has passed for the
  exact commit being pushed.
- Never auto-merge, never skip hooks, never weaken tests.
- If any step fails, stop and report; don't improvise destructive workarounds.
