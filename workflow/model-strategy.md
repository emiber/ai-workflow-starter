# Model strategy

General rule: **plan/design with Opus, implement with Sonnet.** Always the latest version of each.

## Why this split

- **Opus** reasons better on multi-file problems, architecture decisions, and requirement refinement. It's worth its cost in the thinking phase.
- **Sonnet** is faster and cheaper, and more than enough to generate code once the plan is clear. Running Opus to write boilerplate is throwing away tokens.

## Don't hardcode versions

**Don't put `claude-opus-4-8` or `claude-sonnet-4-6` in any command.** The numbers change and go stale without you noticing. Reference the *role* ("planning model" / "implementation model") and let Claude Code resolve the version.

To see which version is the latest today: `/model` with no arguments opens the picker and shows the available ones.

## How to apply it in Claude Code

Three ways, from least to most automatic:

1. **Manual per phase** — you switch depending on the phase you're in:
   ```
   /model opus     # before planning / refining an issue
   /model sonnet   # before implementing
   ```
   `opus` and `sonnet` are aliases that always point to the latest version of each family, so this doesn't age.

2. **`opusplan` (recommended)** — native hybrid mode: Claude Code uses Opus for the planning/reasoning phase and switches on its own to Sonnet to execute.
   ```
   /model opusplan
   ```
   It's literally the flow you asked for, without having to remember to switch.

3. **Default at startup** — `claude --model opusplan` so the whole session runs with this behavior.

## Mapping to this repo's commands

| Command | Phase | Model |
|---|---|---|
| `/init-project` | architecture design | planning (Opus) |
| `/create-issue` | issue capture | planning (Opus) |
| `/refine-issue` | analysis and clarification | planning (Opus) |
| `/work-issue` | implementation | execution (Sonnet) |

With `opusplan` active you don't have to think about this: the mode makes the switch at the right time.

## Cost note

Switching models mid-session reprocesses the whole history (more tokens). For long tasks, it's better to plan in an Opus session and start a fresh Sonnet session to implement, instead of switching with an already-huge context. `opusplan` handles this internally better than manual switching.
