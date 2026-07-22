# AGENTS.md

Guidance for code agents (Codex and compatible) in this project.

The full workflow lives in `workflow/`. Read, in order:

1. `workflow/rules.md` — the canonical hard rules (merge/push, commits, secrets, language).
2. `workflow/principles.md` — principles that govern every decision. The main one: do the minimum that solves the problem; don't over-engineer.
3. `workflow/scaffolding.md` — how to define the architecture and stack of a new project.
4. `workflow/issue-creation.md` — how to create a new issue in the tracker.
5. `workflow/issue-refinement.md` — how to refine an issue before implementing it.
6. `workflow/git-flow.md` — the git flow contract: `main → branch → implementation → PR`.
7. `workflow/epics.md` — epics: parent/child issues and integration branches, plus the `/finish-epic` contract.
8. `workflow/model-strategy.md` — which model to use in each phase (planning vs implementation).
9. `workflow/issue-tracker.md` — GitHub (default) or Jira; how it's resolved and each one's commands.

## Hard rules

The canonical list is in `workflow/rules.md`. The essential safety rules, inline so they're never missed:

- Never merge or push to `main`. The flow ends with an open PR.
- Never `git commit` or `git push` unless the user explicitly asks (running the work-issue flow counts as asking). Don't commit or push on your own initiative.
- Never commit secrets or credentials. Keep them in gitignored `.env` files; provide a `.env.example` with placeholder values.
- Plan before non-trivial work, and ask when something is ambiguous — don't invent requirements.
- Language: write all artifacts (code, comments, commits, branches, issues, PRs, docs) in English unless the user asks otherwise; reply in the language the user writes in.

Above all, follow `workflow/principles.md`: do the minimum that solves the problem; don't over-engineer.

> Note: the Codex CLI supports built-in slash commands. Reusable custom workflows are **skills**, stored in `.agents/skills/<name>/SKILL.md` in a repository or `$HOME/.agents/skills/<name>/SKILL.md` for one user. Select a skill with `/skills` or invoke it as `$skill-name`; a skill does not create a custom `/skill-name` command. This starter ships Codex skills under `.agents/skills/` (`init-project`, `create-issue`, `refine-issue`, `work-issue`, `finish-epic`) that mirror the Claude Code commands and point to the same `workflow/` guides, so Codex discovers them automatically — or just ask in natural language ("refine issue 42") and follow the matching `workflow/` file.
