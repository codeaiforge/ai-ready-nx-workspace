# Nx Workspace Context

This document defines how Nx concepts map to the architecture and governance of this repository. All agents and contributors must use this as the canonical reference for interpreting the Nx project graph and workspace structure.

## Nx Concepts and Mappings

- **apps** → Deployables
  - Projects that produce runnable artifacts or services (e.g., applications, APIs, frontends).
  - Each app represents a deployable unit in the system.

- **libs** → Domains
  - Reusable code, business logic, or shared utilities grouped by domain or concern.
  - Enforces separation of concerns and promotes modularity.

- **tags** → Boundaries
  - Used to define and enforce architectural boundaries between domains.
  - Tags are required for all projects and must reflect business or technical boundaries.

- **Nx project graph** → Architecture
  - The project graph is the canonical, machine-readable representation of the system’s architecture and dependencies.
  - All architectural logic and decisions must be derived from the Nx project graph.

## Workspace Conventions

- All projects (apps/libs) must be tagged according to their domain and boundary.
- Dependencies between projects must respect tag-based boundaries.
- Use Nx generators and commands for all structural changes.

## Example

- An app tagged `customer-facing` may depend on libs tagged `domain-customer` and `shared-ui`, but not on `admin-only` libs.
- The Nx project graph will enforce these boundaries and highlight violations.

## References

- See AGENTS.md for authority order and governance.
- See .ai/standards/ for coding and boundary rules.
