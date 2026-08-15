---
name: init-project
description: Interactive scaffolding of a new project. Asks the project type, defines components, suggests technologies, and generates the base.
---

# /init-project

You start the scaffolding of a new project.

1. Read `workflow/rules.md`, `workflow/principles.md`, `workflow/scaffolding.md`, and `workflow/model-strategy.md`. This is the design phase → use the planning model (Opus). If you're not on `opusplan`, switch with `/model opus`.
2. Follow `scaffolding.md` exactly — including the pre-check for an existing `docs/ARCHITECTURE.md`, the question flow (project type → components → technologies), the design phase (4a: emit `ARCHITECTURE.md`, pause for review), the generation phase (4b: project files, only after explicit confirmation), and enabling branch protection on `main` (step 5). Ask in small groups, not all at once.
3. Apply YAGNI: don't add components or dependencies that weren't confirmed. Suggest technologies with a reason, but the user's preferences win.
4. The generated stack must include a configured linter and a test framework wired to report coverage and fail when it drops below the project threshold (default 85%), enforced identically in the local scripts and in CI (`.github/workflows/ci.yml`). The result has to start.
5. Run the template integrity check at the end of `scaffolding.md`; report anything still off.

Arguments (optional): $ARGUMENTS may carry an initial project description. If present, use it as a starting point but still confirm the details.
