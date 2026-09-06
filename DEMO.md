# Payment Reconciliation Demo

This branch is a worked example of the governance framework on `main`, not a product.

## What it sets out to show

1. An AI agent executing sprint tasks through the tiered SDLC pipeline without drifting
   from the recorded architecture and ADRs.
2. Human gates holding — the agent proposes, a person decides, and the decision is on the
   record.
3. The pipeline being genuinely stack-agnostic: `main` contains no Java, and everything
   Spring-specific here arrives through one file, [`docs/specs/stack.md`](docs/specs/stack.md).

## You do not need to run anything

The evidence is textual. Drift is judged by reading the trail against the architecture, not
by compiling Java:

| Where                                                     | What it shows                                                                                                                       |
| --------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| [`docs/adr/`](docs/adr/)                                  | Decisions taken, with alternatives and consequences                                                                                 |
| [`.ai/sprints/sprint-{N}/tasks/*.md`](.ai/sprints/)       | Per-task output: brief, design decisions, artifacts, metrics, and every **Human Intervention** with the lesson drawn from it        |
| [`.ai/sprints/sprint-{N}/retrospective.md`](.ai/sprints/) | Sprint-level aggregation, including proposed changes to the framework itself                                                        |
| [`docs/specs/sprint-{N}-progress.md`](docs/specs/)        | Task status, story points, current wave                                                                                             |
| Git history                                               | Where each human gate fell — the agent never commits (see [`.github/git-workflow.md`](.github/git-workflow.md) → Commit Checkpoint) |

The Commit Checkpoint is also why re-running this yourself is not the intended experience:
the pipeline stops for a human at every commit, so a fresh clone cannot reproduce the run
without you standing in for those decisions. The **record** is the artifact.

The baseline drift is measured against is
[`docs/architecture/overview.md`](docs/architecture/overview.md) and ADRs 0001-0005 — the
decisions the seeded workspace already embodies, recorded before the first task runs so
they can be departed from visibly.

> **Status**: the execution trail is empty until Sprint 1 runs. This branch currently holds
> the seeded workspace, the specs, the architecture baseline and its ADRs — the starting
> line, not the run.

## What is being built

A settlement reconciliation slice — deliberately a domain where correctness is checkable
and drift is obvious.

```
packages/
├── reconciliation-core/      library     — domain model (Money, matching engine)
└── reconciliation-service/   application — ingestion API, JPA/Flyway, audit, security
                                            depends on core (Maven pom; Nx derives the edge)
```

Requirements are in [`docs/specs/mvp-requirements.md`](docs/specs/mvp-requirements.md) as
EARS statements; the task breakdown is in
[`docs/specs/implementation-roadmap.md`](docs/specs/implementation-roadmap.md). Every task
traces to an `FR-*` / `NFR-*` ID, and that trace is what makes drift detectable.

## Why Java, and why this stack

Java 25 (LTS) and Spring Boot 4 on Maven, with Postgres, Flyway, and Testcontainers.

The framework's own tooling is TypeScript, so a TypeScript demo would prove nothing about
stack-independence. Driving an unrelated toolchain end to end is the test — the pipeline
prompts name no Spring, Maven, or Postgres anywhere; they resolve through
[`docs/specs/stack.md`](docs/specs/stack.md).

## If you do want to run it

The zero-install path is the devcontainer: open the branch in GitHub Codespaces, or
"Reopen in Container" in VS Code. It installs JDK 25, Node 20, pnpm and Docker-in-Docker
(needed by Testcontainers), and mirrors what CI installs, so a container run and a CI run
agree.

To run it on your own machine instead, the prerequisites — exact versions in
[`.tool-versions`](.tool-versions):

- **JDK 25** — the poms compile with `release 25`
- **Node 20+ and pnpm** — Nx is the build and impact engine
- **Docker running** — the service's integration test starts a real Postgres via Testcontainers

```bash
pnpm install
pnpm exec nx run-many -t check-format,test,build   # the gate from docs/specs/stack.md
pnpm exec nx graph                                 # service -> core edge
```

The projects are committed, so no code generation or network to `start.spring.io` is
needed. [`scripts/seed-java.sh`](scripts/seed-java.sh) records how they were produced and is
maintainer-only; it is idempotent and safe to re-run, but you should not need it.

Maven itself is not a prerequisite — each project carries its own `./mvnw` wrapper.

## Known sharp edges

- Formatting requires Spotless ≥ 2.44 with an explicitly pinned `google-java-format`. The
  version bundled with older Spotless calls a javac internal removed after JDK 21 and fails
  on 25.
- `@nxrocks/nx-spring-boot` infers format targets from an **inverted** condition (Spotless
  present ⇒ targets omitted), so `check-format` and `apply-format` are declared explicitly
  in each `project.json` rather than inferred.
- `nx run-many` silently skips targets that do not exist. A gate naming a missing target
  passes while checking nothing — worth remembering when reading CI green.
