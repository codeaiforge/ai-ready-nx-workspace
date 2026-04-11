# Workflow: Complex Tier Pipeline

Full 8-phase pipeline for high-risk tasks (5-8 SP). All phases active including dedicated Security review and per-task Deploy.

## Classification

- **Story Points**: 5-8 SP
- **Typical tasks**: OAuth/SSO setup, AI/ML pipeline, real-time/streaming architecture, compliance features, cross-cutting infrastructure changes
- **Phase count**: 8

## Override Rules

Tasks matching these criteria are treated as Complex regardless of SP:

- Touches multiple high-risk layers simultaneously (e.g., auth + data-access + external API)
- Flagged as a risk item with SP >= 3

## Pipeline

```
① ANALYZE → ② DESIGN → ③ IMPLEMENT → ④ REVIEW → ⑤ TEST → ⑥ SECURITY → ⑦ DEPLOY → ⑧ VERIFY
```

### ① Analyze

- **Agent**: Business Analyst + Architect (consulted)
- **Process**: Resolve requirements trace, check dependencies, pull architectural constraints from ADRs, flag ambiguity
- **Output**: Task Brief with Complexity Notes section
- **Gate**: Task Brief reviewed by human; ambiguities resolved

### ② Design

- **Agent**: Architect + specialist co-designer by layer
- **Input**: Task Brief
- **Process**: Define approach, file plan, interfaces, data flow (Mermaid sequence diagram), Nx boundary check, ADR assessment, risk matrix, test strategy
- **Output**: Design Spec
- **Gate**: Design Spec reviewed and approved by human before implementation

### ③ Implement

- **Agent**: Routed by layer
- **Input**: Design Spec
- **Process**: Scaffold with `nx g`, build, write unit + integration tests, run lint + test, domain-specific checks, commit
- **Gate**: `{package-manager} nx affected -t lint,test,build` passes; implementation matches Design Spec

### ④ Review

- **Agent**: Code Reviewer + 1-2 specialist reviewers
- **Depth**: Deep review — all 5 dimensions + domain expertise
- **Additional reviewers**: Security Engineer (if auth/data-access), Architect (if SP >= 5 or new boundary pattern)
- **Gate**: Zero Blockers; CI green after fixes

### ⑤ Test

- **Agent**: QA Engineer
- **Input**: Implemented and reviewed code
- **Process**: Verify coverage, domain-specific validation, run full affected test suite, exploratory testing against acceptance criteria
- **Output**: Test Report
- **Gate**: All acceptance criteria verified; CI green

### ⑥ Security

- **Agent**: Security Engineer
- **Input**: Implemented code + Test Report
- **Process**: Threat model, OWASP Top 10 audit, domain-specific checks, dependency audit (`{package-manager} audit`)
- **Output**: Security Assessment
- **Gate**: No Critical or High findings; Medium findings documented with mitigation timeline

### ⑦ Deploy

- **Agent**: DevOps Engineer
- **Input**: Approved, tested, secure code
- **Process**: Merge to feature branch, CI pipeline (lint → typecheck → test → build), deploy to preview/staging, verify deployment
- **Gate**: Preview/staging URL serves feature; CI green on merge

### ⑧ Verify

- **Agent**: Business Analyst + QA Engineer
- **Depth**: Full acceptance criteria verification + user flow test + regression check on dependent features
- **Gate**: All acceptance criteria pass on deployed environment

## Prompt Templates

All 7 phase prompts from [prompts/](../prompts/) are used. See [prompts/security-assess.md](../prompts/security-assess.md) for the Phase ⑥ template unique to this tier.
