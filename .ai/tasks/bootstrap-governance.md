# Task: Bootstrap governance into a repository

## Purpose

Install this workspace's portable authority layers — `AGENTS.md`, `.ai/`, and the thin
agent adapters — into another repository, optionally with the SDLC-controls PR gate. The
script creates the layers; it does not invent architecture, and it never silently
overwrites a file someone else wrote.

## Steps

1. Dry-run first. The script writes nothing without `--apply`, so start by reading the
   plan:

   ```sh
   scripts/bootstrap-ai-governance.sh --target ../other-repo
   ```

2. Read the per-file status. This is the part worth slowing down on:

   - `CREATE` — not there yet, will be written.
   - `CURRENT` — already byte-identical to what this script installs. Nothing to do.
   - `STALE` — exists but **differs**. Left alone. Either the target customised it or the
     target was bootstrapped before this script changed.

3. Choose the adapters. `--adapters` defaults to `codex`.

4. Decide whether you also want the gate. `.ai/` is the governance layer this script
   exists to install, so **all of it ships by default** — standards, roles, tasks,
   prompts, the provenance standard and the `commit-msg` hook that enforces it. That
   works on any repository, Nx or not.

   `--with-sdlc-controls` adds the PR risk gate and the tiered pipeline it selects
   (`.ai/workflows/`). It requires `--kind nx`, because the component map is generated
   from the Nx project graph.

   | Profile                 | Files                                                                                                                                                                    | Needs Nx |
   | ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------- |
   | default, generic target | ~64 — `AGENTS.md`, all of `.ai/`, the provenance hook, the git workflow, commit conventions, the ADR standard with its template and numbering check, `docs/` scaffolding | no       |
   | default, Nx target      | ~73 — adds the requested adapters' real content, their root config (`CLAUDE.md`, `opencode.json`), and the `.github/prompts/` store                                      | –        |
   | `--with-sdlc-controls`  | ~85 — adds the gate and `.ai/workflows/`                                                                                                                                 | **yes**  |

   `--adapters` takes `codex`, `claude`, `gemini`, `cursor`, `opencode`, `copilot`.
   `copilot` reads `.github/skills/` and `.github/agents/` rather than a dotted directory.
   All six plus the gate installs ~118 files.

   Adapter content ships only for an Nx target. This workspace's adapters are Nx-flavoured
   throughout — plugin config, an `nx-workspace` skill, graph-aware commands — so a generic
   target gets the pointer README instead of content describing a build system it does not
   use. `monitor-ci` is never shipped: it drives Nx Cloud, which this workspace removed from
   its own CI.

   The manifest is derived from this repository rather than listed, so a governance file
   added here reaches bootstrapped repositories without editing the script. Two short
   carve-outs sit at the top of it:

   - **Never ships** — `.ai/tasks/bootstrap-governance.md` (documents this script),
     `.ai/standards/adr.md` and `.ai/tasks/add-adr.md` (this workspace's own ADR block
     table and branch names, enforced by `tools/adr/`, which is not installed),
     `.ai/context/nx-workspace.md` (superseded by the `workspace.md` written per
     `--kind`), and `.ai/sprints/README.md` (documents a format owned by
     `.github/prompts/`, which is not installed).
   - **Needs the gate** — `.ai/workflows/*`. Each tier file is "what to do when the gate
     says `T0`/`T1`/`T2`/`T3`" and links to its integration doc, so shipping them without
     the gate would ship dangling links.

   A file that needs an entry in either list is usually a file that should have been
   written to be portable. Prefer a block marker to a carve-out: a
   `<!-- local-only:start -->` … `<!-- local-only:end -->` block is stripped from every
   install, and a `<!-- gate-only:… -->` block is stripped unless the gate is installed.
   That is how `.ai/standards/adr.md` ships its MADR format and lifecycle while keeping
   this workspace's ADR block table and renumbering history at home. The markers
   themselves never reach a target. `scripts/check-template-drift.sh` installs both profiles for
   real and link-checks them, so a carve-out that breaks the other profile fails CI.

   `--package-manager` is detected from the lockfile; pass `npm` or `pnpm` explicitly
   when there is no lockfile yet. `--kind` defaults to `auto` (detects `nx.json`).

   Installed files keep their `{placeholder}` tokens — `{package-manager}`, `{ci-tool}`,
   `{requirements-doc}` and the rest. They are the set's own documented fill-ins, listed
   in `.ai/prompts/README.md`. Replace them in the target as part of adoption.

5. Apply:

   ```sh
   scripts/bootstrap-ai-governance.sh --target ../other-repo --kind nx \
     --adapters codex,claude --with-sdlc-controls --apply
   ```

6. Resolve anything reported `STALE`. Diff it against the version here before deciding.
   `--apply --force` takes this script's version and **discards the target's local edits**,
   so it is a decision, not a default. It rewrites only the files that actually differ.

7. Finish the gate by hand, in the target repository. Installing a workflow does not
   enforce anything on its own:

   ```sh
   git config core.hooksPath .githooks   # enable the provenance hook, once per clone
   ```

   Then protect the default branch and make the `sdlc-controls` check required. See
   `docs/sdlc-controls-integration.md`.

8. Re-run later to find drift. `--check` is read-only and exits non-zero when a managed
   file is missing or differs, which is what a bootstrapped repository puts in its own CI:

   ```sh
   scripts/bootstrap-ai-governance.sh --target . --with-sdlc-controls --check
   ```

## Acceptance Criteria

- The dry run was read before `--apply`, and every `STALE` file was diffed and decided on
  rather than force-overwritten by reflex.
- `scripts/bootstrap-ai-governance.sh --target <repo> [...] --check` exits 0.
- With `--with-sdlc-controls`: `node --test tools/sdlc-controls/*.test.mjs` passes in the
  target, `core.hooksPath` is set, and the `sdlc-controls` check is required on the
  default branch.

## Maintaining what ships

Almost everything the script installs is read straight out of this repository at run
time — the adapter, its tests and README, the hook, the criticality and provenance
standards, and the whole `.ai/` cluster. There is no second copy to keep in step: edit
the original and the next bootstrap ships the edit. This is why `scripts/templates/`
holds only two files, the ones that cannot be copied verbatim because they carry
package-manager placeholders:

| File                     | Copy of                               |
| ------------------------ | ------------------------------------- |
| `sdlc-controls.yml.tmpl` | `.github/workflows/sdlc-controls.yml` |
| `integration.md`         | `docs/sdlc-controls-integration.md`   |

Change either original and the placeholder version must be edited by hand.

Two things still need asserting, and CI does both:

```sh
scripts/check-template-drift.sh
```

It renders a real install into a throwaway directory, diffs those two files against
their originals, and then checks every relative link in the result. That second check
is what keeps the manifest honest: the `.ai/` cluster is the transitive link closure of
the tier workflows, so adding a link from an installed file to one that is not in the
manifest fails the build rather than shipping a dangling link.

One link is knowingly left dangling and allowlisted in that script — the integration
doc cites this workspace's ADR-0001, and a bootstrapped repository should record its own
decision rather than inherit someone else's.
