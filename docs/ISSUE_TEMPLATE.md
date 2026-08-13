# Refined issue template

Structure an issue should have after going through `/refine-issue`.

```markdown
**Epic / parent**: #<n> — the epic this issue is a child of. Omit if standalone. (See `workflow/epics.md`.)

## Goal
What problem it solves and for whom. One or two sentences.

## Scope
- In: ...
- NOT in: ...

## Expected behavior
- Normal case: ...
- Edge cases: ...
- Errors: ...

## Data
Inputs, outputs, what's persisted.

## Dependencies
Issues that block or are blocked by this one. External services.

## Acceptance criteria
- [ ] ...
- [ ] ...

## Non-functional notes
Performance, security, permissions, limits. (Omit if not applicable.)

## Assumptions
Decisions made to resolve ambiguity that the user did not state explicitly — e.g. judgment calls proposed and confirmed during refinement. Keep them here so the implementer and reviewer can distinguish what was agreed from what was originally required. Also reflect every decision that affects scope, observable behavior, data, or completion in the corresponding section and, when testable, in Acceptance criteria. This section records provenance; it does not replace implementable requirements. (Omit if there were none.)

## Deferred decisions
Things we decided NOT to do now and why.
```

Not all fields apply to all issues. Omitting the ones that don't apply is correct; leaving a field empty "to complete the template" is not.
