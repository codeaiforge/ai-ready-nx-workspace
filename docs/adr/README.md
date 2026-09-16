# Architectural Decision Records (ADR)

This folder contains all Architectural Decision Records documenting key architectural choices and their rationale.

## Format — single source of truth

The required ADR format, numbering, lifecycle, and traceability rules are defined in
[`.ai/standards/adr.md`](../../.ai/standards/adr.md). Follow that standard exactly — do
not substitute another format. It is MADR-derived.

To create a new ADR, copy [`0000-template.md`](0000-template.md), rename it to the next
free number **within your branch's block** (`NNNN-short-slug.md`, real ADRs start at
`0001`), and fill it in.

Numbers are partitioned so a stack branch that merges `main` does not end up with two
`ADR-0001`s: `0001`-`0099` is `main`'s, for framework decisions; `0101`-`0199` belongs to
the first stack branch, and so on. They are all ADRs — the block carries the scope, not a
different document type. The table lives in
[`.ai/standards/adr.md`](../../.ai/standards/adr.md) and is enforced by
`node tools/adr/check-numbering.mjs`.

## Conventions

- One ADR per significant architectural decision.
- `0000-template.md` is the reserved skeleton — never a real decision, never renumbered.
- Every ADR links to the requirement(s) it serves (its `Trace`) and, where relevant, to
  the architecture doc and diagrams that depend on it.
- ADRs are append-only: to reverse a decision, add a new ADR and mark the old one
  `Superseded by ADR-MMMM`. Nothing is deleted.