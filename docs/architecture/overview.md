# System Architecture — Payment Reconciliation

The authoritative structure is the Nx project graph (`pnpm exec nx graph`). This document
records the intent behind it: what each project is for, which direction dependencies run,
and which decisions are settled. Where this document and the graph disagree, the graph is
right and this document is stale — say so rather than working around it.

## Context

The system reconciles an internal ledger against settlement files received from external
providers. A run pairs ledger entries with settlement rows, and anything unpaired becomes a
categorised exception for an operator to resolve. Every match, override and resolution is
recorded in an append-only audit trail (NFR-6.1).

## Projects

| Project                  | Type        | Responsibility                                                      |
| ------------------------ | ----------- | ------------------------------------------------------------------- |
| `reconciliation-core`    | library     | Domain model and matching engine. No Spring, no database, no I/O.   |
| `reconciliation-service` | application | Ingestion API, persistence, audit, access control. Depends on core. |

```text
reconciliation-service ──depends on──▶ reconciliation-core
        │                                      │
        │ Spring Boot, JPA/Flyway,             │ pure Java: Money,
        │ Security, HTTP                       │ matching engine
        ▼                                      ▼
    PostgreSQL                            (no dependencies)
```

The dependency runs one way and the build enforces it: core cannot reference the service.
See [ADR-0004](../adr/0004-split-domain-core-from-service.md).

## Layers within the service

Package-by-feature, with hexagonal ports and adapters where the feature talks to something
external. The domain sits behind the port; adapters hold the JPA, HTTP and file-parsing
concerns. A feature package owns its own persistence rather than sharing a repository layer
across features.

## Settled decisions

| Decision                                                                             | ADR                                                                 |
| ------------------------------------------------------------------------------------ | ------------------------------------------------------------------- |
| Nx is the impact engine; Maven executes. The pom is the only dependency declaration. | [ADR-0001](../adr/0001-nx-as-build-and-impact-engine-over-maven.md) |
| Money is integer minor units plus ISO-4217 currency. No floating point.              | [ADR-0002](../adr/0002-money-as-integer-minor-units.md)             |
| Integration tests run against real Postgres via Testcontainers.                      | [ADR-0003](../adr/0003-testcontainers-as-integration-harness.md)    |
| The domain lives in a library separate from the service.                             | [ADR-0004](../adr/0004-split-domain-core-from-service.md)           |
| Health is unauthenticated; nothing else is exposed.                                  | [ADR-0005](../adr/0005-unauthenticated-health-endpoint.md)          |

## Constraints these place on new work

These are the lines that make drift detectable. A change that crosses one needs a new ADR
superseding the old, not a workaround:

- **No floating point in a monetary path.** Amounts are `Money`; parsing to and from it
  happens at boundaries, not scattered through the domain.
- **No infrastructure in `reconciliation-core`.** No Spring annotations, no JPA, no I/O. If
  the domain appears to need one, the need is usually a port that belongs in the service.
- **A new inter-project dependency is declared once, in the pom.** The Nx edge is derived
  from it. Do not add `implicitDependencies` — a hand-written edge outlives the dependency
  it claims, and the affected-set then lies.
- **Schema changes are Flyway migrations**, forward-only and ordered. No entity
  auto-generation against a real database.
- **Every table carrying financial or audit data is append-only or explicitly justified**
  in the task's ADR (NFR-6.1).

## Deliberately not decided yet

Recorded so their absence is visible rather than mistaken for an oversight:

- **Where built images are published.** The Deploy phase builds an OCI image and verifies
  it boots locally against Postgres via `compose.yaml`. No registry or cluster is
  configured, so nothing is published and no environment is promoted to. Settling this
  means choosing a registry, credentials handling, and a promotion path.
- **Ingestion idempotency mechanism.** Required by NFR-3.1 and scheduled as task 2.6; the
  approach (natural key, content hash, or delivery receipt) is open.
- **The real access-control policy.** `SecurityConfig` implements only ADR-0005 — health
  permitted, everything else authenticated — so the deploy gate can reach the probe. Task
  2.4 (NFR-2.1) owns the actual policy and is expected to replace that class, carrying the
  ADR-0005 rule forward.
