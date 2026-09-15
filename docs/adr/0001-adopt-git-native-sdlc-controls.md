# ADR-0001: Adopt git-native-sdlc-controls as the PR gate, and generate its component map from the Nx graph

- **Status**: Proposed
- **Date**: 2026-09-15
- **Deciders**: Architect, DevOps Engineer, Security Engineer
- **Trace**: Infra

## Context

This workspace documented a tiered SDLC — Light, Standard and Complex pipelines in
`.ai/workflows/`, with escalation rules and decision gates — but nothing enforced any of
it. The tier was self-declared from a story-point estimate, by the same agent or person
doing the work, and no artifact survived the pull request to show what was decided or
why. Three gaps followed from that:

1. no graph-derived blast-radius tiering — risk was estimated from effort;
2. no standards gate compiled into CI — the standards in `.ai/standards/` were prose;
3. no AI provenance — nothing recorded which commits a machine wrote.

`git-native-sdlc-controls` already implements exactly these as a portable Go binary with
a versioned evidence contract: change-risk tiering (CAF-SDLC-002), AI provenance
(CAF-SDLC-010), an independent-approver control (CAF-SDLC-011), and an `evidence/0`
record per change. Reimplementing any of that here would produce a second, worse copy
that drifts.

The binary has one documented ceiling. It tiers from a **hand-maintained** component map,
and its own control document is candid about the consequence: *"a high fan-in component
that nobody declared `shared: true` will be under-tiered"*, and *"`shared` is a boolean
stand-in for what is really a fan-in count"*. It accepts that trade because computing
fan-in would require per-language build-tool integration, which would cost the binary the
tooling-agnostic property that makes it portable at all.

That cost is already paid here. This workspace has a computed Nx project graph. The
ceiling that is inherent for a generic repository is not inherent for this one.

## Decision

We will adopt `git-native-sdlc-controls` at the exact tag **`v0.2.0`** as a required pull
request gate, and we will **generate** its component map from the Nx project graph rather
than maintain one by hand.

Specifically:

- **Consume, do not reimplement.** Tiering, provenance parsing and approver logic stay in
  the binary. No TypeScript copy of any of them.
- **The adapter lives here.** `tools/sdlc-controls/generate-component-map.mjs` inverts the
  graph's dependency edges for fan-in, reads path globs from project roots, and emits the
  map schema the binary already reads. Nothing about Nx reaches the binary.
- **Split the two signals.** Topology (`match`, `shared`) is computed from the graph.
  Criticality is read from reviewed `criticality:` project tags, with untagged projects
  defaulting to `high`.
- **The binary is the tier authority.** `.ai/workflows/` reads `T0`–`T3` from the evidence
  record. Story points size effort and no longer claim to measure risk.
- **Pin exactly.** `v0.2.0` for both the binary and the evidence schema, fetched from the
  same Go module so they cannot drift.
- **Fail closed.** Exit 1 and exit 2 both fail the job; evidence uploads either way.

## Options Considered

- **Option A — Adopt the binary, generate the map from the Nx graph (chosen).** Closes
  two gaps by pure adoption and the third with a ~200-line adapter. Beats the binary's
  hand-maintained-map ceiling for this workspace, because fan-in is read from the graph
  instead of remembered. Costs a Go toolchain step in CI and an adapter to maintain
  against the map schema. Criticality remains declared.

- **Option B — Adopt the binary with a hand-written `components.yaml`.** Simplest: no
  adapter, no Node step in the gate. Rejected because it inherits the ceiling wholesale
  in a repository that demonstrably does not need to. The map would drift from the graph
  the moment a project moved, and a stale map under-tiers silently — the failure mode is
  invisible, which is the worst kind.

- **Option C — Implement tiering in TypeScript against the Nx graph directly.** No Go in
  CI, and full access to graph detail the map schema cannot express (real fan-in counts,
  transitive blast radius). Rejected: it forks the control logic. The evidence contract,
  the provenance parser and the approver rules would all need a second implementation,
  and the two would diverge on the first bug fixed in one of them. A worse copy of a
  thing that already exists is not an improvement, and the aggregation story — a future
  control plane reading `evidence/0` from many repositories — depends on every repo
  emitting the *same* contract.

- **Option D — Do nothing; keep the documented tiers.** Zero cost, zero enforcement.
  Rejected: the documented pipeline was the thing that did not work. Governance that
  describes itself and never fires is worse than none, because it reads as a control in
  an audit while being a convention.

## Consequences

**Easier**

- Two gaps (CI-compiled standards gates, AI provenance) close by adoption alone, with no
  logic written here.
- The third (graph-derived blast radius) closes with a thin adapter that is strictly
  better than the binary's default for this workspace: a widely-depended-on library
  escalates because the graph says so, not because somebody remembered.
- Every pull request leaves a schema-valid, versioned `evidence/0` record — the upward
  signal a future multi-repo control plane can aggregate without this repo changing again.
- One risk tier with one producer. The pipeline reads it.

**Harder**

- CI gains a Go toolchain step and a `pnpm nx graph` run, so the gate is slower than a
  pure-YAML check.
- The adapter is a new thing to maintain against the map schema. If the schema changes,
  this breaks and must be fixed here.
- Untagged projects default to `high`, so a new project is tiered conservatively until
  somebody tags it. This is intended friction and will be felt as friction.

**Constraints this imposes**

- The adapter is workspace-only. Nothing Nx-shaped may be pushed into
  `git-native-sdlc-controls`; the engine stays framework-agnostic. Limitations found in
  the map schema are recorded as findings in
  [`../sdlc-controls-integration.md`](../sdlc-controls-integration.md#findings-against-the-map-schema),
  not patched into the engine.
- `tools/sdlc-controls/**` is declared `critical`, so changing the tiering code is itself
  a T3 change needing two independent approvers.
- The gate only covers pull requests. It is advisory until branch protection requires
  PRs on `main` and marks this check required.

**Stated plainly, so the gate is not oversold**

- Criticality is a **declared** input, not a computed one. It is now a reviewed tag
  rather than a hand-edited YAML entry, which puts it in front of a reviewer, but no
  machine is deciding what matters to the business.
- Provenance is a **declaration**, not a detection. Nothing here proves a human wrote a
  commit. It makes the honest case cheap and the dishonest case an explicit, attributable
  act — which is what a forge-level control can offer, and no more.
- The independent-approver control is segregation of duties between two **forge
  accounts**, at the tier the policy chooses. It is not "an AI change cannot be approved
  by its prompter"; whoever ran the model is not an input to any of this.
