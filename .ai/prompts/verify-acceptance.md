# Prompt: Verify Acceptance (Phase ⑧)

## Purpose

Confirm the deployed feature meets its acceptance criteria and contributes to the iteration goal.

## Tiers

All tiers. Verification depth varies by tier.

## Composition Blocks

| Block | Source |
| ----- | ------ |
| ① Role Identity | `roles/business-analyst.md` |
| ② Task Template | — (phase-specific instructions below) |
| ③ Standards | — |
| ④ Iteration Context | Roadmap section + task row |
| ⑤ Input Artifacts | Deployed feature on preview/staging (or production) |
| ⑥ Output Format | Acceptance Sign-off template below |

### Verification Depth by Tier

| Tier | Depth | Support Agent |
| ---- | ----- | ------------- |
| Light | Acceptance criteria spot check against deployed preview | — |
| Standard | Full acceptance criteria verification + user flow smoke test | QA Engineer |
| Complex | Full acceptance criteria verification + user flow test + regression check on dependent features | QA Engineer |

## Phase Instructions

1. Verify each acceptance criterion against the live environment
2. QA runs smoke test of the affected user flow (Standard + Complex)
3. For Complex tier: regression check — verify dependent features still work
4. For iteration-final task: verify the Iteration Definition of Done (aggregate checklist)
5. Mark task status as complete
6. Update iteration progress tracking

## Output Format — Acceptance Sign-off

```markdown
## Acceptance: {task_id} — {task_name}

### Acceptance Criteria Verification
- [x] {criterion_1} — verified at {URL/evidence}
- [x] {criterion_2} — verified at {URL/evidence}

### Smoke Test: {Pass | Fail}
### Iteration DoD Impact: {which iteration DoD items this task satisfies}

### Sign-off: Accepted
```

## Quality Gate

- All acceptance criteria pass on deployed environment
- Iteration DoD progress updated
- Task marked complete in iteration tracking
