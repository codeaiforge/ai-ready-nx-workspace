# Workflows

Orchestration definitions for the tiered SDLC pipeline. These files define how AI agents sequence through phases to deliver tasks in an Nx monorepo.

## Contents

| File | Purpose |
| ---- | ------- |
| [sprint-conductor.md](sprint-conductor.md) | Meta-agent orchestrating iteration lifecycle (planning, waves, gates, retro) |
| [task-pipeline.md](task-pipeline.md) | Per-task SDLC pipeline: 8 phases, input/output contracts, quality gates |
| [tier-light.md](tier-light.md) | 4-phase pipeline for trivial tasks (1-2 SP) |
| [tier-standard.md](tier-standard.md) | 6-phase pipeline for moderate tasks (3 SP) |
| [tier-complex.md](tier-complex.md) | 8-phase pipeline for high-risk tasks (5-8 SP) |
| [decision-gates.md](decision-gates.md) | Gate definitions and evaluation criteria at iteration boundaries |

## How These Relate to Other `.ai/` Directories

- **roles/** provide the agent identity injected at each phase
- **tasks/** provide the step-by-step process templates
- **standards/** provide the quality rules agents must follow
- **prompts/** provide the phase-specific prompt templates that compose all of the above

## Framework Alignment

This directory extends the 12-phase AI-Ready Nx Workspace framework (Phases 5-10) with an orchestration layer that sequences agents into a coherent delivery pipeline. It bridges the gap between having governance structures and actually using them to deliver work.

## Customization

Replace `{placeholders}` throughout these files with your project-specific values:

- `{package-manager}` — your package manager (`npm`, `pnpm`, `yarn`)
- `{ci-tool}` — your CI system (GitHub Actions, GitLab CI, CircleCI)
- `{deployment-target}` — your deployment platform (Vercel, AWS, GCP, Azure)
- `{requirements-doc}` — path to your requirements specification
- `{roadmap-doc}` — path to your implementation roadmap
