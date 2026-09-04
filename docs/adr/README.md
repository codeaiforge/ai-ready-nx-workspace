# Architectural Decision Records (ADR)

This folder contains all Architectural Decision Records documenting key architectural choices and their rationale.

## Format — single source of truth

The required ADR format, numbering, lifecycle, and traceability rules are defined in
[`.ai/standards/adr.md`](../../.ai/standards/adr.md). Follow that standard exactly — do
not substitute another format. It is MADR-derived.

To create a new ADR, copy [`0000-template.md`](0000-template.md), rename it to the next
free number (`NNNN-short-slug.md`, real ADRs start at `0001`), and fill it in.

## Conventions

- One ADR per significant architectural decision.
- `0000-template.md` is the reserved skeleton — never a real decision, never renumbered.
- Every ADR links to the requirement(s) it serves (its `Trace`) and, where relevant, to
  the architecture doc and diagrams that depend on it.
- ADRs are append-only: to reverse a decision, add a new ADR and mark the old one
  `Superseded by ADR-MMMM`. Nothing is deleted.