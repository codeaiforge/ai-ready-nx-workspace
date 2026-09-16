# ADR Standards

Defines the required format, numbering, lifecycle, and traceability for
Architectural Decision Records in this workspace. Every ADR an agent or human
produces MUST conform to this standard.

## Format (MADR-derived)

Each ADR is a single Markdown file at `docs/adr/NNNN-short-slug.md`, where `NNNN`
is a zero-padded, monotonically increasing number. Never renumber or delete an
ADR after it is committed; supersede it instead. To create one, copy
`docs/adr/0000-template.md` (the reserved skeleton) and rename to the next
free number — real ADRs start at `0001`.

Every ADR MUST contain these sections, in this order:

## ADR-NNNN: <Title stating the decision, not the problem>

- **Status**: Proposed | Accepted | Superseded by ADR-MMMM | Deprecated
- **Date**: YYYY-MM-DD
- **Deciders**: <roles/handles who approved>
- **Trace**: <FR/NFR IDs this decision serves, e.g. NFR-1.1, FR-2.1>

## Context

The forces at play: the requirement or constraint driving the decision, and why
it needs deciding now. State the problem neutrally — no chosen option here.

## Decision

The option chosen, in the active voice ("We will ..."). One decision per ADR.

## Options Considered

Each option with its trade-offs. The chosen option appears here too, so the
rejected alternatives are on record beside it.

## Consequences

What becomes easier and what becomes harder — positive and negative, including
new constraints the decision imposes on future work.

## Numbering and status

- Numbers are labels, not order-of-execution. Allocate the next free `NNNN`
  **within your branch's block** (see below).
- New ADR starts `Proposed`; becomes `Accepted` only after review.
- To reverse a decision, add a new ADR and set the old one's status to
  `Superseded by ADR-MMMM`. The superseded ADR stays in the tree.

## Number blocks

A stack branch inherits `main`'s ADRs when it merges, so both sets live in one
`docs/adr/`. One sequence for two scopes produces two `ADR-0001`s, and a prose
reference to "ADR-0001" then names nothing in particular. The number space is
partitioned instead:

| Block         | Scope                                                              | Branch                        |
| ------------- | ------------------------------------------------------------------ | ----------------------------- |
| `0001`-`0099` | Framework decisions: the governance layer, CI gates, workspace tooling | `main`                        |
| `0101`-`0199` | Stack decisions for the first stack branch                         | `demo/java-spring-payment-reconciliation` |
| `0201`-`0299` | Stack decisions for the next stack branch                          | a future demo                 |

These are all ADRs — same template, same lifecycle, same standard. Only the scope
of the decision differs, so the identifier stays `ADR-NNNN` and the block carries
the scope. A new stack branch claims the next free hundred and records it here.

`0100`, `0200` and so on are left unused, so a block boundary is visible at a
glance rather than inferred.

Enforced by `node tools/adr/check-numbering.mjs`: a duplicate number, a filename
that disagrees with its title, or a number outside every declared block fails the
build. A numbering rule nothing checks is a convention, not a control — which is
how two `ADR-0001`s reached `main` and a stack branch in the first place.

### Renumbering

Still forbidden, with one exception already spent. The rule exists to protect
references that have left the repository — links in pull requests, issues, forks.
When no such reference can exist, preserving an ambiguous number serves the
letter of the rule and not its purpose.

The stack ADRs were renumbered once into `0101`-`0105` when the blocks were
introduced, at a point where the repository had no forks and no outside
contributors. That exception is recorded here so it reads as a decision rather
than as precedent: after this, supersede.

## Approval

- Every ADR requires review and approval by the Architect role before `Accepted`.
- An ADR tracing a Compliance requirement (`Trace` includes an `NFR-6.*` ID)
  additionally requires Security-role sign-off, per the Complex-tier pipeline.

## Traceability

- `Trace` MUST reference at least one FR/NFR ID, or the literal `Infra`/`Testing`.
- Architecture docs that depend on a decision MUST link the ADR by number.
- A requirement whose design rests on an ADR SHOULD reference it from the Design
  Spec so the chain requirement → decision → code is navigable.
