# Prompt: Security Assessment (Phase ⑥)

## Purpose

Dedicated threat analysis for high-risk tasks — beyond the security dimension in code review.

## Tiers

Complex only, plus any task touching `auth` or `database` layers regardless of tier.

## Composition Blocks

| Block               | Source                                      |
| ------------------- | ------------------------------------------- |
| ① Role Identity     | `roles/security-engineer.md`                |
| ② Task Template     | — (phase-specific instructions below)       |
| ③ Standards         | `standards/security.md`                     |
| ④ Iteration Context | Roadmap section + task row                  |
| ⑤ Input Artifacts   | Implemented code + Test Report from Phase ⑤ |
| ⑥ Output Format     | Security Assessment template below          |

## Phase Instructions

1. **Threat model** — Identify attack surfaces introduced by this specific feature
2. **OWASP Top 10 audit** — Check changeset against relevant OWASP categories
3. **Auth-specific** (for `auth` layer):
   - Session management follows framework best practices (no custom session handling)
   - OAuth redirect URIs properly scoped
   - Token handling follows provider best practices
4. **Database-specific** (for `database` layer):
   - The stack's **Access control** mechanism covers every CRUD path to new table(s).
     Whether that is enforced in the database or in the application is a property of the
     stack — do not assume row-level security exists.
   - Cascade / delete behaviour verified (no orphaned data, no unauthorized access)
   - Application data access goes through the stack's **Data access** layer. Schema
     migrations are DDL and are expected to be SQL; this rule is about queries.
5. **API-specific** (for `api` layer):
   - Input validation on all endpoints
   - Rate limiting configured
   - No sensitive data in error responses
6. **Dependency audit**: `{package-manager} audit` — no known vulnerabilities in new dependencies

## Output Format — Security Assessment

```markdown
### Security Assessment: {task_id}

#### Threat Surface

- {surface_1}: {risk_level} — {mitigation}

#### OWASP Findings

- {category}: {finding or "not applicable"}

#### Access Policy Verification (if applicable)

- {table/resource}: {operation} — {policy_name} — {verified}

#### Dependency Audit

- New dependencies: {count}
- Known vulnerabilities: {count} ({severity})

#### Verdict: {Pass | Conditional Pass — {conditions} | Fail — {blockers}}
```

## Quality Gate

- No Critical or High findings
- Medium findings documented with mitigation timeline
- All access policies verified (if database layer)
- `{package-manager} audit` clean or findings acknowledged
