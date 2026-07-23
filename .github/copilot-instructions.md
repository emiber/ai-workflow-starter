# GitHub Copilot Instructions

Guidance for GitHub Copilot in this project.

The full workflow lives in `workflow/`. Copilot **does** support slash commands —
in VS Code via *prompt files* (`.github/prompts/*.prompt.md`, invoked as `/name`),
and the Copilot CLI ships built-in ones (`/model`, `/context`, ...) plus a plan
mode, custom agents, and skills. What this starter does *not* ship is Copilot
prompt files for its own commands: `/init-project`, `/create-issue`,
`/refine-issue`, `/work-issue`, `/finish-epic`, and `/review-pr` are defined
only under `.claude/commands/` (Claude Code format).

So with Copilot you have two options:

- **Natural language** (works everywhere): ask "refine issue 42" or "work on
  issue 42" and follow the steps in the matching `workflow/` file.
- **Add prompt files** (optional): create `.github/prompts/refine-issue.prompt.md`
  and friends that point to the same `workflow/` guides, to get real
  `/refine-issue` slash commands in VS Code.

Read, in order:

1. `workflow/rules.md` — the canonical hard rules (merge/push, commits, secrets, language).
2. `workflow/principles.md` — the principles that govern every decision. The main one: do the minimum that solves the problem; don't over-engineer.
3. `workflow/scaffolding.md` — how to define the architecture and stack of a new project.
4. `workflow/issue-creation.md` — how to create a new issue in the tracker.
5. `workflow/issue-refinement.md` — how to refine an issue before implementing it.
6. `workflow/git-flow.md` — the git flow contract: `main → branch → implementation → PR`.
7. `workflow/epics.md` — epics: parent/child issues and integration branches, plus the `/finish-epic` contract.
8. `workflow/pr-review.md` — the read-only PR review contract: linked-issue ACs + Definition of Done.
9. `workflow/model-strategy.md` — which model to use in each phase (Claude Code specific; ignore if it doesn't apply).
10. `workflow/issue-tracker.md` — GitHub (default) or Jira; how it's resolved and each one's commands.

## Hard rules

The canonical list is in `workflow/rules.md` (read it). The essential safety rules, inline so they're never missed:

- Never merge or push to `main`. The flow ends with an open PR.
- Never `git commit` or `git push` unless the user explicitly asks (running the `/work-issue` flow counts as asking). Don't commit or push on your own initiative.
- Never commit secrets or credentials. Keep them in gitignored `.env` files; provide a `.env.example` with placeholder values.
- Plan before non-trivial work, and ask when something is ambiguous — don't invent requirements.
- Language: write all artifacts (code, comments, commits, branches, issues, PRs, docs) in English unless the user asks otherwise; reply in the language the user writes in.
