# Criticality tags and the fan-in threshold

The PR gate tiers every change with
[`git-native-sdlc-controls@v0.2.0`](https://github.com/codeaiforge/git-native-sdlc-controls).
That binary reads a **component map**: for each component, which paths it owns, how
business-critical it is, and whether it is shared. This workspace does not keep that
map by hand — it generates it from the Nx project graph on every run
([`tools/sdlc-controls/generate-component-map.mjs`](../../tools/sdlc-controls/generate-component-map.mjs)).

Two inputs, two different kinds of truth:

| Map field         | Where it comes from            | Who can change it                    |
| ----------------- | ------------------------------ | ------------------------------------ |
| `match` (paths)   | project `root` / `sourceRoot`  | computed — moving a project moves it |
| `shared` (fan-in) | inverted dependency edges      | computed — nobody sets it            |
| `criticality`     | a `criticality:` project tag   | **declared, and reviewed in the PR** |

That split is deliberate. Topology is a fact about the graph and a machine should read
it. Business criticality is a judgement about consequences, and no graph knows it — a
utility everything imports is not automatically business-critical, and a payments module
nothing imports yet still is. So criticality stays a human declaration; what changed is
that it is now declared as a reviewed tag rather than hand-edited into a YAML file
nobody re-reads.

## The tag

Tag every Nx project in its `project.json` (or `nx.json` target defaults):

```jsonc
{
  "name": "payments-api",
  "tags": ["scope:payments", "criticality:critical"]
}
```

| Tag                    | Base tier | Use for                                                               |
| ---------------------- | --------- | --------------------------------------------------------------------- |
| `criticality:low`      | T0        | Marketing pages, examples, fixtures, docs tooling                     |
| `criticality:medium`   | T1        | Internal tools, non-customer-facing services                          |
| `criticality:high`     | T2        | Customer-facing services, anything holding user data                  |
| `criticality:critical` | T3        | Money, authentication, authorisation, PII, regulated data, migrations |

Rules the generator enforces, so a typo cannot quietly under-tier a change:

- A value outside `low|medium|high|critical` **fails the run**. `criticality:critcal`
  would otherwise be read as "no tag" and tier a critical project at the default.
- Two `criticality:` tags on one project **fails the run**. There is no tie-break that
  is not a guess.

### Untagged projects default to `high`

A project with no `criticality:` tag is mapped to **`high`** (base T2), not to `low`.

This is deliberately inconvenient. The alternative — defaulting to `low` — means the
one thing a team forgets to do (tag a new project) is also the thing that makes the
gate stop looking at it. Defaulting high matches the binary's own escalation
philosophy, where an unmatched path is floored at `high` rather than waved through.
Tag your project and the tier drops; forget, and it is treated as consequential.

## The fan-in threshold

A project that **3 or more** other projects depend on is emitted as `shared: true`,
which escalates its tier by one.

The number lives in `SHARED_FANIN_THRESHOLD` in the generator — a constant, not an
environment variable and not a config file. The value that decides how much scrutiny a
change gets must not be adjustable by a CI variable nobody reviews. Changing it means
editing the generator, which appears in a pull request and, because the generator is
declared `critical` in the map, is itself tiered at the top.

Counting rules: only edges to other projects in this workspace count (npm packages are
not components), and one dependent counts once however many files it imports from.

### What `shared` cannot express

The map's `shared` is a boolean; real fan-in is a count. A library with 3 dependents and
one with 300 are both `shared: true` and both escalate by exactly one tier. The graph
knows the difference and the map has nowhere to put it. This is recorded as a finding
against the map schema in
[`docs/sdlc-controls-integration.md`](../../docs/sdlc-controls-integration.md#findings-against-the-map-schema) —
it is not worked around here.

## Paths that are not Nx projects

This workspace is mostly *not* Nx projects: `.ai/`, `docs/`, `.github/`, the agent
folders and the root config are the substance of it. Those are declared in a short table
(`WORKSPACE_COMPONENTS`) in the generator, reviewed in the pull request that changes it —
the same human checkpoint the tags get, for paths the project graph does not model.

It is kept short on purpose, and anything it does not claim is still floored at `high`
by `unmatched_path_tier`. Adding a component there is a declaration about consequences
and should be reviewed as one.
