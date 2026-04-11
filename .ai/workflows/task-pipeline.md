# Workflow: Task Pipeline

Defines the 8-phase SDLC pipeline that every task flows through. The tier classification determines which phases are active.

## Phases

| # | Phase | Purpose | Lead Agent | Output Artifact |
| - | ----- | ------- | ---------- | --------------- |
| ① | Analyze | Understand what to build, resolve ambiguity | Business Analyst | Task Brief |
| ② | Design | Define how to build it — files, interfaces, data flow | Architect + specialist | Design Spec |
| ③ | Implement | Write code, tests, documentation | Specialist by layer | Committed code |
| ④ | Review | Verify correctness, security, maintainability | Code Reviewer + specialists | Review Report |
| ⑤ | Test | Validate beyond unit tests — integration, a11y, perf | QA Engineer | Test Report |
| ⑥ | Security | Dedicated threat analysis for high-risk tasks | Security Engineer | Security Assessment |
| ⑦ | Deploy | Ship to verifiable environment | DevOps Engineer | Deployment confirmation |
| ⑧ | Verify | Confirm acceptance criteria met on deployed feature | Business Analyst | Acceptance Sign-off |

## Phase Flow Rules

- Each phase consumes the output artifact of the previous phase
- A phase cannot start until its predecessor's quality gate passes
- On review blocker: fix in Phase ③, re-enter Phase ④
- On test failure: fix in Phase ③, re-enter Phase ⑤
- Tier determines which phases are active (see tier files)

## Quality Gates

| Phase | Gate Condition |
| ----- | -------------- |
| ① Analyze | Task Brief reviewed by human; ambiguities resolved; dependencies confirmed |
| ② Design | Complex: human approval required. Standard: auto-proceed unless architectural risk flagged |
| ③ Implement | `{package-manager} nx affected -t lint,test,build` passes; implementation matches Design Spec |
| ④ Review | Zero Blockers remaining; CI still green after fixes |
| ⑤ Test | All acceptance criteria verified; CI green; no a11y blockers |
| ⑥ Security | No Critical or High findings; Medium findings documented with mitigation |
| ⑦ Deploy | Preview/staging environment serves feature; CI green on merge |
| ⑧ Verify | All acceptance criteria pass on deployed environment |

## Agent Routing by Layer

Customize this matrix based on your workspace's Nx `scope:*` tags. The `layer` column represents the primary domain a task touches.

| Phase | `shared` | `frontend` | `data-access` | `auth` | `api` | `infra`/`ci` | `testing` |
| ----- | -------- | ---------- | ------------- | ------ | ----- | ------------ | --------- |
| ① | BA | BA | BA | BA | BA | BA | BA |
| ② | Arch | Arch+Impl | Arch+DBE | Arch+Sec | Arch | Arch+DevOps | Arch+QA |
| ③ | Impl | Impl | DBE | Impl+Sec | Impl | DevOps | QA |
| ④ | Rev | Rev | Rev+Sec | Rev+Sec | Rev | Rev | Rev |
| ⑤ | QA | QA | QA | QA | QA | QA | QA |
| ⑥ | — | — | Sec | Sec | — | — | — |
| ⑦ | DevOps | DevOps | DevOps | DevOps | DevOps | DevOps | DevOps |
| ⑧ | BA | BA | BA | BA | BA | BA | BA |

**Legend**: BA=Business Analyst, Arch=Architect, Impl=Implementer, DBE=Database Engineer, Rev=Code Reviewer, Sec=Security Engineer, QA=QA Engineer, DevOps=DevOps Engineer

## References

- [tier-light.md](tier-light.md) / [tier-standard.md](tier-standard.md) / [tier-complex.md](tier-complex.md)
- [prompts/](../prompts/) — phase prompt templates
