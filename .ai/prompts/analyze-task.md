# Prompt: Analyze Task (Phase ①)

## Purpose

Understand exactly what needs to be built. Resolve ambiguity before any code is written.

## Composition Blocks

| Block | Source |
| ----- | ------ |
| ① Role Identity | `roles/business-analyst.md` |
| ② Task Template | — (phase-specific instructions below) |
| ③ Standards | — |
| ④ Iteration Context | Roadmap section + task row |
| ⑤ Input Artifacts | Requirements doc (`{requirements-doc}`) |
| ⑥ Output Format | Task Brief template below |

For Complex tier, also consult `roles/architect.md` for architectural constraints.

## Phase Instructions

1. Resolve the task's requirements trace to specific requirement IDs and pull their full text from `{requirements-doc}`
2. Check dependency satisfaction — are all prerequisite tasks complete?
3. Classify the task into a tier (Light / Standard / Complex) based on SP + layer + override rules from `workflows/tier-*.md`
4. For Complex tier: pull architectural constraints from ADRs (`docs/adr/`)
5. Flag any ambiguity, missing information, or unresolvable dependencies
6. Convert acceptance criteria into checkable items

## Output Format — Task Brief

```markdown
## Task Brief: {task_id} — {task_name}

### Iteration Context
- Iteration: {N} — {theme}
- Iteration Goal: {goal statement}
- Wave: {wave_number} in execution plan

### Requirements Trace
- {REQ-x.x}: "{full requirement text}"

### Acceptance Criteria
- [ ] {criterion_1}
- [ ] {criterion_2}

### Constraints
- Layer: {layer}
- Priority: {Must|Should|Could}
- Nx scope tags involved: {scope:*, type:*}
- Dependencies satisfied: {yes | no — {blocking_task_ids}}

### Tier Classification: {Light | Standard | Complex}
### Complexity Notes: {for Complex — what makes this hard, what risks exist}
```

## Quality Gate

- Task Brief reviewed by human
- Ambiguities resolved before proceeding
- Dependencies confirmed satisfied
- Tier classification validated against override rules
