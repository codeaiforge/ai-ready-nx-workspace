# Workflow: Standard Tier Pipeline

6-phase pipeline for changes the gate tiers `T1` or `T2`. Adds Design and Test phases over Light tier.

## Selected by

**Evidence tier `T1` or `T2`.** The tier is computed by `sdlc-controls` and read from the
pull request's evidence record — it is not declared here, and not inferred from story
points. See [docs/sdlc-controls-integration.md](../../docs/sdlc-controls-integration.md).

| Emitted tier | Pipeline                  | Required by the tier                          |
| ------------ | ------------------------- | --------------------------------------------- |
| `T1`         | the six phases below      | 1 approver; lint, sast                        |
| `T2`         | the six phases **+ ⑥ Security** | owning-team reviewer; lint, sast, secrets, deps |

`T2` adds Phase ⑥ because the tier itself demands secrets and dependency scanning — the
work Phase ⑥ does. It is the same pipeline otherwise.

- **Typical tasks**: Database migration, API endpoint, feature slice, CI pipeline, database library
- **Phase count**: 6 (`T1`), 7 (`T2`)
- **Story points**: a planning estimate for effort. They do not select this pipeline.

## Escalation

The gate escalates for blast radius — a `critical` component, a shared library, breadth,
an undeclared path. If it emits `T3`, run [tier-complex.md](tier-complex.md).

One escalation stays independent of the tier: any task touching **authentication,
authorization, database or AI** runs Phase ⑥ Security regardless of the emitted tier.
Where the two disagree, take the stricter.

## Pipeline

```
① ANALYZE → ② DESIGN → ③ IMPLEMENT → ④ REVIEW → ⑤ TEST → ⑧ VERIFY
```

### ① Analyze

- **Agent**: Business Analyst
- **Process**: Resolve requirements trace, check dependencies, confirm Standard tier, pull relevant ADR context
- **Output**: Task Brief
- **Gate**: Task Brief reviewed; dependencies confirmed

### ② Design

- **Agent**: Architect + co-designer by layer (see [task-pipeline.md](task-pipeline.md))
- **Input**: Task Brief
- **Process**: Define approach, file plan, interfaces, Nx boundary check, risk assessment, test strategy
- **Output**: Design Spec
- **Gate**: Auto-proceed unless architectural risk flagged (new pattern or boundary change)

### ③ Implement

- **Agent**: Routed by layer
- **Input**: Design Spec
- **Process**: Scaffold with `nx g`, build, write unit tests for non-trivial logic, run lint + test, commit
- **Gate**: `{package-manager} nx affected -t lint,test,build` passes; implementation matches Design Spec

### ④ Review

- **Agent**: Code Reviewer + 0-1 specialist reviewer (conditional)
- **Depth**: Standard review — 5 dimensions (correctness, security, maintainability, performance, architecture)
- **Gate**: Zero Blockers; CI green after fixes

### ⑤ Test

- **Agent**: QA Engineer
- **Input**: Implemented and reviewed code
- **Process**: Verify coverage meets Design Spec expectations, domain-specific validation, run affected test suite
- **Output**: Test Report
- **Gate**: All acceptance criteria verified; CI green; no a11y blockers

### ⑧ Verify

- **Agent**: Business Analyst + QA Engineer (smoke test)
- **Depth**: Full acceptance criteria verification + user flow smoke test
- **Gate**: All acceptance criteria pass on deployed environment

## Deployment

Standard tier tasks are deployed in batches (per wave or per iteration), not individually.

## Prompt Templates

Use [prompts/analyze-task.md](../prompts/analyze-task.md), [prompts/design-spec.md](../prompts/design-spec.md), [prompts/implement.md](../prompts/implement.md), [prompts/review-code.md](../prompts/review-code.md), [prompts/test-feature.md](../prompts/test-feature.md), [prompts/verify-acceptance.md](../prompts/verify-acceptance.md).
