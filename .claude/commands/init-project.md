---
name: init-project
description: Interactive scaffolding of a new project. Asks the project type, defines components, suggests technologies, and generates the base.
---

# /init-project

You start the scaffolding of a new project.

1. Read `workflow/rules.md`, `workflow/principles.md`, `workflow/scaffolding.md`, and `workflow/model-strategy.md`. This is the design phase → use the planning model (Opus). If you're not on `opusplan`, switch with `/model opus`.
2. Follow the question flow in `scaffolding.md`: project type → components → technologies → confirmation.
3. Ask in small groups, not all at once. Suggest technologies with a reason, but the user's preferences win.
4. Apply YAGNI: don't add components or dependencies that weren't confirmed.
5. Before generating files, summarize the architecture and ask for explicit confirmation.
6. Generate `docs/ARCHITECTURE.md`, the folder structure, and the base files — including replacing the placeholder root `README.md` with the project's own (leave `workflow/` untouched, `workflow/README.md` included). The generated stack must include a configured linter and a test framework wired to report coverage and fail when it drops below the project threshold (default 85%), enforced identically in the local scripts and in CI (`.github/workflows/ci.yml`). The result has to start.

Arguments (optional): $ARGUMENTS may carry an initial project description. If present, use it as a starting point but still confirm the details.
