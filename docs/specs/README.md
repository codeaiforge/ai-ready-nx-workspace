# Specifications

This folder holds the requirements, roadmap, and sprint progress records that
drive the SDLC pipeline.

## Templates and their instances

This is a template workspace, so the files here are skeletons. A real project
copies each one to its instance filename — the name the prompts and tooling
actually read.

| Template | Copy to | Read by |
| -------- | ------- | ------- |
| `requirements-template.md` | `mvp-requirements.md` | `run-task.prompt.md` — resolves the roadmap Trace column to full EARS requirement text |
| `roadmap-template.md` | `implementation-roadmap.md` | `run-task.prompt.md` — reads the task row by ID; `sprint-conductor.prompt.md` — reads the sprint |
| `sprint-progress-template.md` | `sprint-{N}-progress.md` (one per sprint) | `run-task.prompt.md` — writes Status, Summary, Current Wave, and Last updated after every task |

Instance filenames are fixed. The prompts reference them by path, so renaming
one breaks the pipeline.

## Intended Content

- Business goals and objectives
- Functional requirements (features, use cases) as EARS statements
- Non-functional requirements (performance, security, reliability, usability,
  scalability, compliance)
- Sprint-by-sprint task breakdown with story points, dependencies, and
  execution waves
- Traceability from requirement ID to task to commit

## Conventions

- Requirement IDs (`FR-1.1`, `NFR-3.1`) are permanent labels. Never renumber
  one after it has been traced by a roadmap task.
- Task IDs (`0.1`, `1.3`) follow `<sprint>.<task>` and flow into branch names
  and commit scopes. Never renumber an executed task.
- `NFR-6.*` marks compliance requirements. A task or ADR tracing one requires
  Security-role sign-off — see [`.ai/standards/adr.md`](../../.ai/standards/adr.md).
- Each template carries its own authoring rules in a comment block at the top.
  Read them before filling one in, and delete them before committing.
