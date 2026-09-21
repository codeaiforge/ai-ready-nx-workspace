# The SDLC controls gate

This workspace described tiered governance in `.ai/workflows/` but did not enforce it.
It now does: every pull request is tiered by
[`git-native-sdlc-controls@v0.2.0`](https://github.com/codeaiforge/git-native-sdlc-controls)
and emits a schema-valid `evidence/0` record.

<!-- local-only:start -->

Decision and rationale: [ADR-0001](adr/0001-adopt-git-native-sdlc-controls.md).

<!-- local-only:end -->

## How it runs

[`.github/workflows/sdlc-controls.yml`](../.github/workflows/sdlc-controls.yml), on
`pull_request` and on `pull_request_review` — approvals arrive after a PR is opened, so
a gate that only ran on open could never evaluate the approver controls against anything
but an empty set.

```
checkout refs/pull/N/head (fetch-depth: 0, the tier is computed against the merge base)
  → go install sdlc-controls@v0.2.0
  → __INSTALL__
  → node --test tools/sdlc-controls/*.test.mjs        (the adapter, before it is trusted)
  → __NX__ graph --file=$RUNNER_TEMP/graph.json
  → node generate-component-map.mjs > $RUNNER_TEMP/components.yaml
  → sdlc-controls binding --config …                  (the policy the decision is under)
  → gh api …/reviews → approver list
  → sdlc-controls tier --base origin/<base> --head <head sha> --approvers … --approvers-known
  → validate evidence.json against evidence/0
  → upload evidence.json + tier.txt                   (always, including on a block)
```

The gate is **additive**. `ci.yml` still runs lint, test, build and typecheck; this does
not replace them. It is a separate required check.

### Fail closed

| `tier` exit | Meaning             | Job    |
| ----------- | ------------------- | ------ |
| 0           | controls met        | passes |
| 1           | controls not met    | fails  |
| 2           | tool or usage error | fails  |

Exit 2 is never a pass. A gate that could not run has not cleared anything.

Evidence is uploaded on success **and** on failure. A gate that blocks a change without
leaving the record defeats the point of having a record.

### One pin, two artifacts

`SDLC_CONTROLS_VERSION: v0.2.0` in the workflow pins the binary. The evidence schema is
read from the **same** Go module at the same tag, out of the module cache — so the
schema a record is validated against cannot drift from the binary that produced it. The
last step of validation asserts that the record's own `tool.version` is `0.2.0`, which
proves the pin held all the way through.

## Where the component map comes from

Generated per run from the Nx project graph, never committed. See
[`tools/sdlc-controls/README.md`](../tools/sdlc-controls/README.md) and
[`config/sdlc-controls/criticality-tags.md`](../config/sdlc-controls/criticality-tags.md).

The honest summary: **topology is computed, criticality is declared.** Path globs and
`shared` come from the graph, so a high fan-in library cannot be under-tiered because
somebody forgot to flag it — which is the binary's stated ceiling for a hand-maintained
map. Criticality is still a human input. It is now a reviewed project tag instead of a
hand-edited YAML entry, which is better, but it is not automatic and this document does
not claim it is.

## Tier reconciliation — `T0`–`T3` is the risk tier

The binary is the **single authority on risk tier**. The pipeline in `.ai/workflows/`
reads it; it no longer declares one.

| Evidence `tier` | Pipeline     | Phases                   | Because the tier requires                  |
| --------------- | ------------ | ------------------------ | ------------------------------------------ |
| `T0`            | Light        | ① ③ ④ ⑧                  | 1 approver, lint                           |
| `T1`            | Standard     | ① ② ③ ④ ⑤ ⑧              | 1 approver, lint + sast                    |
| `T2`            | Standard + ⑥ | ① ② ③ ④ ⑤ ⑥ ⑧            | owning-team reviewer; secrets + deps scans |
| `T3`            | Complex      | ① – ⑧, human design gate | 2 approvers, **independent** approver      |

Two things this mapping deliberately does not do:

- **It adds no fifth tier and renames nothing.** Light/Standard/Complex are ceremony
  levels; `T0`–`T3` is blast radius. The table maps one onto the other.
- **It does not replace story points.** Story points are a planning estimate for
  _effort_. They were never a measurement of _risk_, and using them as one is what let a
  1-point change to an authentication module travel the Light path. Effort still sizes
  the work; the gate sets the tier.

The Phase ⑥ Security escalation stays an independent axis: a task touching auth,
database or AI runs Phase ⑥ whatever the gate says. The gate can only see paths, and a
change can be dangerous for reasons no path reveals. The two escalations compose — take
the stricter.

### Reading the tier

The tier is in the evidence record, downloadable from the PR's `sdlc-controls-evidence`
artifact, and printed in the job summary:

```sh
jq -r '.tier, .reasons[]' evidence.json
```

`reasons[]` is the ordered decision trail — which rule fired, in the order it applied.
Read it before arguing with the tier.

## AI provenance

Agent-authored commits carry CAF-SDLC-010 trailers, so the evidence record attributes
them. Convention and enforcement: [`.ai/standards/ai-provenance.md`](../.ai/standards/ai-provenance.md).

At **T3** the independent-approver control (CAF-SDLC-011) means an AI-authored change
cannot merge on its author's own approval. Note the precise scope, because it is easy to
oversell: the rule is attached to the _tier_, not to AI provenance. Every T3 change needs
an independent approver, AI-assisted or not, and an AI-assisted change at T0–T2 needs
none from this engine. And "independent" means a second forge account, not a second
human — tying accounts to people is the forge's job.

## Known gaps

These are stated rather than papered over.

### Direct pushes to the default branch are not tiered

The gate triggers on pull requests. A commit pushed straight to `main` is never tiered.
The fix is branch protection, not more workflow: require pull requests on `main` and
make `sdlc-controls / controls` a required check. Until that is set, the gate is
advisory for anyone with push access.

### Map governance cannot fire here

CAF-SDLC-002 self-escalates any change that edits the component map, on the principle
that the file deciding scrutiny should be the most scrutinised file in the repository.
Our map is generated into `$RUNNER_TEMP` and never committed, so it never appears in a
diff and that rule can never fire. Every evidence record carries the binary's warning
saying exactly that, which is true and should stay visible.

The compensation is that `tools/sdlc-controls/**` and `.github/workflows/sdlc-controls.yml`
are declared `criticality: critical`, so changing the code that decides tiers tiers at T3.
That is equivalent in effect and honest about being a substitute.

Writing the map into the working tree instead would make the warning disappear without
making the repository any safer — the generated file would be git-ignored, so it still
would not appear in a diff, and the rule still would not fire. A silent non-event is
worse than a visible one.

### Owners are not declared

The map emits no `owners`, because Nx has no owners concept in this workspace and there
is no `CODEOWNERS` file. At T2 and above the binary warns that it cannot verify an
owning-team reviewer and names no owners. When `CODEOWNERS` exists, map it into the
generator and the warning becomes useful.

## Findings against the map schema

`evidence/0` and the map schema are deliberately experimental at major version 0, to
collect exactly this kind of feedback from real consumers. Recorded here; **not** worked
around by patching the engine.

1. **`shared` is a boolean where the graph has a count.** A library with 3 dependents
   and one with 300 both emit `shared: true` and both escalate by exactly one tier. This
   workspace computes real fan-in and has nowhere to put it. A `fan_in: <int>` field, or
   a `shared` that accepts a threshold, would let a graph-backed caller pass through what
   it actually knows.
2. **A generated map cannot be governed.** The map-governance rule assumes the map is a
   committed file. For a caller that projects the map from a build graph, governance
   should attach to the _generator_, which the schema cannot express — there is no way
   for a map to say "the thing that produced me lives at this path". Today the caller
   has to smuggle that in as an ordinary `critical` component, which works but reads as
   an unrelated declaration.

Neither blocks adoption. Both are the kind of thing a second consumer would hit.
