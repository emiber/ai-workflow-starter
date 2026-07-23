# Hard rules — canonical source

These are the non-negotiable rules for every agent working in this repo. This
file is the **single source of truth**: the agent entry points (`CLAUDE.md`,
`AGENTS.md`, `.github/copilot-instructions.md`) keep only the essential safety
rules inline and point here for the full list. If a rule changes, change it here.

1. **Do the minimum that solves the problem.** Follow `workflow/principles.md`:
   no abstractions, layers, or dependencies "just in case".
2. **Plan before non-trivial work.** Present the plan and wait for approval before
   implementing anything non-trivial. Don't assume requirements.
3. **Ask when something is ambiguous.** One extra question is cheaper than a wrong
   assumption. Don't invent requirements.
4. **Never merge or push to `main`.** The flow ends with an open PR (see
   `workflow/git-flow.md`). A PR may target `main` or, for an issue that belongs to an
   epic, that epic's integration branch (see `workflow/epics.md`) — either way it's left
   open for human review, never merged.
5. **Never `git commit` or `git push` unless the user explicitly asks.** Invoking a
   mutating workflow explicitly authorizes only the side effects that workflow declares —
   e.g. `/work-issue` authorizes its commit → push → PR steps, and `/finish-epic` its
   epic-branch sync/push and integration PR. It does **not** authorize unrelated commits,
   pushes, merges, or PRs. Outside of an invoked workflow, make the changes and let the
   user decide when to commit or push — never do it on your own initiative.
6. **Never commit secrets or credentials.** Keep them in gitignored `.env` files
   and provide a `.env.example` with placeholder values.
7. **Language.** All artifacts — code, comments, commit messages, branch names,
   issues, PRs, and documentation — are written in English unless the user
   explicitly asks otherwise. Reply to the user in the language they write in.

Platform-specific behavior (slash commands vs. natural language, model strategy)
lives in each agent's entry file, not here.
