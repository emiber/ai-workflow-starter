---
name: init-project
description: Interactively scaffold a new project from this template — ask the project type, define components, suggest technologies, and generate a runnable base. Use when starting a new project.
---

# init-project

Scaffold a new project through questions. Mirrors the Claude Code `/init-project` command; the logic lives in `workflow/`.

1. Read `workflow/rules.md`, `workflow/principles.md`, and `workflow/scaffolding.md`.
2. Follow the question flow in `scaffolding.md`: project type → components → technologies → confirmation. Ask in small groups, not all at once.
3. Apply YAGNI: don't add components or dependencies that weren't confirmed. Suggest technologies with a reason, but the user's preferences win.
4. Before generating files, summarize the architecture and ask for explicit confirmation.
5. Generate `docs/ARCHITECTURE.md`, the folder structure, and the base files — including replacing the placeholder root `README.md` with the project's own (leave `workflow/` untouched, `workflow/README.md` included). The generated stack must include a configured linter and a test framework wired to fail when coverage drops below the project threshold (default 85%). The result has to start.
6. Run the template integrity check at the end of `scaffolding.md`; report anything still off.
