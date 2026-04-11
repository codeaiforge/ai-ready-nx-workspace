# Workflow: Light Tier Pipeline

4-phase pipeline for low-risk tasks (1-2 SP). Minimal ceremony — skip Design, Test, Security, and Deploy phases.

## Classification

- **Story Points**: 1-2 SP
- **Typical tasks**: Schema definition, barrel export, config file, simple component, type definition, documentation update
- **Phase count**: 4

## Override Rules

Tasks matching these criteria should be upgraded to Standard even if 1-2 SP:

- Touches authentication or authorization logic
- Has compliance/regulatory requirements (GDPR, HIPAA, SOC2, etc.)
- Flagged as a risk item in the roadmap
- Part of a hardening/stabilization iteration

## Pipeline

```
① ANALYZE → ③ IMPLEMENT → ④ REVIEW → ⑧ VERIFY
```

### ① Analyze

- **Agent**: Business Analyst
- **Process**: Resolve requirements trace, check dependencies, confirm Light tier classification
- **Output**: Task Brief
- **Gate**: Task Brief reviewed; dependencies confirmed

### ③ Implement

- **Agent**: Routed by layer (see [task-pipeline.md](task-pipeline.md))
- **Input**: Task Brief (no Design Spec — Light tier skips Phase ②)
- **Process**: Scaffold with `nx g`, build, write minimal co-located tests (contract validation), run lint + test, commit
- **Test scope**: Minimal — schema validates, export resolves, component renders
- **Gate**: `{package-manager} nx affected -t lint,test,build` passes

### ④ Review

- **Agent**: Code Reviewer only (no specialist reviewers for Light tier)
- **Depth**: Quick pass — correctness + boundary compliance
- **Gate**: Zero Blockers

### ⑧ Verify

- **Agent**: Business Analyst
- **Depth**: Acceptance criteria spot check against deployed preview
- **Gate**: All acceptance criteria pass

## Deployment

Light tier tasks are deployed in batches (per wave or per iteration), not individually. DevOps handles batch deployment during wave transitions or iteration review.

## Prompt Templates

Use [prompts/analyze-task.md](../prompts/analyze-task.md) for Phase ①, [prompts/implement.md](../prompts/implement.md) for Phase ③, [prompts/review-code.md](../prompts/review-code.md) for Phase ④, [prompts/verify-acceptance.md](../prompts/verify-acceptance.md) for Phase ⑧.
