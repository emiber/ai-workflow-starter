---
name: init-project
description: Interactively scaffold a new project from this template — ask the project type, define components, suggest technologies, and generate a runnable base. Use when starting a new project.
---

# init-project

Scaffold a new project through questions. This is the canonical playbook: Codex runs it directly and the Claude Code `/init-project` command delegates to it. The detailed rules live in `workflow/`.

1. Read `workflow/rules.md`, `workflow/principles.md`, and `workflow/scaffolding.md`.
2. If the user gave an initial project description, use it as a starting point, but still confirm the details.
3. Follow `scaffolding.md` exactly — including the pre-check for an existing `docs/ARCHITECTURE.md`, the question flow (project type → components → technologies), the design phase (4a: emit `ARCHITECTURE.md`, pause for review), the generation phase (4b: project files, only after explicit confirmation), enabling branch protection on `main` (step 5: resolve and show the target repo from `origin`'s single github.com push URL, stop on the starter or a mismatch with gh's repo, check read-only whether `main` is already protected, never change existing protection, create it only when its absence is verified and the user says yes, and report the outcome (created, preserved, unverified or not created) with the manual steps whenever it wasn't created), and landing the scaffold (**Land the scaffold**). Ask in small groups, not all at once.
4. Apply YAGNI: don't add components or dependencies that weren't confirmed. Suggest technologies with a reason, but the user's preferences win.
5. The generated stack must include a configured linter and a test framework wired to report coverage and fail when it drops below the project threshold (default 85%), enforced identically in the local scripts and in CI (`.github/workflows/ci.yml`). Record the exact lint and test-with-coverage commands in the **Quality gate** section of `docs/ARCHITECTURE.md`. The result has to start, run, and pass its own quality gate (step 6's integrity check runs it) — or, if the gate can't run locally, report it as not run with the reason.
6. Run the template integrity check in `scaffolding.md`; report anything still off.
7. Then follow **Land the scaffold** in `scaffolding.md`: say the scaffold is uncommitted and, only when its landing gate holds (target check passed, `main` on GitHub, quality gate passed), offer the branch → commit → push → PR into `main`. Act only on an explicit yes and never push to `main`; otherwise say what must be fixed first and print the commands.
