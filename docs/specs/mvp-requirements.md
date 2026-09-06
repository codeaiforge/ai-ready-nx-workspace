# Payment Reconciliation Service — MVP Requirements Specification

**Version**: 0.1 — September 2026
**Methodology**: EARS (Easy Approach to Requirements Syntax)
**Scope**: MVP — P0 and P1 only
**Target platform**: Java 25 / Spring Boot 4 microservice (see `docs/specs/stack.md`)

---

## EARS Pattern Reference

| Pattern           | Template                                               | Use when                        |
| ----------------- | ------------------------------------------------------ | ------------------------------- |
| Ubiquitous        | The system shall [action]                              | Requirement is always active    |
| Event-driven      | When [event], the system shall [action]                | Triggered by a specific event   |
| State-driven      | While [state], the system shall [action]               | Active during a specific state  |
| Unwanted behavior | If [unwanted condition], the system shall [action]     | Handling failures or edge cases |
| Optional          | Where [feature is included], the system shall [action] | Configurable or conditional     |
| Complex           | Combination of patterns above                          | Multiple conditions apply       |

---

## 1. Transaction Ingestion (P0)

### FR-1.1: Ingest settlement file `[Event-driven]`

When a settlement file is delivered to the ingestion endpoint, the system shall parse each row into a normalized transaction record and persist it with a unique ingestion ID.

**Acceptance Criteria:**

- [ ] A well-formed 10,000-row file is fully ingested and each row is retrievable by ingestion ID
- [ ] Parse errors on a row are recorded against that row without aborting the file
- [ ] Duplicate delivery of the same file (same checksum) is rejected with a logged reason

### FR-1.2: Normalize currency and amount `[Ubiquitous]`

The system shall store every monetary amount as an integer minor unit with an ISO-4217 currency code.

**Acceptance Criteria:**

- [ ] Amounts are stored as integers (no floating-point currency in the store)
- [ ] A row with an unrecognized currency code is quarantined, not persisted as valid

## 2. Reconciliation Matching (P0)

### FR-2.1: Match ledger to settlement `[Event-driven]`

When a batch completes ingestion, the system shall match each internal ledger entry to a settlement transaction on amount, currency, and value date within a configurable tolerance window.

**Acceptance Criteria:**

- [ ] A perfectly matching pair is marked `matched` with both source IDs linked
- [ ] A near-match within tolerance is marked `matched_within_tolerance` with the delta recorded
- [ ] Match runs are deterministic: the same inputs produce the same match set

### FR-2.2: Raise reconciliation exception `[Unwanted behavior]`

If a ledger entry has no settlement counterpart after a match run, the system shall raise a reconciliation exception with a category and route it to the exception queue.

**Acceptance Criteria:**

- [ ] An unmatched entry produces exactly one exception with a category (`missing`, `amount_mismatch`, `duplicate`)
- [ ] The exception carries enough context to action it without opening the raw file

### FR-2.3: Manual match override `[Optional]`

Where an operator has the reconciler role, the system shall allow manually linking a ledger entry to a settlement transaction and shall record who did so and when.

**Acceptance Criteria:**

- [ ] A manual match records operator ID and timestamp on the resulting link
- [ ] A manual match over a monetary delta above the auto-tolerance requires a second approver

## 3. Exception Workflow (P0)

### FR-3.1: Assign and resolve exceptions `[State-driven]`

While an exception is in the `open` state, the system shall allow assignment to an operator and transition to `resolved` only with a recorded resolution reason.

**Acceptance Criteria:**

- [ ] An exception cannot reach `resolved` without a non-empty resolution reason
- [ ] State transitions are append-only and individually timestamped

## 4. Reporting (P1)

### FR-4.1: Daily reconciliation summary `[Event-driven]`

When a reconciliation day closes, the system shall produce a summary of matched value, unmatched value, and open-exception count by category.

**Acceptance Criteria:**

- [ ] Summary totals reconcile to the sum of the underlying records
- [ ] The summary is retrievable for any past closed day

---

## 5. Non-Functional Requirements

### NFR-1: Performance

#### NFR-1.1: Match throughput `[Ubiquitous]`

The system shall complete a reconciliation match run of 1,000,000 record pairs within 10 minutes.

**Acceptance Criteria:**

- [ ] A 1M-pair run completes in ≤ 600 seconds on the reference environment
- [ ] Match latency is reported per run for trend tracking

### NFR-2: Security

#### NFR-2.1: Access control `[Ubiquitous]`

The system shall restrict every reconciliation and override action to an authenticated operator holding the required role.

**Acceptance Criteria:**

- [ ] An unauthenticated request to any mutating endpoint is rejected with 401
- [ ] An authenticated operator without the reconciler role is rejected with 403 on override

### NFR-3: Reliability

#### NFR-3.1: Ingestion durability `[Ubiquitous]`

The system shall guarantee that an acknowledged ingestion is durable across a process restart.

**Acceptance Criteria:**

- [ ] A file acknowledged then followed by a restart is not re-requested and not lost
- [ ] Recovery after restart requires no manual intervention

### NFR-6: Compliance

#### NFR-6.1: Auditable financial trail `[Ubiquitous]`

The system shall maintain an immutable, timestamped audit record of every match, override, and exception resolution, retained for the period required by applicable financial-record regulation.

**Acceptance Criteria:**

- [ ] Every mutating action appends an audit record that cannot be edited or deleted through the application
- [ ] The audit trail for any transaction is reconstructable end to end from ingestion to resolution
- [ ] Retention duration is configurable and enforced

---

## Requirement Traceability

| Requirement ID | Feature                 | Priority | Dependencies        |
| -------------- | ----------------------- | -------- | ------------------- |
| FR-1.1–1.2     | Transaction Ingestion   | P0       | None                |
| FR-2.1–2.3     | Reconciliation Matching | P0       | FR-1.x (input)      |
| FR-3.1         | Exception Workflow      | P0       | FR-2.x (exceptions) |
| FR-4.1         | Reporting               | P1       | FR-2.x, FR-3.x      |
| NFR-1.1        | Performance             | —        | All FR              |
| NFR-2.1        | Security                | —        | All FR              |
| NFR-3.1        | Reliability             | —        | All FR              |
| NFR-6.1        | Compliance              | —        | NFR-2.x (security)  |

---

_Version 0.1 — September 2026_
_Next review: after technical design completion_
