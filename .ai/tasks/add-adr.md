# Task: Add ADR

## Purpose

Create and approve a new Architectural Decision Record for a significant architectural
choice, so the decision, its alternatives, and its consequences are on record and traceable.

## Steps

1. Copy `docs/adr/0000-template.md` to `docs/adr/NNNN-short-slug.md`, using the next free
   number.
   <!-- local-only:start -->
   Take it **from your branch's block** — `0001`-`0099` on `main` for framework decisions,
   `0101`-`0199` on the first stack branch, per the table in `.ai/standards/adr.md`.
   <!-- local-only:end -->
   Delete the template comment block.
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
<!-- local-only:start -->
- `node tools/adr/check-numbering.mjs` passes: the number is unused, sits inside the
branch's block, and matches the `# ADR-NNNN:` heading in the file.
<!-- local-only:end -->
