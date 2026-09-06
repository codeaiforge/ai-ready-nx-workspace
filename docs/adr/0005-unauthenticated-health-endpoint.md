# ADR-0005: Expose the health endpoint unauthenticated, and nothing else

- **Status**: Accepted
- **Date**: 2026-09-06
- **Deciders**: Architect, Security Engineer, DevOps Engineer
- **Trace**: NFR-2.1, Infra

## Context

The deploy phase has to establish that a built image actually runs — not merely that it
compiled. Proving that requires asking the running service a question and getting a
trustworthy answer.

Spring Security is on the classpath, and its default is to authenticate everything. A
platform probe therefore cannot reach the service at all without an explicit decision about
what it may see. That decision is security-relevant and must not be made implicitly by
whoever writes the deployment tooling.

There is also a scope boundary to keep clear. Roadmap task 2.4 owns role-based access
control for the application's own endpoints (NFR-2.1). This ADR is not that. It settles only
what an unauthenticated caller may learn about a running instance.

## Decision

We will permit unauthenticated access to `/actuator/health` and require authentication for
everything else. Only the `health` endpoint is exposed over HTTP; no other actuator endpoint
is enabled.

## Options Considered

- **Option A — health unauthenticated, all else authenticated (chosen)**: the deploy gate
  and any future orchestrator probe work with no credentials. The exposure is a liveness
  signal and, with details withheld, reveals nothing about topology or configuration.
- **Option B — authenticated probe with credentials**: leaks nothing, but every prober needs
  a secret. That means a credential in the compose file, in CI, and eventually in a cluster —
  more secret-handling surface than the exposure is worth.
- **Option C — actuator on a separate management port, firewalled**: the conventional
  production answer and probably right once a cluster exists. It needs network policy to
  mean anything, and there is no cluster to enforce it (see the open decisions in
  `docs/architecture/overview.md`). Adopting it now would be configuration pretending to be
  a control.
- **Option D — no probe; treat "image built" as deployed**: removes the exposure and the
  value. A gate that never asks the service anything cannot tell a working deployment from a
  broken one.

## Consequences

The deploy verify gate can assert that the service booted, connected to its database and ran
its migrations — Flyway and JPA both participate in health — which is a materially stronger
claim than "the image was produced".

An unauthenticated endpoint exists on the service. It is the only one, it returns status
without detail, and health details stay off by default; anything richer needs a new decision.

`SecurityConfig` is deliberately minimal and provisional. Task 2.4 owns the real policy and
is expected to **replace** that class, carrying this rule forward. If 2.4 lands without
preserving it, the deploy gate breaks — that is intentional, so the coupling fails loudly
rather than silently dropping the exemption.

Once a cluster exists, Option C should be revisited and this ADR superseded: a separate
management port with network policy is strictly better than an application-level permit.
