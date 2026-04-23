---
description: Execute a single roadmap task through its tier-appropriate SDLC pipeline (Light 4-phase / Standard 6-phase / Complex 8-phase). Provide the task ID as argument (e.g., 0.7, 1.4, 2.5).
argument-hint: '<task-id>'
agent: agent
---

# Task Pipeline — Agent Orchestrator

Execute the target roadmap task through its full tier-appropriate SDLC pipeline. Each phase has a lead role, a prompt guide, and a quality gate that must pass before advancing.

Use TodoWrite to track phase progress throughout.

---

## Step 1 — Load Task

Read `docs/specs/implementation-roadmap.md` and find the task row matching the target task ID. Extract:

| Field | Source Column |
| ----- | ------------ |
| Task ID | # |
| Name | Task |
| Story Points | SP |
| Priority | Priority (Must / Should / Could) |
| Layer | Layer |
| Dependencies | Depends on |
| Requirements Trace | Trace |
| Acceptance Criteria | Done when |
| Sprint Number | Section header |
| Wave Number | Execution waves table |

Also read `docs/specs/mvp-requirements.md` to resolve the Trace column to full requirement text.

### Load Lessons Learned

Read all existing task output files in `.ai/sprints/sprint-{N}/tasks/*.md` (where N is the target sprint). For each file, extract the **Human Interventions** section and compile a list of lessons. These lessons are corrections from prior task executions and **must** be applied during this task's pipeline — repeating a previously corrected mistake is a pipeline failure.

If this is not Sprint 0, also read `.ai/sprints/sprint-{N-1}/retrospective.md` for cross-sprint lessons.

If no prior task outputs exist, proceed without lessons.

---

## Step 2 — Classify Tier

| SP | Tier | Pipeline |
| -- | ---- | -------- |
| 1–2 | Light | ① → ③ → ④ → ⑧ |
| 3 | Standard | ① → ② → ③ → ④ → ⑤ → ⑧ |
| 5–8 | Complex | ① → ② → ③ → ④ → ⑤ → ⑥ → ⑦ → ⑧ |

**Override rules** — upgrade to next tier minimum when:

- Layer is `auth` or task involves security-sensitive logic
- Trace includes `NFR-6.*` (GDPR/compliance)
- Flagged as sprint risk in the roadmap
- Sprint 6 hardening task

Read the matching tier workflow:

- Light: `.ai/workflows/tier-light.md`
- Standard: `.ai/workflows/tier-standard.md`
- Complex: `.ai/workflows/tier-complex.md`

Also read `.ai/workflows/task-pipeline.md` for phase definitions and the agent routing matrix.

---

## Step 3 — Create Feature Branch

Read `.github/git-workflow.md` for branching conventions, including the **Commit Checkpoint** rule: the agent never runs `git add`/`git commit` on the changeset — it presents a plan and the human commits. This rule applies at every phase where work lands on the branch (Phase ③ initial commit, Phase ④ blocker fixes, Phase ⑧ any verification tweaks).

Create a feature branch from `main`:

```bash
git checkout main && git pull origin main
git checkout -b <type>/<sprint>.<task>-<slug>
```

Use the task's layer to determine the `<type>` (e.g., `feat` for new functionality, `chore` for infra/ci, `docs` for documentation). Use the task ID for `<sprint>.<task>` and derive a short slug from the task name.

---

## Step 4 — Check Dependencies

Verify every entry in the task's `Depends on` column is complete:

- Check git log and existing code for evidence of prior task completion
- Verify expected artifacts exist (files, schemas, routes, tables)

If any dependency is unmet: **STOP** — report exactly which task(s) must complete first and what evidence is missing.

---

## Step 5 — Execute Pipeline

### Agent model by tier

| Tier | Execution model |
| ---- | --------------- |
| Light (1–2 SP) | **Single agent** — run all phases inline, reading each role file to shift perspective |
| Standard (3 SP) | **Sub-agent per phase** — spawn a dedicated agent for each active phase via the Agent tool |
| Complex (5–8 SP) | **Sub-agent per phase** — spawn a dedicated agent for each active phase via the Agent tool |

**Single-agent phases** (Light tier): Read the role file, execute the phase, check the gate, then move on to the next phase within the same conversation context.

**Sub-agent phases** (Standard/Complex tiers): For each active phase, spawn a sub-agent with a prompt that includes:

1. The role file path and guide file path to read
2. The Task Brief (and Design Spec if produced)
3. The phase-specific instructions from this prompt
4. The quality gate criteria
5. Any prior phase artifacts the sub-agent needs as input

The orchestrator (this agent) passes artifacts between sub-agents and checks each gate before spawning the next phase. On gate failure, re-spawn the sub-agent with the failure context and remediation instructions.

---

### Phase ① — Analyze

> All tiers

**Role**: `.ai/roles/business-analyst.md`
**Guide**: `.ai/prompts/analyze-task.md`

1. Resolve the Trace column to full EARS requirement text from `docs/specs/mvp-requirements.md`
2. Convert "Done when" into specific, testable acceptance criteria
3. Confirm tier classification against override rules
4. For Complex tier: pull architectural constraints from `docs/architecture/` ADRs
5. Identify ambiguities, missing information, or risks
6. Determine Nx scope tags involved and verify boundary implications

**Output**: Task Brief — use the format defined in `.ai/prompts/analyze-task.md`

**Quality Gate**: Present the Task Brief.

**PAUSE — Wait for human confirmation before proceeding.**

---

### Phase ② — Design

> Standard + Complex only. Light tier skips to Phase ③.

**Role**: `.ai/roles/architect.md` + layer co-designer (see table in `.ai/prompts/design-spec.md`)
**Guide**: `.ai/prompts/design-spec.md`

1. Read the Task Brief from Phase ①
2. Consult `docs/architecture/` for relevant ADRs and design patterns
3. Read `.ai/standards/architecture.md` and `.ai/standards/nx-boundaries.md`
4. Identify all files to create or modify — with full paths
5. Define interfaces, Zod schemas, or contracts at component boundaries
6. Map data flow (consider a Mermaid sequence diagram for Complex tier)
7. Verify Nx boundary compliance — which `scope:*` tags are involved
8. Define test strategy (what to test, where, fixtures needed)
9. For Complex tier: determine if an ADR is needed (new pattern, new dependency, new trade-off)

**Output**: Design Spec — use the format defined in `.ai/prompts/design-spec.md`

**Quality Gate**:

- **Complex tier**: **PAUSE — Present Design Spec for human approval**
- **Standard tier**: auto-proceed unless architectural risk is flagged (new pattern or boundary change)

---

### Phase ③ — Implement

> All tiers

**Role**: Route by layer per the agent routing matrix in `.ai/workflows/task-pipeline.md`. Read the matching role file from `.ai/roles/`:

| Layer | Primary Role File |
| ----- | ----------------- |
| `monorepo`, `frontend`, `api`, `auth` | `roles/implementer.md` |
| `database` | `roles/database-engineer.md` |
| `ai` | `roles/ai-engineer.md` |
| `infra`, `ci` | `roles/devops.md` |
| `testing` | `roles/qa.md` |

For `auth` layer, also consult `roles/security-engineer.md` in an advisory capacity.

**Guide**: `.ai/prompts/implement.md`
**Standards**: `.ai/standards/coding.md`, `.ai/standards/testing.md`

**Input**: Task Brief (Light tier) or Design Spec (Standard/Complex tier)

1. **Read first** — read all relevant existing source files before changing anything
2. **Scaffold** — use `pnpm nx g` for new files/projects where applicable
3. **Build** — implement following the spec. Respect:
   - `.ai/standards/coding.md` for code conventions
   - `.ai/standards/nx-boundaries.md` for module boundaries
   - FSD layer structure for frontend components
4. **Test** — write co-located tests at tier-appropriate depth:
   - **Light**: minimal — contract validation (Zod schema validates, export resolves, component renders)
   - **Standard**: unit tests for all non-trivial logic
   - **Complex**: unit + integration tests; fixture-based tests for AI pipelines
5. **Domain-specific checks**:
   - AI pipelines: test against reference fixtures in `__fixtures__/`, verify schema conformance
   - Database: run migration locally, verify with `supabase status`
   - Frontend: verify FSD layer compliance, check barrel exports
6. **Validate** — run `pnpm nx affected -t lint,test,build`

**Quality Gate**: `pnpm nx affected -t lint,test,build` must pass.

If the gate fails:

1. Read the error output carefully
2. Fix the issues
3. Re-run the gate
4. Repeat until green — do not proceed with failures

**Commit Checkpoint**: Once the gate is green, present a commit plan (file groups + Conventional Commit messages) and wait for the human to commit. Do not run `git add` / `git commit` yourself. See `.github/git-workflow.md` → Commit Checkpoint.

---

### Phase ④ — Review

> All tiers. Depth varies by tier.

**Role**: `.ai/roles/reviewer.md`
**Guide**: `.ai/prompts/review-code.md`
**Standards**: `.ai/standards/review.md`, `.ai/standards/coding.md`, `.ai/standards/security.md`

**Additional reviewers by condition** (read their role files and apply their perspective):

| Condition | Additional Role |
| --------- | --------------- |
| Task touches `auth` or `database` layer | `.ai/roles/security-engineer.md` |
| Task has `NFR-6.*` trace (GDPR) | `.ai/roles/compliance.md` |
| Task introduces new Nx boundary pattern | `.ai/roles/architect.md` |
| Task SP >= 5 (Complex tier) | `.ai/roles/architect.md` |
| Task touches AI pipeline | `.ai/roles/ai-engineer.md` |

**Review depth by tier**:

| Tier | Depth |
| ---- | ----- |
| Light | Quick pass — correctness + boundary compliance |
| Standard | Full review — 5 dimensions (correctness, security, maintainability, performance, architecture) |
| Complex | Deep review — all dimensions + domain expertise from specialist reviewers |

1. Review all changes from Phase ③ against the Task Brief / Design Spec
2. Evaluate across the 5 dimensions defined in `.ai/prompts/review-code.md`
3. Classify each finding: **Blocker** (must fix) / **Suggestion** (should consider) / **Nit** (optional)

**Output**: Review Report — use the format defined in `.ai/prompts/review-code.md`

**Quality Gate**: Zero Blockers remaining. `pnpm nx affected -t lint,test,build` still green after any fixes.

**On Blockers**:

1. Fix the issues (return to Phase ③ implementation)
2. Re-enter Phase ④ (re-review the fixes)
3. Maximum 3 review cycles — if still blocked after 3, escalate to user with the pattern of recurring issues

Each blocker-fix round is a separate commit — present a fresh commit plan and wait for the human to commit before re-entering review. See `.github/git-workflow.md` → Commit Checkpoint.

---

### Phase ⑤ — Test

> Standard + Complex only. Light tier tests are co-located in Phase ③.

**Role**: `.ai/roles/qa.md`
**Guide**: `.ai/prompts/test-feature.md`
**Standards**: `.ai/standards/testing.md`

1. Verify test coverage meets expectations from the Design Spec test strategy
2. Domain-specific validation:
   - **AI pipeline**: run against reference fixtures, check schema conformance rate (target >95%), test failure modes and fallback behavior
   - **Frontend**: accessibility audit — keyboard navigation, aria labels, color independence, focus management
   - **API**: integration test with local Supabase
   - **Database**: migration rollback test, RLS policy verification
3. Run `pnpm nx affected -t test`
4. For Complex tier: exploratory testing against acceptance criteria

**Output**: Test Report — use the format defined in `.ai/prompts/test-feature.md`

**Quality Gate**: All acceptance criteria verified. CI green. No accessibility blockers.

**On failure**:

1. Fix in Phase ③
2. Re-enter Phase ⑤
3. Maximum 3 test cycles — escalate if recurring

---

### Phase ⑥ — Security

> Complex only, plus any task touching `auth`, `database`, or `ai` layers regardless of tier.

**Role**: `.ai/roles/security-engineer.md` (+ `.ai/roles/compliance.md` if task has `NFR-6.*` trace)
**Guide**: `.ai/prompts/security-assess.md`
**Standards**: `.ai/standards/security.md`

1. **Threat model** — identify attack surfaces introduced by this feature
2. **OWASP Top 10** — check changeset against relevant categories
3. **AI-specific** (for `ai` layer):
   - Prompt injection surface analysis
   - Output validation via Zod schema
   - Data leakage in system prompts or logs
4. **Database-specific** (for `database` layer):
   - RLS policy covers all CRUD operations for new tables
   - Cascade delete behavior verified
   - All queries through Drizzle ORM (no raw SQL)
5. **Auth-specific** (for `auth` layer):
   - Session management is Supabase-native
   - OAuth redirect URIs scoped correctly
   - Token handling follows Supabase best practices
6. **Dependency audit**: run `pnpm audit` — no known vulnerabilities in new dependencies

**Output**: Security Assessment — use the format defined in `.ai/prompts/security-assess.md`

**Quality Gate**: No Critical or High findings. Medium findings documented with mitigation plan.

---

### Phase ⑦ — Deploy

> Complex only. Light and Standard tasks deploy in batches per wave.

Follow the PR conventions in `.github/git-workflow.md`:

1. Ensure all changes are committed and pushed to the feature branch
2. Open a PR using the squash-merge conventions (PR title = commit message format)
3. Confirm Vercel preview deployment is triggered
4. Verify the feature is accessible and functional at the preview URL
5. Once CI is green and the preview is verified, squash merge into `main`
6. Delete the feature branch

**Quality Gate**: PR merged. Production deploy succeeds. CI green on `main`.

---

### Phase ⑧ — Verify

> All tiers. Depth varies.

**Role**: `.ai/roles/business-analyst.md`
**Guide**: `.ai/prompts/verify-acceptance.md`

**Verification depth by tier**:

| Tier | Depth |
| ---- | ----- |
| Light | "Done when" spot check |
| Standard | Full "Done when" verification + user flow smoke test |
| Complex | Full verification + user flow test + regression check on dependent features |

1. Walk through every acceptance criterion from the Task Brief
2. Verify each against the actual implementation (code review or deployed preview)
3. For Standard + Complex: smoke test the affected user flow
4. For Complex: regression check — verify dependent features still work

**Output**:

```
## Task {id} — Verification

### Acceptance Criteria

- [x / ] {criterion}: {evidence}

### Smoke Test: Pass / Fail / N/A (Light tier)
### Regressions: None / {findings}

### Status: PASSED / FAILED — {failing criteria}
```

**Quality Gate**: All acceptance criteria pass.

---

## Step 6 — Completion

After the final phase passes, save the task output and present a summary.

### 6a. Save Task Output

Create the file `.ai/sprints/sprint-{N}/tasks/{task-id}.md` with this format:

```markdown
# Task {id} — {name}

**Sprint**: {N} — Wave {M}
**Tier**: {tier} ({phase count} phases)
**Pipeline**: {list of phase numbers executed}
**Status**: PASSED / FAILED
**Branch**: {branch name}

## Task Brief

{Summary from Phase ①: trace, acceptance criteria, constraints}

## Design Decisions

{Key decisions made during implementation — or "N/A" for Light tier}

## Artifacts

- Code changes: {list of files created or modified}
- Review: {verdict — Approved, findings summary}
- Test Report: {pass / fail summary, or N/A for Light}
- Security Assessment: {verdict, or N/A}
- Verification: {N}/{N} acceptance criteria passed

## Metrics

| Metric | Value |
| ------ | ----- |
| Total phases | {count of phases executed} |
| Gate failures | {count — list which phases failed and how many cycles} |
| Review cycles | {N (max 3 before escalation)} |
| Files changed | {count of files created + modified} |
| Lines changed | {+N / -N from git diff --stat} |
| Lint errors | {0 or count at final gate} |
| Test count | {number of tests run, or N/A for Light} |
| Build status | {pass / fail} |
| Human interventions | {count} |

## Human Interventions

{Log every point where the human corrected, redirected, or refined the agent's approach. For each intervention:}

- **{phase or step}**: {what the agent did or proposed} → {what the human corrected it to} — **Lesson**: {generalizable takeaway for the framework}

{If no interventions occurred, write "None — pipeline ran without human correction."}
```

### 6b. Update Sprint Progress

Update `docs/specs/sprint-{N}-progress.md`:

1. Set the task's Status column to `Done` (or `Failed`) with branch name and brief notes
2. Update the Summary section (done count, SP completed)
3. Update the Current Wave pointer
4. Set `**Last updated**` to today's date

If the progress file does not exist yet, create it following the format of `docs/specs/sprint-0-progress.md`.

### 6c. Present Summary

Output the summary to the conversation:

```
## Task {id} Complete

**Name**: {name}
**Sprint**: {N} — Wave {M}
**Tier**: {tier} ({phase count} phases)
**Pipeline**: {list of phase numbers executed}
**Output**: `.ai/sprints/sprint-{N}/tasks/{task-id}.md`
**Progress**: `docs/specs/sprint-{N}-progress.md` updated
```

---

## Failure Escalation

| Situation | Action |
| --------- | ------ |
| Unmet dependency | **STOP** — report which task(s) must complete first and what's missing |
| Ambiguous requirement | **STOP** — present the ambiguity and ask user to clarify |
| 3+ review/test cycles with recurring issues | **Escalate** — present the issue pattern and request architectural guidance |
| Scope creep (task larger than SP estimate) | **Flag** — report the scope increase and let user decide to split or proceed |
| External blocker (API down, tool broken) | **STOP** — document the blocker and suggest workaround |
| CI flake (passes on retry) | Note it, proceed, but log for retrospective |
