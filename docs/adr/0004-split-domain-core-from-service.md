# ADR-0004: Keep the reconciliation domain in a library separate from the service

- **Status**: Accepted
- **Date**: 2026-09-06
- **Deciders**: Architect
- **Trace**: FR-2.1, NFR-1.1

## Context

The matching engine (FR-2.1) is the part of this system whose correctness is hardest to
argue and most expensive to get wrong. It is pure computation: given ledger entries and
settlement rows, decide what pairs. It needs no database, no HTTP, and no Spring context.

The ingestion API, persistence, audit and access control around it need all three. If both
live in one deployable, the matching logic can only be tested through a Spring context with
a container attached — which makes the tests that most need to be exhaustive the slowest
ones to run, and quietly discourages writing enough of them.

## Decision

We will keep the domain model and matching engine in `reconciliation-core`, a plain library
with no Spring Boot plugin and no infrastructure dependencies, and have
`reconciliation-service` depend on it.

## Options Considered

- **Option A — separate core library (chosen)**: domain logic is unit-testable in
  milliseconds with no container; the dependency direction is enforced by the build rather
  than by convention. Costs a second project, a published jar between them, and a dependency
  edge that must stay consistent in both Maven and the Nx graph (see ADR-0001).
- **Option B — single service, package-level separation**: fewer moving parts, and the same
  separation is expressible with packages. But nothing enforces it — an `import` from domain
  into persistence compiles fine, and the boundary erodes exactly when schedule pressure
  makes erosion tempting.
- **Option C — separate services**: strongest isolation, but matching is not independently
  deployable or separately scalable here. It would buy network calls and operational
  surface in exchange for a boundary a library already provides.

## Consequences

Matching-engine tests run without Docker or Spring — the fast feedback loop lands where the
hard logic is. The `MoneyTest` suite runs in tens of milliseconds against the container-bound
service tests' several seconds, and that ratio should hold as the engine grows.

The build enforces the dependency direction: core cannot reference the service, so
infrastructure concerns cannot leak into the domain by accident.

The cost is ceremony. Every cross-project change touches two poms, and Nx must publish
core's jar to the local repository before the service builds — handled by the `install`
target running ahead of `build`, but it means a stale local jar can produce confusing
results after a manual Maven invocation that bypasses Nx.

This split is also what makes the demo's `affected` ripple meaningful: a change in core must
mark the service affected, and if it does not, the graph is lying.
