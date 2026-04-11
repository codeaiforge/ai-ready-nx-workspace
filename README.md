# AI-Ready Nx Workspace

A template Nx monorepo pre-configured for AI-assisted software development. It provides an agent-agnostic governance framework, a tiered SDLC pipeline, and the scaffolding needed so that any AI coding agent (Claude, Codex, Gemini, or others) can operate consistently within a well-defined architecture.

## Why This Exists

AI coding agents are powerful, but without guardrails they tend to:

- Duplicate or contradict architectural decisions across agent-specific config files.
- Invent their own conventions instead of following the ones already in the repo.
- Skip quality gates because no machine-readable pipeline tells them otherwise.

This workspace solves those problems by establishing a **single source of truth** that every agent and human contributor consumes.

## Authority Order

All agents and contributors must follow this strict precedence:

| Priority | Source | Purpose |
| -------- | ------ | ------- |
| 1 | **Nx project graph** | Canonical system architecture and dependency boundaries |
| 2 | **`/docs`** | Repository-internal documentation (architecture, requirements, ADRs, diagrams) |
| 3 | **`/.ai`** | Shared AI governance: context, roles, standards, tasks, prompts, workflows |
| 4 | **Agent folders** (`.claude/`, `.codex/`, `.gemini/`) | Implementation adapters only -- must not duplicate or override architecture |

> Agents consume architecture. They do not redefine it.

## Repository Structure

```
.
├── .ai/                    # Shared AI governance layer
│   ├── context/            # Workspace context and Nx concept mappings
│   ├── roles/              # Agent role definitions (architect, implementer, reviewer, QA, BA)
│   ├── standards/          # Coding, architecture, testing, security, review standards
│   ├── tasks/              # Executable task templates (implement-feature, create-library, ...)
│   ├── prompts/            # Phase-specific SDLC prompt templates
│   └── workflows/          # Tiered SDLC pipeline orchestration
├── docs/                   # Project documentation
│   ├── adr/                # Architectural Decision Records
│   ├── architecture/       # System architecture documentation
│   ├── diagrams/           # Mermaid and visual diagrams
│   └── requirements/       # Business and functional requirements
├── packages/               # Nx projects (apps and libs)
├── AGENTS.md               # Agent governance entry point (Codex/Gemini adapter)
├── CLAUDE.md               # Claude-specific adapter
├── nx.json                 # Nx workspace configuration
├── tsconfig.base.json      # Shared TypeScript configuration
└── pnpm-workspace.yaml     # pnpm workspace definition
```

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) (LTS recommended)
- [pnpm](https://pnpm.io/)

### Installation

```sh
pnpm install
```

### Common Commands

```sh
# Visualize the project graph
pnpm nx graph

# Run a task for a project
pnpm nx <target> <project>

# Run tasks for all affected projects
pnpm nx affected -t <target>

# Sync TypeScript project references
pnpm nx sync
```

## AI Governance Framework

The `/.ai` directory is the core of what makes this workspace "AI-ready". It defines a shared, agent-agnostic layer that any AI tool can consume.

### Roles

Predefined agent personas that map to SDLC responsibilities:

| Role | File | Responsibility |
| ---- | ---- | -------------- |
| Architect | `roles/architect.md` | System design, boundary enforcement, ADRs |
| Business Analyst | `roles/business-analyst.md` | Requirements analysis, acceptance criteria |
| Implementer | `roles/implementer.md` | Code authoring following standards |
| Reviewer | `roles/reviewer.md` | Code review, security, maintainability |
| QA | `roles/qa.md` | Test strategy, validation, quality gates |

### Standards

Shared rules that apply to all agents and contributors, covering: coding conventions, architecture alignment, Nx boundary enforcement, testing, security, documentation, review process, ADR format, CI/CD, release management, and onboarding.

See [`.ai/standards/`](.ai/standards/) for the full set.

### Task Templates

Standardized, executable task definitions that agents follow when performing common operations: implementing features, creating libraries/apps, validating architecture, running tests, reviewing PRs, managing releases, and more.

See [`.ai/tasks/`](.ai/tasks/) for the full set.

### SDLC Pipeline

Work flows through a tiered pipeline with quality gates between each phase:

| Phase | Lead Agent | Purpose |
| ----- | ---------- | ------- |
| Analyze | Business Analyst | Understand requirements, resolve ambiguity |
| Design | Architect | Define files, interfaces, data flow |
| Implement | Specialist | Write code, tests, documentation |
| Review | Reviewer | Verify correctness, security, maintainability |
| Test | QA Engineer | Integration, accessibility, performance testing |
| Security | Security Engineer | Threat analysis (complex tasks only) |
| Deploy | DevOps Engineer | Ship to verifiable environment |
| Verify | Business Analyst | Confirm acceptance criteria met |

Three tiers control which phases are active:

- **Light** (1--2 SP) -- 4 phases: Analyze, Implement, Review, Verify
- **Standard** (3 SP) -- 6 phases: adds Design and Test
- **Complex** (5--8 SP) -- all 8 phases: adds Security and Deploy

See [`.ai/workflows/`](.ai/workflows/) for pipeline definitions and decision gates.

## Agent Adapters

Each supported AI agent has an adapter file at the repo root that wires it into the shared governance layer:

| File | Agent | Purpose |
| ---- | ----- | ------- |
| `CLAUDE.md` | Claude Code | Claude-specific Nx instructions |
| `AGENTS.md` | Codex / Gemini / others | Shared agent governance + Nx guidelines |

These adapters reference `/.ai` for roles, standards, and tasks. They must not duplicate or override the shared definitions.

## Nx Workspace Details

- **Package manager**: pnpm
- **Build system**: SWC via `@nx/js`
- **TypeScript**: Composite project references with strict mode
- **Task inference**: Targets are inferred by the `@nx/js/typescript` plugin

### Nx Concepts in This Workspace

| Nx Concept | Maps To |
| ---------- | ------- |
| apps | Deployable units (services, frontends, APIs) |
| libs | Domain modules (business logic, shared utilities) |
| tags | Architectural boundaries between domains |
| project graph | Canonical system architecture |

## Documentation

The `/docs` directory follows a structured layout for project documentation:

- **`adr/`** -- Architectural Decision Records using [MADR](https://adr.github.io/madr/) format
- **`architecture/`** -- System overviews, component breakdowns, technology rationale
- **`diagrams/`** -- Mermaid diagrams as authoritative system views
- **`requirements/`** -- Business, functional, and non-functional requirements

## License

[MIT](LICENSE)
