# Sprints

Execution records produced by the SDLC pipeline. Unlike the rest of `.ai/`,
nothing here is authored by hand — agents write these files as they work, and
later runs read them back as accumulated context.

This directory is empty in the template workspace. It fills in as sprints run.

## Tree Shape

```
.ai/sprints/
└── sprint-{N}/
    ├── tasks/
    │   ├── {task-id}.md        # one per executed task, e.g. 0.1.md, 1.3.md
    │   └── ...
    └── retrospective.md        # one per completed sprint
```

Sprint directories are numbered to match the roadmap (`sprint-0`, `sprint-1`).
Task filenames are the roadmap task ID exactly — `0.1.md`, not `task-0.1.md`.

## Contents

| File | Written by | Read by |
| ---- | ---------- | ------- |
| `sprint-{N}/tasks/{task-id}.md` | `run-task.prompt.md` step 6a, after every task | `run-task.prompt.md` and `sprint-conductor.prompt.md` — both compile the **Human Interventions** sections into accumulated lessons before starting new work |
| `sprint-{N}/retrospective.md` | `sprint-conductor.prompt.md` step 5b, at sprint close | `run-task.prompt.md` and `sprint-conductor.prompt.md` — read from sprint `N+1` for cross-sprint lessons |

## Format Ownership

**The prompts own these formats, not this directory.** Both file formats are
specified inline at the step that writes them:

- Task output — [`.github/prompts/run-task.prompt.md`](../../.github/prompts/run-task.prompt.md), section 6a
- Retrospective — [`.github/prompts/sprint-conductor.prompt.md`](../../.github/prompts/sprint-conductor.prompt.md), section 5b

There are deliberately no templates here. A template would be a second copy of a
format that already has a home, and agents read the prompt — so a drifted
template would lose silently.

## Why These Files Matter

The **Human Interventions** section in each task file is the framework's
feedback loop. Every point where a human corrected the agent is logged with a
generalizable lesson, and those lessons are compiled and re-applied on every
subsequent task in the sprint. Repeating a previously corrected mistake counts
as a pipeline failure.

Retrospectives aggregate those interventions into proposed changes to the
prompts, workflows, roles, and standards themselves — which is how the
governance layer improves rather than ossifying.
