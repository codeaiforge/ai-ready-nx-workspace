# `sdlc-controls` adapter

Generates the component map that
[`git-native-sdlc-controls@v0.2.0`](https://github.com/codeaiforge/git-native-sdlc-controls)
tiers this repository's pull requests against.

| File                           | What it is                                                     |
| ------------------------------ | -------------------------------------------------------------- |
| `generate-component-map.mjs`   | Nx project graph → `components.yaml`. Pure, deterministic.      |
| `generate-component-map.test.mjs` | Unit tests over fixture graphs (`node --test`).              |
| `acceptance.sh`                | End-to-end gate behaviour against the real binary.              |

## Why this exists

The binary tiers a change by matching its diff against a declared component map. Its
documented ceiling is that the map is hand-maintained: *"a high fan-in component that
nobody declared `shared: true` will be under-tiered"* (CAF-SDLC-002). That ceiling is
real for a generic repository. It is not real here — this workspace has a computed
project graph, so topology does not have to be remembered.

So the map is a **projection of the graph**, regenerated on every CI run, never
committed. Topology is computed; criticality is read from reviewed project tags. See
[`config/sdlc-controls/criticality-tags.md`](../../config/sdlc-controls/criticality-tags.md).

The adapter lives here and only here. Nothing about Nx leaks into the binary — it
accepts a component map, and where that map comes from is the caller's business.

## Run it locally

```sh
go install github.com/codeaiforge/git-native-sdlc-controls/cmd/sdlc-controls@v0.2.0

pnpm nx graph --file=graph.json
node tools/sdlc-controls/generate-component-map.mjs graph.json > /tmp/components.yaml

# the map is valid and this is the policy it will be tiered under
sdlc-controls binding --config /tmp/components.yaml

# tier your branch the way CI will
sdlc-controls tier --base origin/main --head HEAD \
  --config /tmp/components.yaml --evidence-out /tmp/evidence.json
```

`tier` exits 0 when the controls are met, 1 when they are not, and 2 on a tool error.
CI fails on 1 **and** 2: a gate that could not run has not cleared anything.

Locally the approver controls are recorded but not verified, because there is no
approver set to read — the record says so rather than passing them silently. CI passes
`--approvers`/`--approvers-known` from the GitHub review API.

## Tests

```sh
node --test "tools/sdlc-controls/*.test.mjs"   # adapter, no binary needed
tools/sdlc-controls/acceptance.sh              # gate behaviour, needs the binary on PATH
```

`acceptance.sh` builds a throwaway repository with a fixture graph and asserts the
things that actually matter: a leaf change tiers T0 and passes, a high fan-in library
escalates even though it is tagged `low`, a change to the critical project tiers T3 and
blocks on a single self-approval, an AI-authored T3 change blocks without an independent
approver and passes with one, provenance round-trips into the evidence record, and an
unreadable map exits 2 rather than 0.

## Changing this directory

`tools/sdlc-controls/**` is declared `criticality: critical` in the map it generates, so
any change here tiers at T3 and needs two independent approvers.

That is not decoration. The binary normally self-escalates changes to its component map,
because the file that decides how much scrutiny a change gets should be the most
scrutinised file in the repository. Our map is generated and never committed, so it
never appears in a diff and that rule can never fire. Declaring the generator `critical`
puts the rule back where it belongs — on the code that decides the tiers.
