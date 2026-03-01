<!-- nx configuration start-->
<!-- Leave the start & end comments to automatically receive updates. -->

# Repository Authority & Nx Guidelines

## Authority Order (Source of Truth)

All agents and contributors must follow this strict authority order:

1. **Nx project graph** — The canonical source of system architecture and boundaries.
2. **/docs** — Repository-internal documentation (architecture, requirements, diagrams, ADRs).
3. **/.ai** — Shared AI governance, context, roles, tasks, and standards.
4. **Agent folders** (e.g., .claude/, .codex/, .gemini/) — Implementation adapters only.

> **Agents must consume, not redefine, architecture.**

All architectural logic and decisions must be derived from the Nx project graph and /docs. Agent folders must not duplicate or override architecture logic. This ensures a single source of truth and prevents fragmentation.

## General Guidelines for working with Nx

- For navigating/exploring the workspace, invoke the `nx-workspace` skill first - it has patterns for querying projects, targets, and dependencies
- When running tasks (for example build, lint, test, e2e, etc.), always prefer running the task through `nx` (i.e. `nx run`, `nx run-many`, `nx affected`) instead of using the underlying tooling directly
- Prefix nx commands with the workspace's package manager (e.g., `pnpm nx build`, `npm exec nx test`) - avoids using globally installed CLI
- You have access to the Nx MCP server and its tools, use them to help the user
- For Nx plugin best practices, check `node_modules/@nx/<plugin>/PLUGIN.md`. Not all plugins have this file - proceed without it if unavailable.
- NEVER guess CLI flags - always check nx_docs or `--help` first when unsure

## Scaffolding & Generators

- For scaffolding tasks (creating apps, libs, project structure, setup), ALWAYS invoke the `nx-generate` skill FIRST before exploring or calling MCP tools

## When to use nx_docs

- USE for: advanced config options, unfamiliar flags, migration guides, plugin configuration, edge cases
- DON'T USE for: basic generator syntax (`nx g @nx/react:app`), standard commands, things you already know
- The `nx-generate` skill handles generator discovery internally - don't call nx_docs just to look up generator syntax

<!-- nx configuration end-->
