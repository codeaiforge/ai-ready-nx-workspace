# Prompt: Review Code (Phase ④)

## Purpose

Verify correctness, security, maintainability, performance, and architectural compliance.

## Tiers

All tiers. Review depth and reviewer count vary by tier.

## Composition Blocks

| Block | Source |
| ----- | ------ |
| ① Role Identity | `roles/reviewer.md` + specialist(s) by condition |
| ② Task Template | `tasks/review-pr.md` |
| ③ Standards | `standards/review.md`, `standards/coding.md`, `standards/security.md` |
| ④ Iteration Context | Roadmap section + task row |
| ⑤ Input Artifacts | Git diff/changeset from Phase ③ + Design Spec (if exists) |
| ⑥ Output Format | Review Report template below |

### Reviewer Depth by Tier

| Tier | Reviewers | Depth |
| ---- | --------- | ----- |
| Light | Code Reviewer only | Quick pass — correctness + boundaries |
| Standard | Code Reviewer + 0-1 specialist | Standard review — 5 dimensions |
| Complex | Code Reviewer + 1-2 specialists | Deep review — all dimensions + domain expertise |

### Additional Reviewer Conditions

| Condition | Additional Reviewer |
| --------- | ------------------- |
| Task touches `auth` or `data-access` layer | Security Engineer |
| Task has compliance/regulatory requirements | Compliance Checker (if defined) |
| Task introduces new Nx boundary pattern | Architect |
| Task SP >= 5 (Complex tier) | Architect |

## Phase Instructions

1. Code Reviewer evaluates across 5 dimensions:
   - **Correctness**: Does it do what the Task Brief / Design Spec says?
   - **Security**: Input validation, no secrets, no injection surface?
   - **Maintainability**: Clear code, appropriate abstraction level, no dead code?
   - **Performance**: No N+1 queries, no unnecessary re-renders, efficient algorithms?
   - **Architecture**: Nx boundaries respected, layer direction correct, ADR adherence?
2. Classify each finding: **Blocker** (must fix) / **Suggestion** (should consider) / **Nit** (optional)
3. Specialist reviewers add domain-specific checks per their role definitions

## Output Format — Review Report

```markdown
## Review: {task_id} — {task_name}

### Reviewers
- Code Reviewer: {pass/changes_requested}
- {Specialist}: {pass/changes_requested}

### Blockers (must fix before merge)
- [ ] {issue} — `{file_path}:{line}` — {explanation}

### Suggestions (should consider)
- {improvement} — `{file_path}:{line}` — {rationale}

### Nits (optional, take or leave)
- {style item}

### Positive Observations
- {what was done well — specific praise}

### Verdict: {Approved | Changes Requested}
```

## Quality Gate

- Zero Blockers remaining
- All Blockers fixed and re-reviewed
- `{package-manager} nx affected -t lint,test,build` still green after fixes
