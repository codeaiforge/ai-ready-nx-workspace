<!--
  Requirements Specification Template
  -----------------------------------
  Preserve the structure, heading levels, and field names exactly — downstream
  tooling (roadmap Trace column, task-brief resolution in
  .ai/prompts/analyze-task.md) depends on the format. Diverge only at the
  placeholder slots marked with `{{double-braces}}` (mustache style).

  Authoring rules:
  1. Every FR/NFR MUST pick ONE EARS pattern from the reference table and tag
     it in the heading: ### FR-N.M: Name `[Pattern]`.
  2. Every FR/NFR MUST have a single sentence in the EARS shape that matches
     the pattern, followed by an Acceptance Criteria checklist.
  3. Acceptance Criteria MUST be testable (measurable, observable). Avoid
     "user should feel" / "reasonably fast" / "clean UI" — those are not ACs.
  4. Group P0 (must-ship) FRs in numbered sections 1..N; group P1 (should-ship
     if possible) after. P2+ belongs in a later version of the spec.
  5. NFR-6.* traces to GDPR/compliance and triggers Complex-tier task review
     per .ai/workflows/tier-standard.md — don't add NFR-6 lightly.
  6. The Traceability table at the bottom MUST list every FR/NFR range and
     must stay in sync with the body. Run a sync check in review.
  7. Delete the template comment blocks (like this one) before committing
     the real spec. Keep the EARS Pattern Reference section — it's
     load-bearing and must appear verbatim in every concrete spec.
-->

# {{Project}} {{Phase}} Requirements Specification

**Version**: {{X.Y — Month YYYY}}
**Methodology**: EARS (Easy Approach to Requirements Syntax)
**Scope**: {{Phase or release name}} — {{priority bands included, e.g. "P0 and P1 only"}}

---

## EARS Pattern Reference

| Pattern | Template | Use when |
| ------- | -------- | -------- |
| Ubiquitous | The system shall [action] | Requirement is always active |
| Event-driven | When [event], the system shall [action] | Triggered by a specific event |
| State-driven | While [state], the system shall [action] | Active during a specific state |
| Unwanted behavior | If [unwanted condition], the system shall [action] | Handling failures or edge cases |
| Optional | Where [feature is included], the system shall [action] | Configurable or conditional |
| Complex | Combination of patterns above | Multiple conditions apply |

---

<!--
  Functional Requirements (FR)
  ----------------------------
  Group into numbered sections, one section per feature area. Each section
  header names the feature + priority band: `## N. Feature Name (P0|P1)`.

  Inside each section, emit one `### FR-N.M: Name [Pattern]` block per
  requirement. Number FRs within a section starting at 1. Never renumber an
  FR after it's traced from a task — downstream references break.
-->

## 1. {{Feature Area Name}} (P0)

### FR-1.1: {{Requirement Name}} `[Event-driven]`

When {{event}}, the system shall {{observable action}}.

**Acceptance Criteria:**

- [ ] {{Testable criterion 1 — measurable or observable}}
- [ ] {{Testable criterion 2}}
- [ ] {{Testable criterion 3}}

### FR-1.2: {{Requirement Name}} `[State-driven]`

While {{state}}, the system shall {{observable action}}.

**Acceptance Criteria:**

- [ ] {{Testable criterion 1}}
- [ ] {{Testable criterion 2}}

### FR-1.3: {{Requirement Name}} `[Ubiquitous]`

The system shall {{observable action that is always active}}.

**Acceptance Criteria:**

- [ ] {{Testable criterion 1}}
- [ ] {{Testable criterion 2}}

<!-- Duplicate the FR-1.M block as many times as needed for this feature area. -->

---

## 2. {{Next Feature Area Name}} (P0)

### FR-2.1: {{Requirement Name}} `[Event-driven]`

When {{event}}, the system shall {{observable action}}.

**Acceptance Criteria:**

- [ ] {{Testable criterion 1}}
- [ ] {{Testable criterion 2}}

### FR-2.2: {{Requirement Name}} `[Unwanted behavior]`

If {{unwanted condition}}, the system shall {{observable recovery or rejection action}}.

**Acceptance Criteria:**

- [ ] {{Testable criterion 1}}
- [ ] {{Testable criterion 2}}

### FR-2.3: {{Requirement Name}} `[Optional]`

Where {{feature or plan is included}}, the system shall {{observable conditional action}}.

**Acceptance Criteria:**

- [ ] {{Testable criterion 1}}
- [ ] {{Testable criterion 2}}

<!--
  Continue with `## 3.`, `## 4.`, ... for every P0 feature area.
  Then `## N.` for each P1 feature area, with the `(P1)` suffix in the header.
  Do not mix P0 and P1 within the same numbered section.
-->

---

## {{N}}. {{P1 Feature Area Name}} (P1)

### FR-{{N}}.1: {{Requirement Name}} `[Event-driven]`

When {{event}}, the system shall {{observable action}}.

**Acceptance Criteria:**

- [ ] {{Testable criterion 1}}
- [ ] {{Testable criterion 2}}

---

<!--
  Non-Functional Requirements (NFR)
  ---------------------------------
  Grouped by category. Six canonical categories — include every category that
  applies; omit ones that do not. Use `### NFR-{{n}}: {{Category}}` for the group
  header and `#### NFR-{{n}}.{{m}}: {{Name}}` for each requirement. Sub-heading level
  differs from FR intentionally — FRs are flat (### only), NFRs nest once.

  Canonical categories (keep the numbering stable across versions):
    NFR-1 Performance
    NFR-2 Security
    NFR-3 Reliability
    NFR-4 Usability
    NFR-5 Scalability
    NFR-6 Compliance
  Add new NFR-N groups at the end; never reorder existing ones.
-->

## {{M}}. Non-Functional Requirements

### NFR-1: Performance

#### NFR-1.1: {{Name}} `[Ubiquitous]`

The system shall {{observable performance guarantee with quantified threshold}}.

**Acceptance Criteria:**

- [ ] {{Measurable criterion with number + unit}}
- [ ] {{Measurable criterion with number + unit}}

#### NFR-1.2: {{Name}} `[Event-driven]`

When {{event}}, the system shall {{response with quantified threshold}}.

**Acceptance Criteria:**

- [ ] {{Measurable criterion}}
- [ ] {{Measurable criterion}}

### NFR-2: Security

#### NFR-2.1: {{Name}} `[Ubiquitous]`

The system shall {{security guarantee}}.

**Acceptance Criteria:**

- [ ] {{Testable security criterion}}
- [ ] {{Testable security criterion}}

### NFR-3: Reliability

#### NFR-3.1: {{Name}} `[Ubiquitous]`

The system shall {{reliability / uptime guarantee with quantified target}}.

**Acceptance Criteria:**

- [ ] {{Measurable criterion}}
- [ ] {{Measurable criterion}}

### NFR-4: Usability

#### NFR-4.1: {{Name}} `[Ubiquitous]`

The system shall {{usability guarantee}}.

**Acceptance Criteria:**

- [ ] {{Testable criterion}}
- [ ] {{Testable criterion}}

### NFR-5: Scalability

#### NFR-5.1: {{Name}} `[Ubiquitous]`

The system shall {{scalability guarantee with quantified target}}.

**Acceptance Criteria:**

- [ ] {{Measurable criterion}}
- [ ] {{Measurable criterion}}

### NFR-6: Compliance

<!--
  WARNING: NFR-6.* requirements trigger Complex-tier task classification per
  .ai/workflows/tier-standard.md override rules. Every task whose Trace column
  includes an NFR-6.* entry gets the full 8-phase pipeline (Design + Security
  gates mandatory). Add NFR-6 requirements only when compliance is actually
  in scope — do not sprinkle them for "feels more serious" signal.
-->

#### NFR-6.1: {{Name}} `[Ubiquitous]`

The system shall {{compliance guarantee citing the specific regulation}}.

**Acceptance Criteria:**

- [ ] {{Regulation-specific criterion}}
- [ ] {{Regulation-specific criterion}}

---

## Requirement Traceability

<!--
  Keep this table in exact sync with the body. Reviewers check it as part of
  the FR/NFR review — a missing or drifted row is a blocker.

  `Requirement ID` column uses ID ranges (e.g. FR-1.1–1.5). When a new FR is
  added to an existing section, update the range in place.
  `Dependencies` column uses `None` or an FR-range (e.g. `FR-1.x (input)`).
-->

| Requirement ID | Feature | Priority | Dependencies |
| -------------- | ------- | -------- | ------------ |
| FR-1.1–1.{{last}} | {{Feature Area 1}} | P0 | {{None or FR-range}} |
| FR-2.1–2.{{last}} | {{Feature Area 2}} | P0 | {{FR-range}} |
| FR-{{N}}.1–{{N}}.{{last}} | {{P1 Feature Area}} | P1 | {{FR-range}} |
| NFR-1.1–1.{{last}} | Performance | — | All FR |
| NFR-2.1–2.{{last}} | Security | — | All FR |
| NFR-3.1–3.{{last}} | Reliability | — | All FR |
| NFR-4.1–4.{{last}} | Usability | — | All FR |
| NFR-5.1–5.{{last}} | Scalability | — | All FR |
| NFR-6.1–6.{{last}} | Compliance | — | NFR-2.x (security) |

---

*Version {{X.Y}} — {{Month YYYY}}*
*Next review: {{trigger, e.g. "after technical design completion" or "end of Sprint N"}}*
