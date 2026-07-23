# Instructions for Claude Code

This project uses a workflow defined in `workflow/`. **Read those files before acting.**

## Rules

The full, canonical hard rules live in **`workflow/rules.md`** — read them first.
The essential safety rules, repeated here so they're never missed:

- Never merge or push to `main`. The flow ends with an open PR.
- Never `git commit` or `git push` unless the user explicitly asks (running the `/work-issue` flow counts as asking). Don't commit or push on your own initiative.
- Never commit secrets or credentials. Keep them in gitignored `.env` files; provide a `.env.example` with placeholder values.
- Plan before non-trivial work, and ask when something is ambiguous — don't invent requirements.
- Language: write all artifacts (code, comments, commits, branches, issues, PRs, docs) in English unless the user asks otherwise; reply in the language the user writes in.

Above all, follow `workflow/principles.md`: do the minimum that solves the problem; don't over-engineer.

## Model strategy

You plan with Opus and implement with Sonnet (see `workflow/model-strategy.md`). The simplest way: start with `claude --model opusplan` or run `/model opusplan`, and Claude Code switches on its own between the planning and execution phases. Don't hardcode versions; use the `opus`/`sonnet` aliases that always point to the latest.

## Available commands

- `/init-project` — interactive scaffolding of a new project. Reads `workflow/scaffolding.md`.
- `/create-issue <description>` — creates a new issue in the tracker from a description; may create it as an epic or nest it under an existing one. Reads `workflow/issue-creation.md` and `workflow/epics.md`.
- `/refine-issue <n>` — refines and clarifies an issue. Reads `workflow/issue-refinement.md`.
- `/work-issue <n>` — implements a refined issue following the git flow. Child issues of an epic target the epic's integration branch. Reads `workflow/git-flow.md` and `workflow/epics.md`.
- `/finish-epic <n>` — opens the integration PR (epic branch → `main`) when an epic's children are done. Reads `workflow/epics.md`.
- `/review-pr <n>` — reviews an open PR against its linked issue(s)' acceptance criteria and the Definition of Done. Read-only: never commits or pushes. Reads `workflow/pr-review.md`.

## Reading order at startup

1. `workflow/rules.md`
2. `workflow/principles.md`
3. The invoked command (if any).
4. The specific guide that command references.
