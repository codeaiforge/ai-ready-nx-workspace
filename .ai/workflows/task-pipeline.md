# Workflow: Task Pipeline

Defines the 8-phase SDLC pipeline that every task flows through. The emitted risk tier determines which phases are active.

## Tier authority

The tier is **computed, not declared**. `sdlc-controls` tiers each pull request `T0`-`T3`
from the change's blast radius and emits it in an `evidence/0` record; the pipeline reads
that record. Nobody on the change selects its own tier.

| Evidence tier | Pipeline                                        | Active phases   |
| ------------- | ----------------------------------------------- | --------------- |
| `T0`          | [Light](tier-light.md)                          | ① ③ ④ ⑧         |
| `T1`          | [Standard](tier-standard.md)                    | ① ② ③ ④ ⑤ ⑧     |
| `T2`          | [Standard](tier-standard.md) + Phase ⑥          | ① ② ③ ④ ⑤ ⑥ ⑧   |
| `T3`          | [Complex](tier-complex.md)                      | ① - ⑧           |

Story points size **effort**. They never measured **risk**, and using them as a risk
proxy is what let a one-point change to an authentication module travel the Light path.
Estimate in points; let the gate set the tier.

Phase ⑥ Security remains an independent escalation: any task touching authentication,
authorization, database or AI runs it whatever the gate emits. The gate reads paths, and
a change can be dangerous for reasons no path reveals. Take the stricter of the two.

How to read the tier, and what the gate does not claim:
[docs/sdlc-controls-integration.md](../../docs/sdlc-controls-integration.md).

## Phases

| #   | Phase     | Purpose                                               | Lead Agent                  | Output Artifact         |
| --- | --------- | ----------------------------------------------------- | --------------------------- | ----------------------- |
| ①   | Analyze   | Understand what to build, resolve ambiguity           | Business Analyst            | Task Brief              |
| ②   | Design    | Define how to build it — files, interfaces, data flow | Architect + specialist      | Design Spec             |
| ③   | Implement | Write code, tests, documentation                      | Specialist by layer         | Committed code          |
| ④   | Review    | Verify correctness, security, maintainability         | Code Reviewer + specialists | Review Report           |
| ⑤   | Test      | Validate beyond unit tests — integration, a11y, perf  | QA Engineer                 | Test Report             |
| ⑥   | Security  | Dedicated threat analysis for high-risk tasks         | Security Engineer           | Security Assessment     |
| ⑦   | Deploy    | Ship to verifiable environment                        | DevOps Engineer             | Deployment confirmation |
| ⑧   | Verify    | Confirm acceptance criteria met on deployed feature   | Business Analyst            | Acceptance Sign-off     |

## Phase Flow Rules

- Each phase consumes the output artifact of the previous phase
- A phase cannot start until its predecessor's quality gate passes
- On review blocker: fix in Phase ③, re-enter Phase ④
- On test failure: fix in Phase ③, re-enter Phase ⑤
- The emitted tier determines which phases are active (see the table above)

## Quality Gates

| Phase       | Gate Condition                                                                                |
| ----------- | --------------------------------------------------------------------------------------------- |
| ① Analyze   | Task Brief reviewed by human; ambiguities resolved; dependencies confirmed                    |
| ② Design    | Complex: human approval required. Standard: auto-proceed unless architectural risk flagged    |
| ③ Implement | `{package-manager} nx affected -t lint,test,build` passes; implementation matches Design Spec |
| ④ Review    | Zero Blockers remaining; CI still green after fixes                                           |
| ⑤ Test      | All acceptance criteria verified; CI green; no a11y blockers                                  |
| ⑥ Security  | No Critical or High findings; Medium findings documented with mitigation                      |
| ⑦ Deploy    | Preview/staging environment serves feature; CI green on merge                                 |
| ⑧ Verify    | All acceptance criteria pass on deployed environment                                          |

## Agent Routing by Layer

Customize this matrix based on your workspace's Nx `scope:*` tags. The `layer` column represents the primary domain a task touches.

| Phase | `monorepo` | `frontend` | `database` | `auth`   | `api`  | `infra`/`ci` | `testing` |
| ----- | ---------- | ---------- | ---------- | -------- | ------ | ------------ | --------- |
| ①     | BA         | BA         | BA         | BA       | BA     | BA           | BA        |
| ②     | Arch       | Arch+Impl  | Arch+DBE   | Arch+Sec | Arch   | Arch+DevOps  | Arch+QA   |
| ③     | Impl       | Impl       | DBE        | Impl+Sec | Impl   | DevOps       | QA        |
| ④     | Rev        | Rev        | Rev+Sec    | Rev+Sec  | Rev    | Rev          | Rev       |
| ⑤     | QA         | QA         | QA         | QA       | QA     | QA           | QA        |
| ⑥     | —          | —          | Sec        | Sec      | —      | —            | —         |
| ⑦     | DevOps     | DevOps     | DevOps     | DevOps   | DevOps | DevOps       | DevOps    |
| ⑧     | BA         | BA         | BA         | BA       | BA     | BA           | BA        |

**Legend**: BA=Business Analyst, Arch=Architect, Impl=Implementer, DBE=Database Engineer, Rev=Code Reviewer, Sec=Security Engineer, QA=QA Engineer, DevOps=DevOps Engineer

## References

- [tier-light.md](tier-light.md) / [tier-standard.md](tier-standard.md) / [tier-complex.md](tier-complex.md)
- [prompts/](../prompts/) — phase prompt templates
