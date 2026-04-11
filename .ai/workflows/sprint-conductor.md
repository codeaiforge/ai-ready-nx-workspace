# Workflow: Sprint Conductor

Meta-agent that orchestrates the entire iteration lifecycle. Does not write code — sequences work, gates transitions, and tracks progress.

## Iteration Lifecycle

1. **Planning** — Generate Task Briefs for all iteration tasks, confirm tier classifications, validate execution wave order, identify cross-task risks
2. **Wave Execution** — For each wave: confirm dependencies met, launch parallel subagents per task, each runs tier-appropriate pipeline, wait for all to pass Verify, gate to next wave
3. **Iteration Review** — Full regression, security sweep, accessibility audit, Definition of Done verification, performance spot check
4. **Decision Gate** — If applicable: prepare gate evaluation, present to human for go/no-go
5. **Retrospective** — Update lessons, log velocity (actual vs plan), flag risks for next iteration, identify prompt improvements, tune agent definitions

## Wave Execution Rules

- Tasks within a wave have no mutual dependencies and execute in parallel
- Each subagent runs the full tier-appropriate pipeline independently
- Wave N+1 starts only after all Wave N tasks pass Phase ⑧ Verify
- On failure: the failing task is fixed and re-reviewed/re-tested; other wave tasks are not blocked

## Inputs

- Iteration section from `{roadmap-doc}`
- Execution waves and dependency graph
- Prior iteration's retrospective lessons (if not first iteration)

## Outputs

- Iteration backlog with tier classifications
- Per-wave progress tracking
- Iteration Review Report
- Gate evaluation (if applicable)
- Retrospective: lessons + velocity log

## Failure Handling

- **Blocked dependency**: flag to human, suggest reordering or descoping
- **Repeated review failures**: escalate to Architect for design review
- **Gate no-go**: execute defined no-go actions from `decision-gates.md`
- **Velocity shortfall**: propose scope reduction for remaining waves

## References

- [decision-gates.md](decision-gates.md)
- [task-pipeline.md](task-pipeline.md)
- [roles/business-analyst.md](../roles/business-analyst.md) — planning lead
- [standards/workflow.md](../standards/workflow.md)
