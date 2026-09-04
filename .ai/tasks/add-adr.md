# Task: Add ADR

## Purpose

Create and approve a new Architectural Decision Record for a significant architectural
choice, so the decision, its alternatives, and its consequences are on record and traceable.

## Steps

1. Copy `docs/adr/0000-template.md` to `docs/adr/NNNN-short-slug.md`, using the next free
   number (real ADRs start at `0001`). Delete the template comment block.
2. Fill every section per `.ai/standards/adr.md` — the single source of truth for format,
   numbering, lifecycle, and traceability. Do not substitute another format.
3. Set `Trace` to the FR/NFR ID(s) the decision serves (or `Infra`/`Testing`). Set `Status`
   to `Proposed`.
4. Review with the Architect role. An ADR whose `Trace` includes an `NFR-6.*` (Compliance) ID
   additionally requires Security-role sign-off, per the Complex-tier pipeline.
5. On approval, set `Status` to `Accepted`. Link the ADR by number from the architecture doc
   (and any Design Spec) that depends on it.
  
## Acceptance Criteria

- ADR is approved, documented, and referenced.
