# Prompt: Design Spec (Phase ②)

## Purpose

Define *how* the task will be built — file paths, interfaces, data flow — before writing code.

## Tiers

Standard and Complex only. Light tier skips to Phase ③.

## Composition Blocks

| Block | Source |
| ----- | ------ |
| ① Role Identity | `roles/architect.md` + specialist by layer |
| ② Task Template | — (phase-specific instructions below) |
| ③ Standards | `standards/architecture.md`, `standards/nx-boundaries.md` |
| ④ Iteration Context | Roadmap section + task row |
| ⑤ Input Artifacts | Task Brief from Phase ① |
| ⑥ Output Format | Design Spec template below |

### Co-Designer by Layer

| Task Layer | Co-Designer | Role File |
| ---------- | ----------- | --------- |
| `data-access` | Database Engineer | `roles/database-engineer.md` |
| `frontend` | Implementer | `roles/implementer.md` |
| `auth`, `infra`, `ci` | DevOps Engineer | `roles/devops.md` |
| `api` | Architect solo | — |
| `testing` | QA Engineer | `roles/qa.md` |

Add additional specialist mappings for your project's domain-specific layers.

## Phase Instructions

1. Architect determines the minimal correct solution approach
2. Specialist co-designer validates domain-specific decisions
3. Confirm Nx boundary compliance — which `scope:*` and `type:*` tags are involved, verify no violations
4. For Complex tier: determine if an ADR is needed (new pattern, new dependency, new trade-off)
5. Identify risks and their mitigations
6. Define test strategy (what to test, where, fixtures needed)

## Output Format — Design Spec

```markdown
## Design Spec: {task_id} — {task_name}

### Approach
{1-3 paragraph description of how this will be built}

### Files to Create/Modify
| File | Action | Purpose |
| ---- | ------ | ------- |
| `{path}` | Create/Modify | {purpose} |

### Interfaces / Contracts
{TypeScript interfaces or schemas that define boundaries between components}

### Data Flow
{Mermaid sequence diagram showing how data moves through the system}

### Nx Boundary Verification
- Scope tags involved: {list}
- Cross-boundary imports: {list with justification}
- Violations: none

### ADR Required: {yes — ADR-NNN | no}

### Risks
| Risk | Likelihood | Mitigation |
| ---- | ---------- | ---------- |
| {risk} | {low/medium/high} | {mitigation} |

### Test Strategy
- Unit: {what to test, where}
- Integration: {what to test, where}
- Fixtures needed: {yes/no — description}
```

## Quality Gate

- **Complex tier**: Design Spec reviewed and approved by human before implementation
- **Standard tier**: Auto-proceed unless architectural risk flagged (new pattern or boundary change)
