# ADR-0003: Test against a real Postgres via Testcontainers, not an in-memory substitute

- **Status**: Accepted
- **Date**: 2026-09-06
- **Deciders**: Architect, QA Engineer, Database Engineer
- **Trace**: Testing, NFR-3.1, NFR-6.1

## Context

The service persists through Spring Data JPA with Flyway-managed schema on PostgreSQL. Its
correctness claims are database-shaped: migrations apply in order, constraints reject bad
data, and the audit trail is append-only (NFR-6.1). Ingestion must survive restart without
double-processing (NFR-3.1), which is a transactional property of the real engine.

A test that runs against a different database does not exercise any of that. Worse, it can
pass while the production path fails, because dialect differences hide exactly the
constraint and migration behaviour being asserted.

Spring Boot's generated `contextLoads` test made the tension concrete: scaffolding the
service with `data-jpa` and no datasource leaves the build red out of the box. Something had
to supply a database before the suite could go green.

## Decision

We will run integration tests against a real PostgreSQL instance supplied by Testcontainers,
wired into the Spring context with `@ServiceConnection` so no datasource properties are
duplicated in configuration.

## Options Considered

- **Option A — Testcontainers Postgres (chosen)**: tests exercise the real engine, real
  migrations, real constraints. Costs a Docker daemon as a hard prerequisite for the test
  suite and adds container startup to the test run — measured at roughly 5-6 seconds for the
  context test.
- **Option B — H2 in PostgreSQL compatibility mode**: fast and dependency-free, but the
  compatibility is partial. Flyway migrations using Postgres-specific DDL fail or, worse,
  silently behave differently. It tests a database we do not ship.
- **Option C — a shared developer database**: real Postgres without container startup cost,
  but tests become order-dependent and mutually destructive, and CI needs credentials and
  network reach to a stateful resource. Reproducibility is lost.
- **Option D — mock the repositories**: fastest, and appropriate for unit-testing logic
  above the data layer, but it asserts nothing about schema, migrations, or constraints —
  precisely the claims that matter here.

## Consequences

Migration and constraint behaviour is verified against the engine we deploy, so a Flyway
change that breaks on Postgres fails in CI rather than in staging.

The cost is that Docker becomes a prerequisite for running tests at all — for contributors,
for CI, and for the devcontainer, which therefore needs docker-in-docker. Anyone without a
running daemon sees the suite fail for environmental reasons, so the prerequisite is stated
in `docs/specs/stack.md` and the seed script warns when the daemon is absent.

Test runs are also slower by container startup. That cost is per-suite rather than per-test
as long as the container is reused across the context, which the `@ServiceConnection`
configuration provides.
