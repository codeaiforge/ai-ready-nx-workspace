<!--
  Sprint Progress Template
  ------------------------
  Copy to `docs/specs/sprint-{{N}}-progress.md` — one file per sprint.

  Preserve the structure, heading levels, and field names exactly. Downstream
  tooling depends on them: `.github/prompts/run-task.prompt.md` (step 6b) writes
  the Status column, the Summary section, the Current Wave pointer, and the
  `**Last updated**` line by name after every task. Diverge only at the
  placeholder slots marked with `{{double-braces}}` (mustache style).

  Authoring rules:
  1. Task IDs and task names MUST match the roadmap rows exactly. Never
     renumber — tooling, branch names, and git history reference the ID.
  2. Status is one of: `Not started`, `In progress`, `Done`, `Failed`,
     `Blocked`. A task reaching a terminal state gets `Done` or `Failed`.
  3. The Notes cell for a finished task carries the branch name first, then a
     one-line summary of what shipped. Keep it to one cell — long-form detail
     goes in a per-task section (see the optional block below).
  4. Summary counts MUST agree with the Task Status table. Re-derive them
     rather than incrementing by hand.
  5. Current Wave names the wave now unblocked, per the roadmap's Execution
     Waves table — not the wave just finished.
  6. Definition of Done comes from the sprint's roadmap entry. Copy it at
     sprint start; do not invent new criteria mid-sprint.
  7. Blockers are carried forward, not deleted. A resolved blocker is struck
     through or moved under a `Resolved` sub-heading so the trail survives.
  8. `**Last updated**` records the date AND the task that triggered the write.
  9. Delete this comment block before committing the real progress file.
-->

# Sprint {{N}} Progress

**Sprint**: {{N}} — {{Theme}}
**Dates**: {{Mon D}} – {{Mon D, YYYY}}
**Last updated**: {{YYYY-MM-DD}} ({{task N.M — what triggered this update}})

---

## Task Status

| # | Task | Status | Notes |
| - | ---- | ------ | ----- |
| {{N.1}} | {{Task name, copied from the roadmap}} | {{Done}} | `{{branch-name}}` — {{what shipped, one line}} |
| {{N.2}} | {{Task name}} | {{In progress}} | {{current state}} |
| {{N.3}} | {{Task name}} | {{Not started}} | {{blocked on N.2, or empty}} |

## Additional Work Completed (not in roadmap)

| Item | Commit | Notes |
| ---- | ------ | ----- |
| {{What was done}} | `{{sha}}` | {{Why it happened here — e.g. "supports N.4"}} |

## Summary

- **Done**: {{X}} / {{Y}} tasks
- **In progress**: {{X}} / {{Y}} tasks
- **Not started**: {{X}} / {{Y}} tasks
- **Story points completed**: {{X}} / {{Y}} SP

## Current Wave

**{{Wave N}}** — {{tasks now unblocked}}. {{One line on what gates the next wave.}}

## Sprint {{N}} Definition of Done

- [ ] {{Observable criterion copied from the roadmap sprint entry}}
- [ ] {{Observable criterion}}
- [ ] {{Observable criterion}}

## Blockers / Decisions Needed

- **{{Task N.M}}**: {{What is blocked, what decision is needed, and who owns it.}}
- **{{Carried forward from Sprint N-1}}**: {{Blocker still open.}}

<!--
  OPTIONAL — per-task detail sections.

  For sprints where the one-line Notes cell isn't enough (complex-tier tasks,
  multi-commit tasks, tasks with review cycles), add a section per task below
  the tables. Keep the tables authoritative for status; these sections carry
  the narrative only.

## Task {{N.M}} — {{Done}} ✅

### What shipped ({{N.M}})

- {{Change, with the file or package it landed in}}

### Notes ({{N.M}})

- {{Decisions taken, ADRs raised, follow-ups deferred to a later sprint}}
-->
