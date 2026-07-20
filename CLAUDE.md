# Instructions for Claude Code

This project uses a workflow defined in `workflow/`. **Read those files before acting.**

## Rules

The full, canonical hard rules live in **`workflow/rules.md`** — read them first.
The essential safety rules, repeated here so they're never missed:

- **Never merge or push to `main`.** The flow ends with an open PR (see `workflow/git-flow.md`).
- **Never run `git commit` or `git push` unless the user explicitly asks.** Running `/work-issue` counts as that request for its commit → push → PR flow. Don't commit or push on your own initiative.
- **Never commit secrets or credentials.** Keep them in gitignored `.env` files and provide a `.env.example` with placeholder values.
- **Plan before non-trivial work, and ask when something is ambiguous.** Don't invent requirements.
- **Language.** All artifacts (code, comments, commits, branches, issues, PRs, docs) are written in English unless the user asks otherwise. Reply in the language the user writes in.

Above all, follow `workflow/principles.md`: do the minimum that solves the problem; don't over-engineer.

## Model strategy

You plan with Opus and implement with Sonnet (see `workflow/model-strategy.md`). The simplest way: start with `claude --model opusplan` or run `/model opusplan`, and Claude Code switches on its own between the planning and execution phases. Don't hardcode versions; use the `opus`/`sonnet` aliases that always point to the latest.

## Available commands

- `/init-project` — interactive scaffolding of a new project. Reads `workflow/scaffolding.md`.
- `/create-issue <description>` — creates a new issue in the tracker from a description. Reads `workflow/issue-creation.md`.
- `/refine-issue <n>` — refines and clarifies an issue. Reads `workflow/issue-refinement.md`.
- `/work-issue <n>` — implements a refined issue following the git flow. Reads `workflow/git-flow.md`.

## Reading order at startup

1. `workflow/rules.md`
2. `workflow/principles.md`
3. The invoked command (if any).
4. The specific guide that command references.
