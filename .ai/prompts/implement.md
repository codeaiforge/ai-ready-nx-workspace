# Prompt: Implement (Phase ③)

## Purpose

Write the code, tests, and documentation that deliver the task.

## Tiers

All tiers. Input and test depth vary by tier.

## Composition Blocks

| Block | Source |
| ----- | ------ |
| ① Role Identity | Specialist by layer (see routing below) |
| ② Task Template | `tasks/implement-feature.md` |
| ③ Standards | `standards/coding.md`, `standards/testing.md` |
| ④ Iteration Context | Roadmap section + task row |
| ⑤ Input Artifacts | Light: Task Brief. Standard/Complex: Design Spec |
| ⑥ Output Format | Committed code + passing CI |

### Agent Routing by Layer

| Task Layer | Primary Agent | Support Agent |
| ---------- | ------------- | ------------- |
| `shared` | Implementer | — |
| `frontend` | Implementer | — |
| `data-access` | Database Engineer | — |
| `api` | Implementer | — |
| `auth` | Implementer | Security Engineer (advisory) |
| `infra`, `ci` | DevOps Engineer | — |
| `testing` | QA Engineer | — |

Add additional layer mappings for your project's domain-specific concerns.

## Phase Instructions

1. **Scaffold** — Use `{package-manager} nx g` for new files/projects where applicable
2. **Build** — Implement code following the Design Spec file plan (or Task Brief for Light tier)
3. **Test** — Write co-located tests at depth matching the tier:
   - Light: minimal — contract validation (schema validates, export resolves)
   - Standard: unit tests for non-trivial logic
   - Complex: unit + integration tests
4. **Validate** — Run `{package-manager} nx lint` and `{package-manager} nx test` on affected projects
5. **Domain-specific checks**:
   - Database: run migration locally, verify schema state
   - Frontend: verify component hierarchy compliance, check barrel exports
   - API: verify endpoint contracts against schema
6. **Commit** — Conventional commit message following `{commit-conventions-doc}`

## Quality Gate

- `{package-manager} nx affected -t lint,test,build` passes
- Implementation matches Design Spec file plan (Standard/Complex) or Task Brief acceptance criteria (Light)
- No secrets committed, no hardcoded configuration
- Conventional commit message
