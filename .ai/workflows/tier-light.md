# Workflow: Light Tier Pipeline

4-phase pipeline for changes the gate tiers `T0`. Minimal ceremony — skip Design, Test, Security, and Deploy phases.

## Selected by

**Evidence tier `T0`** where the `sdlc-controls` gate is installed. The tier is computed
from the change's blast radius and read from the pull request's evidence record — not
declared here, and not inferred from story points. Without the gate there is no evidence
record: `run-task.prompt.md` classifies by story points instead, and this file is the
procedure for the class it picks.

<!-- gate-only:start -->

See [docs/sdlc-controls-integration.md](../../docs/sdlc-controls-integration.md).

<!-- gate-only:end -->

- **Emitted tier**: `T0` — every affected component is `criticality:low`, with no
  escalation for fan-in, breadth or unmatched paths
- **Required by the tier**: 1 approver, lint
- **Typical tasks**: Schema definition, barrel export, config file, simple component, type definition, documentation update
- **Phase count**: 4
- **Story points**: 1–2 SP. A planning estimate for effort. With the gate installed they do not select this pipeline; without it they are the only signal there is.

## Escalation

Tier escalation is the gate's job, and it happens for reasons this file does not
restate — a shared component, breadth, an undeclared path. If the gate emits anything
above `T0`, run the pipeline that tier selects.

One escalation stays independent of the tier: any task touching **authentication,
authorization, database or AI** runs Phase ⑥ Security regardless of the emitted tier. The
gate sees paths, and a change can be dangerous for reasons no path reveals. Where the two
disagree, take the stricter.

## Pipeline

```
① ANALYZE → ③ IMPLEMENT → ④ REVIEW → ⑧ VERIFY
```

### ① Analyze

- **Agent**: Business Analyst
- **Process**: Resolve requirements trace, check dependencies, estimate effort (the gate sets the tier)
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
