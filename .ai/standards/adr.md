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

- Numbers are labels, not order-of-execution. Allocate the next free `NNNN`.
- New ADR starts `Proposed`; becomes `Accepted` only after review.
- To reverse a decision, add a new ADR and set the old one's status to
  `Superseded by ADR-MMMM`. The superseded ADR stays in the tree.

## Approval

- Every ADR requires review and approval by the Architect role before `Accepted`.
- An ADR tracing a Compliance requirement (`Trace` includes an `NFR-6.*` ID)
  additionally requires Security-role sign-off, per the Complex-tier pipeline.

## Traceability

- `Trace` MUST reference at least one FR/NFR ID, or the literal `Infra`/`Testing`.
- Architecture docs that depend on a decision MUST link the ADR by number.
- A requirement whose design rests on an ADR SHOULD reference it from the Design
  Spec so the chain requirement → decision → code is navigable.
