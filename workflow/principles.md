# Principles

Principles extracted from Ponytail, BMAD, and Superpowers. These aren't the frameworks: they're the ideas worth keeping, condensed.

## From Ponytail — think like the laziest senior (in the good way)

1. **Do the minimum that solves the problem.** The best line of code is the one you don't write. If something can be solved with a function, don't build a class; if it can be solved with a table, don't add a queue.
2. **Pick the boring solution.** Between two options, the more familiar and predictable one wins. No new technology out of curiosity.
3. **Don't over-engineer for requirements that don't exist.** Don't add configurability, abstraction layers, or "hooks for the future" nobody asked for. YAGNI.
4. **Delete before you add.** If you can solve something by removing code instead of adding it, remove it.
5. **Reasonable doubt = ask.** Asking is cheaper than redoing.
6. **Justify every new dependency.** Prefer the standard library or something already in the project. A dependency is a liability (maintenance, security, footprint); add one only when it clearly beats writing the small thing yourself, and say why.

## From BMAD — phases with explicit artifacts

BMAD organizes work into roles/phases (analyst → PM → architect → dev → QA). We don't copy the roles; we copy the discipline of **phasing with reviewable outputs**:

1. **Analysis** — understand the problem. Output: a clear description of the what and the why.
2. **Design** — decide architecture and stack. Output: `docs/ARCHITECTURE.md`.
3. **Stories/Issues** — split the work into small, verifiable units. Output: refined issues.
4. **Implementation** — code. Output: PR.
5. **Verification** — tests and review. Output: an approvable PR.

Each phase leaves something a human can read and approve before moving to the next. **Don't jump from "idea" to "code" without passing through design.**

## From Superpowers — modular knowledge and reusable commands

1. **A prompt you repeat three times is a command.** Instead of rewriting instructions, let them live in `.claude/commands/`.
2. **Load context on-demand.** Don't put all the knowledge in one giant file; split by topic (`scaffolding.md`, `issue-refinement.md`, `git-flow.md`) and read the relevant one.
3. **Self-contained instructions.** Each `workflow/` file must be readable on its own and say what to do, without depending on you having read the others.

## Components and tests

1. **Prefer atomic, composable components.** Build the smallest units that do one thing well, then compose them. A small, single-responsibility component is easier to understand, reuse, and test than a large one that does many things — the same spirit as Ponytail: the simplest thing that works.
2. **Every component ships with unit tests.** A component isn't "done" without tests covering its normal, edge, and error cases.
3. **Test coverage meets the project threshold (default 85%).** If a change drops coverage below the threshold, add tests before opening the PR. Treat it as a floor, not a number to game — cover real behavior, not lines for the sake of the metric. 85% is the default; a project may record a different threshold and measurement type in `docs/ARCHITECTURE.md`, but any deviation is an explicit, documented decision and must be enforced identically in the local scripts and in CI (`.github/workflows/ci.yml`).
4. **Never weaken tests to make them pass.** Don't delete, skip, or loosen a test just to get green, and don't bypass git hooks (`--no-verify`). If a test fails, fix the code or fix the test for a real reason — and say which.

## Docs travel with code

When you change behavior, setup, or public interfaces, update the relevant docs in the same PR (`README`, `docs/ARCHITECTURE.md`, inline docs). Stale docs are worse than no docs. If a change genuinely needs no doc update, that's fine — but decide it, don't just forget it.

## Conflict rule

If two principles clash, Ponytail (simplicity) wins. BMAD brings order, not bureaucracy: if a phase doesn't add value for a small change, skip it and say so explicitly.
