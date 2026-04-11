# Workflow: Decision Gates

Pipeline interrupts at iteration boundaries that pause automation and require human go/no-go decisions. Agents prepare the evaluation; humans make the call.

## Defining Your Gates

Every project should define 2-4 decision gates aligned to major milestones. Each gate needs:

1. **Purpose** — What decision is being made
2. **Evaluating agents** — Which roles prepare the assessment
3. **Signals** — Measurable criteria with go/no-go thresholds
4. **No-go actions** — Concrete steps if the gate fails

## Gate Template

```markdown
## Gate N: {Name} (End of Iteration {X})

**Purpose**: {What this gate validates}

**Evaluating agents**: {Role 1} + {Role 2} + {Role 3}

| Signal | Go | No-Go |
| ------ | -- | ----- |
| {Metric 1} | {Acceptable threshold} | {Unacceptable threshold} |
| {Metric 2} | {Acceptable threshold} | {Unacceptable threshold} |

**No-go actions**:
1. {Specific remediation step}
2. {Fallback plan}
```

## Example Gates

### Gate: Core Feature Complete

**Purpose**: Validate that the primary user workflow functions end-to-end before building secondary features.

| Signal | Go | No-Go |
| ------ | -- | ----- |
| Critical bugs | 0 critical, < 5 minor | Any critical or > 5 minor |
| Timeline | On schedule | > 1 week behind |
| Core workflow | End-to-end functional | Any step broken |

**No-go actions**: Redirect next iteration to bug fixes and stability. Defer secondary features.

### Gate: Release Readiness

**Purpose**: Confirm readiness to release to users.

**Evaluating agents**: Business Analyst + QA + Security + DevOps

| Signal | Go | No-Go |
| ------ | -- | ----- |
| Security | No Critical/High findings | Any Critical/High unresolved |
| Performance | Meets NFR targets | Key metrics out of range |
| Accessibility | WCAG 2.1 AA compliant | Blocking a11y issues |
| Test coverage | Meets team standards | Below minimum threshold |

**No-go actions**: Extend iteration for targeted fixes. Release with documented known issues if non-critical.

## Evaluation Process

1. Sprint Conductor triggers gate evaluation at iteration end
2. Evaluating agents produce their assessments independently
3. Assessments compiled into a Gate Report with go/no-go recommendation
4. Human reviews Gate Report and makes final decision
5. Decision recorded in retrospective
6. If no-go: Sprint Conductor executes the defined no-go actions

## References

- [sprint-conductor.md](sprint-conductor.md) — triggers and consumes gate decisions
- [roles/business-analyst.md](../roles/business-analyst.md) — Decision Gate Template
