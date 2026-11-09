# Project README

> **Placeholder.** This repository was bootstrapped from the **AI Workflow Starter**.
> Running `/init-project` replaces this file with a README that describes *your*
> project — what it is, how to run it, how to develop and test it.
>
> How the AI-assisted workflow works (commands, git flow, conventions) is documented
> in **[workflow/README.md](workflow/README.md)**. That file stays; only this one gets replaced.

## Quick start with the workflow

First create your own repo with **Use this template** (see "Getting started" in [workflow/README.md](workflow/README.md)) and work in a clone of it, not a plain clone of the starter.

1. Open Claude Code in this folder: `claude --model opusplan`. It uses Opus only in plan mode, so the planning commands below switch to Opus first.
2. Run `/model opus`, then `/init-project` to scaffold the project (this replaces this README).
3. Still on Opus, write and refine issues with `/create-issue` and `/refine-issue <n>`.
4. Run `/model opusplan` before `/work-issue <n>`, which takes a refined issue to a PR.

Full details: **[workflow/README.md](workflow/README.md)**.
