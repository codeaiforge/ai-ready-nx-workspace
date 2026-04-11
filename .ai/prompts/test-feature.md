# Prompt: Test Feature (Phase ⑤)

## Purpose

Validate that the feature works correctly beyond what unit tests cover — integration, accessibility, performance, acceptance.

## Tiers

Standard and Complex only. Light tier tests are co-located in Phase ③.

## Composition Blocks

| Block | Source |
| ----- | ------ |
| ① Role Identity | `roles/qa.md` |
| ② Task Template | `tasks/run-tests.md` |
| ③ Standards | `standards/testing.md` |
| ④ Iteration Context | Roadmap section + task row |
| ⑤ Input Artifacts | Implemented and reviewed code + Design Spec test strategy |
| ⑥ Output Format | Test Report template below |

## Phase Instructions

1. Verify test coverage meets expectations from Design Spec
2. Domain-specific validation:
   - **Frontend**: accessibility audit (keyboard nav, aria labels, color independence, focus management)
   - **API**: integration test with real or local database
   - **Database**: migration rollback test, access policy verification
   - **Auth**: session management, token handling, permission boundaries
3. Run full affected test suite: `{package-manager} nx affected -t test`
4. For Complex tier: exploratory testing against acceptance criteria
5. For release iterations: E2E tests for critical user paths

## Output Format — Test Report

```markdown
## Test Report: {task_id} — {task_name}

### Test Coverage
| Type | Count Added | Coverage |
| ---- | ----------- | -------- |
| Unit | {n} | {x}% |
| Integration | {n} | — |
| E2E | {n} | — |

### Accessibility (if frontend)
- [ ] Keyboard navigable
- [ ] Screen reader compatible
- [ ] Color-independent indicators
- [ ] Focus management correct

### Performance (if applicable)
- {metric_1}: {value} (target: {target})
- {metric_2}: {value} (target: {target})

### Acceptance Criteria Verification
- [ ] {criterion_1}
- [ ] {criterion_2}

### Result: {Pass | Fail}
### Failure Details: {if fail — what broke, reproduction steps}
```

## Quality Gate

- All acceptance criteria verified
- CI green (`{package-manager} nx affected -t test`)
- No accessibility blockers
- Performance within NFR targets
