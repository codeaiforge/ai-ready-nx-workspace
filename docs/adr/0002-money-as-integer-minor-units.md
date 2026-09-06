# ADR-0002: Represent money as integer minor units with an explicit currency

- **Status**: Accepted
- **Date**: 2026-09-06
- **Deciders**: Architect, Database Engineer
- **Trace**: FR-1.2, FR-2.1, NFR-6.1

## Context

Reconciliation decides whether two amounts are the same. That comparison is the product:
a false inequality raises an exception a human must investigate, and a false equality hides
a real break.

Binary floating point cannot represent most decimal fractions exactly, so `0.1 + 0.2` is not
`0.3`. Amounts that arrive from different systems — a ledger export and a settlement file —
can therefore differ by a rounding artefact that is indistinguishable, downstream, from a
genuine discrepancy. Currency compounds it: adding an amount in EUR to one in USD is always
a defect, but nothing in a bare numeric type says so.

## Decision

We will represent monetary amounts as a `Money` value object holding a `long` of **integer
minor units** (cents, pence) together with an ISO-4217 `Currency`. No floating-point type
appears in any monetary path. Arithmetic across differing currencies raises rather than
coercing, and overflow raises rather than wrapping.

## Options Considered

- **Option A — integer minor units + currency (chosen)**: exact, comparable with `equals`,
  and maps cleanly to a `BIGINT` column. Costs an explicit scale convention per currency and
  makes the caller state the currency. A `long` bounds the representable amount, which for
  minor units is far beyond any plausible settlement value.
- **Option B — `BigDecimal` with a scale**: exact and handles arbitrary magnitude, but
  equality is a trap — `BigDecimal.equals` compares scale, so `1.50` and `1.5` are unequal
  while `compareTo` says otherwise. In a system whose core operation is equality, that is a
  defect waiting to be written.
- **Option C — `double`**: rejected outright. The failure is silent, data-dependent, and
  surfaces as phantom reconciliation breaks.

## Consequences

Amount comparison becomes exact and total, which is what the matching engine (FR-2.1) needs,
and persistence is a plain `BIGINT` with no scale ambiguity — relevant to the auditable
trail required by NFR-6.1.

In exchange, every boundary that accepts an amount must declare a currency and a scale.
Parsing settlement rows into `Money` is therefore real work rather than a cast, and that
conversion is where scale errors will concentrate — it needs tests at the boundary, not
just on the arithmetic.

Cross-currency addition throwing means callers must handle currency mismatch explicitly.
That is deliberate: silently coercing is how cross-currency bugs reach production.
