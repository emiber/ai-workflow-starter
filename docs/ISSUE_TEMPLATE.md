# Refined issue template

Structure an issue should have after going through `/refine-issue`.

```markdown
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

## Deferred decisions
Things we decided NOT to do now and why.
```

Not all fields apply to all issues. Omitting the ones that don't apply is correct; leaving a field empty "to complete the template" is not.
