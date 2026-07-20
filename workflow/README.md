# AI Workflow Starter

A base for kicking off projects with AI-assisted development. Optimized for **Claude Code**, with best-effort support for **GitHub Copilot** and **Codex**.

> **This file documents the workflow itself.** The project's own README lives at the repo root (`README.md`) and is generated/replaced by `/init-project`. This file is not touched by scaffolding.

It gives you two things:

1. **Interactive scaffolding** — the agent asks what kind of project you're building, defines the components (APIs, frontend, database, queues, etc.), suggests technologies, and generates the base.
2. **Issue → PR workflow** — interactive issue refinement and the `main → branch → implementation → PR` cycle.

## Getting started

1. **Copy this repo** as the base of your new project (clone it, or copy its contents into your project folder).
2. **Check the requirements**: `git` and `gh` (GitHub CLI) authenticated. For Jira issues, also the `jira` CLI. See [Git flow requirements](#git-flow-requirements).
3. **Open Claude Code** in the folder, ideally in Opus-plan mode so it plans with Opus and implements with Sonnet (details in `workflow/model-strategy.md`):
   ```bash
   claude --model opusplan
   ```
4. **Scaffold the project** — the agent asks what you're building and generates a runnable base (this replaces the placeholder root `README.md` with your project's own):
   ```
   /init-project
   ```
5. **Work in the issue → PR loop** — create an issue (optional), refine it, then implement it:
   ```
   /create-issue "contacts list not paginating past page 2"
   /refine-issue 42
   /work-issue 42
   ```
   The agent stops at an open PR; it never merges, and it won't commit or push unless you ask (running `/work-issue` is that ask).

### Commands

| Command | What it does | Phase |
|---|---|---|
| `/init-project` | Interactive scaffolding: asks project type, components and stack, then generates a runnable base. | Design (Opus) |
| `/create-issue <description>` | Creates a new issue in the tracker from a description — light capture, not full refinement. | Capture (Opus) |
| `/refine-issue <n>` | Turns a raw issue into an implementable one by asking every question needed. | Analysis (Opus) |
| `/work-issue <n>` | Implements a refined issue: `main → branch → code → PR`. | Implementation (Sonnet) |

> Not on Claude Code? The same workflow works with Codex (`AGENTS.md`) and GitHub Copilot (`.github/copilot-instructions.md`). For Codex, this starter ships skills under `.agents/skills/` (invoked with `/skills` or `$skill-name`) that mirror the Claude Code commands, so Codex picks them up automatically. Copilot supports slash commands via prompt files under `.github/prompts/`, but those aren't shipped here — with Copilot, use natural language ("refine issue 42") or add the equivalent prompt files. Either way the logic lives in `workflow/`.

## Philosophy

It doesn't install Ponytail, Superpowers, or BMAD. It **extracts principles** from each one (see `workflow/principles.md`):

- **Ponytail** → do the minimum that solves the problem. Don't over-engineer. When in doubt between two solutions, pick the more boring one.
- **BMAD** → split the work into phases with explicit outputs (analysis → design → stories → implementation). Each phase leaves a reviewable artifact.
- **Superpowers** → modular knowledge loaded on-demand; reusable commands instead of repeating prompts.

All three step on each other if installed whole (BMAD is heavy and opinionated; Ponytail is the opposite). Hence: principles, not frameworks.

## How the different agents use it

There is no universal format. The logic lives in neutral markdown (`workflow/`, `docs/`) and each agent has a thin pointer:

| Agent | File it reads | Support |
|---|---|---|
| Claude Code | `CLAUDE.md` + `.claude/commands/*.md` | Full (slash commands, interactive refinement) |
| Codex | `AGENTS.md` | Full (ships `.agents/skills/` mirroring the commands, plus natural language) |
| GitHub Copilot | `.github/copilot-instructions.md` | Good (natural language out of the box; slash commands if you add `.github/prompts/` files) |

All three point to the same `workflow/`. The difference is how much each one honors the interactive flow.

## Language

Reply to the user in the language they write in. But all artifacts — code, comments, commit messages, branch names, issues, PRs, and documentation — are written in English, unless the user explicitly asks for another language.

## Conventions

A few rules the agents enforce (full detail in `workflow/principles.md` and `workflow/git-flow.md`):

- **Atomic components + tests.** Prefer the smallest composable units; each ships with unit tests and coverage meets the project threshold (default 85%).
- **No commits or pushes unless you ask.** The agent implements and stops; running `/work-issue` is what authorizes its commit → push → PR flow.
- **No secrets in the repo.** Credentials live in gitignored `.env` files; a `.env.example` holds placeholders.
- **Minimal dependencies.** Every new dependency has to be justified.
- **One PR = one issue.** Changes stay small and focused; unrelated work becomes its own issue.
- **Docs travel with code.** Behavior or setup changes update the docs in the same PR.
- **CI enforces the gate.** A GitHub Actions workflow runs lint + tests + the coverage threshold (default 85%) on every PR (`/init-project` fills it in for your stack).

## Structure

```
.
├── README.md                       # The project's own README (placeholder until /init-project fills it)
├── CLAUDE.md                       # Pointer + rules for Claude Code
├── AGENTS.md                       # Pointer for Codex
├── .gitignore                      # Safe baseline (/init-project extends it per stack)
├── .env.example                    # Placeholder env vars; copy to gitignored .env
├── .workflow-config                # Issue tracker selection (github by default)
├── .github/
│   ├── copilot-instructions.md     # Pointer for Copilot
│   └── workflows/ci.yml            # Lint + tests + coverage threshold (default 85%) on PRs
├── .claude/commands/               # Claude Code slash commands (thin pointers to workflow/)
│   ├── init-project.md             # Interactive scaffolding
│   ├── create-issue.md             # Create a new issue in the tracker
│   ├── refine-issue.md             # Issue refinement
│   └── work-issue.md               # main → branch → impl → PR
├── .agents/skills/                 # Same four, as Codex skills (mirror the commands)
│   ├── init-project/SKILL.md
│   ├── create-issue/SKILL.md
│   ├── refine-issue/SKILL.md
│   └── work-issue/SKILL.md
├── workflow/
│   ├── README.md                   # This file — how the workflow works
│   ├── rules.md                    # Canonical hard rules (agent files point here)
│   ├── principles.md               # Extracted principles (Ponytail/BMAD/Superpowers)
│   ├── scaffolding.md              # Architecture decision guide + stacks
│   ├── issue-creation.md           # How to create an issue
│   ├── issue-refinement.md         # How to refine an issue
│   ├── git-flow.md                 # The git flow contract
│   ├── issue-tracker.md            # GitHub (default) or Jira
│   └── model-strategy.md           # Opus to plan, Sonnet to implement
└── docs/
    ├── ARCHITECTURE.md             # (generated by /init-project)
    └── ISSUE_TEMPLATE.md           # Refined issue template
```

## Issue tracker

Defaults to **GitHub**, already set in `.workflow-config` (`issue_tracker=github`), so the agent doesn't ask. To use Jira instead, edit that file (`issue_tracker=jira` plus `jira_project=...`). If the file is ever missing, the agent falls back to asking and defaults to GitHub. The PR always goes to GitHub, whatever tracker you use. Details in `workflow/issue-tracker.md`.

## Git flow requirements

`git` and `gh` (GitHub CLI) authenticated. For Jira, additionally the `jira` CLI configured. The agent does **not** merge; it leaves the PR open for human review.
