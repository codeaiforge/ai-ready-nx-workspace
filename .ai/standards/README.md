# Shared Standards

This folder documents shared rules and standards for the workspace.

- Architecture alignment, coding rules, diagram rules, Nx boundary usage, etc.
- Ensures all agents and contributors follow the same guidelines.

[`ai-provenance.md`](ai-provenance.md) is the one an agent must read before it commits:
agent-authored commits declare CAF-SDLC-010 trailers, and the PR gate fails a change
that claims AI involvement without naming the tool.
