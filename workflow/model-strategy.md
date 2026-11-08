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

2. **`opusplan` (recommended)** — native hybrid mode: Claude Code uses Opus only while you're in plan mode (Shift+Tab) and Sonnet the rest of the time. It picks the model by mode, not by command.
   ```
   /model opusplan
   ```
   That fits `/work-issue`: plan in plan mode on Opus, implement on Sonnet. It doesn't run `/init-project`, `/create-issue` or `/refine-issue` on Opus; see **Mapping to this repo's commands** below.

3. **Default at startup** — `claude --model opusplan` so the whole session runs with this behavior: Opus only in plan mode, Sonnet otherwise.

## Mapping to this repo's commands

| Command | Phase | Model |
|---|---|---|
| `/init-project` | architecture design | planning (Opus) |
| `/create-issue` | issue capture | planning (Opus) |
| `/refine-issue` | analysis and clarification | planning (Opus) |
| `/work-issue` | implementation | execution (Sonnet) |
| `/finish-epic` | epic integration | execution (Sonnet) |
| `/review-pr` | read-only PR review | execution (Sonnet) |
| self-review inside `/work-issue` | read-only review subagent, clean context | execution (Sonnet) |

`opusplan` doesn't follow this table: it picks the model by plan mode, not by command, and outside plan mode every command runs on Sonnet. To follow the table:

- Run `/init-project`, `/create-issue` and `/refine-issue` with `/model opus`. Plan mode isn't a substitute: these commands write files or update the tracker, and plan mode blocks file edits until you approve a plan and needs approval for commands outside its read-only set (such as `gh issue edit`).
- Switch back with `/model opusplan` before `/work-issue`. `/model` also saves your choice as the default for new sessions, so otherwise later sessions start on Opus too.
- `/work-issue`, `/finish-epic` and `/review-pr` are fine on `opusplan` or `sonnet`.

One nuance: `opusplan` uses Opus only while you're in **plan mode**. The implementation plan that `/work-issue` posts for your approval is drafted by the execution model unless you switch to plan mode (Shift+Tab) for that step — worth doing for a non-trivial issue.

## Cost note

Switching models mid-session reprocesses the whole history (more tokens). For long tasks, it's better to plan in an Opus session and start a fresh Sonnet session to implement, instead of switching with an already-huge context.
