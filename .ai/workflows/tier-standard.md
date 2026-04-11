# Workflow: Standard Tier Pipeline

6-phase pipeline for moderate-risk tasks (3 SP). Adds Design and Test phases over Light tier.

## Classification

- **Story Points**: 3 SP
- **Typical tasks**: Database migration, API endpoint, feature slice, CI pipeline, data-access library
- **Phase count**: 6

## Override Rules

Tasks matching these criteria are upgraded to Complex:

- SP >= 5
- Flagged as a risk item in the roadmap and SP >= 3

Tasks matching these criteria are upgraded to Standard (from Light):

- Touches authentication or authorization logic
- Has compliance/regulatory requirements
- Part of a hardening/stabilization iteration

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
