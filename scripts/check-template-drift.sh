#!/usr/bin/env bash
# Assert scripts/bootstrap-ai-governance.sh still installs a coherent repository.
#
#   scripts/check-template-drift.sh
#
# Most of what the bootstrap installs is read straight from this repository, so it
# cannot drift from the original — there is no second copy to fall behind. Two things
# still can, and this checks both against a real install into a throwaway directory:
#
#   1. The two files under scripts/templates/ that are not verbatim copies. They carry
#      package-manager placeholders, so they are re-typed rather than copied, and a
#      change to the original does not reach them.
#
#   2. The install manifest. All of .ai/ ships, minus two short carve-outs in the
#      bootstrap: files that are not portable, and files meaningless without the gate.
#      Add a link from an installed file to a carved-out one and the target gets a
#      dangling link, so both profiles are installed for real and link-checked.
#
# Exits 1 on either, printing the diff or the dangling links.

set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)

# Each templated file and the file it is a re-typed copy of.
declare -A live=(
  [integration.md]='docs/sdlc-controls-integration.md'
  [sdlc-controls.yml.tmpl]='.github/workflows/sdlc-controls.yml'
)

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
rendered="$workdir/gate"
mkdir -p "$rendered"

# This workspace is the pnpm/Nx case, so its own files are what a pnpm render must
# equal. --kind and --package-manager are explicit: detection reads the target, and
# the target is an empty directory.
"$root/scripts/bootstrap-ai-governance.sh" \
  --target "$rendered" --kind nx --package-manager pnpm \
  --with-sdlc-controls --apply >/dev/null

# The default profile must stand alone, including on a repository that is not Nx and
# has no gate: that is the claim it makes. Installed and link-checked as its own profile.
mkdir -p "$workdir/default"
"$root/scripts/bootstrap-ai-governance.sh" \
  --target "$workdir/default" --kind generic --apply >/dev/null

# Nx without the gate -- neither of the two above, and the profile a gate-conditional
# carve-out breaks first: the prompt store ships here (it needs --kind nx) while
# anything gated does not. Checking only the two diagonal cases let exactly that
# through once, with run-task.prompt.md naming .ai/workflows/ files no profile in this
# script installed. Four combinations, three that can differ.
mkdir -p "$workdir/nx-nogate"
"$root/scripts/bootstrap-ai-governance.sh" \
  --target "$workdir/nx-nogate" --kind nx --package-manager pnpm --apply >/dev/null

status=0
for name in "${!live[@]}"; do
  path=${live[$name]}
  [[ -f "$root/scripts/templates/sdlc-controls/$name" ]] \
    || { printf 'error: missing template: scripts/templates/sdlc-controls/%s\n' "$name" >&2; exit 1; }
  [[ -f "$root/$path" ]] || { printf 'error: missing original: %s\n' "$path" >&2; exit 1; }
  # The rendered copy has its <!-- local-only --> blocks stripped, so strip them from
  # the original too: the diff is about the template falling behind, not about that.
  if ! diff -u --label "$path" --label "rendered from scripts/templates/sdlc-controls/$name" \
       <(sed '/<!-- local-only:start -->/,/<!-- local-only:end -->/d' "$root/$path") \
       "$rendered/$path"; then
    printf '\nscripts/templates/sdlc-controls/%s no longer matches %s.\n' "$name" "$path" >&2
    printf 'Port the change by hand: it carries __INSTALL__/__NX__/__CACHE__/__DLX__\n' >&2
    printf 'placeholders and a __PNPM_ONLY_START/END__ block, so it cannot be re-copied.\n' >&2
    status=1
  fi
done

# A template under scripts/templates/ that nothing installs is dead weight, and one
# with no entry above is unchecked. Both are failures rather than skips.
while IFS= read -r -d '' template; do
  name=$(basename "$template")
  [[ -v live[$name] ]] || {
    printf 'error: scripts/templates/sdlc-controls/%s has no entry in this script.\n' "$name" >&2
    exit 1
  }
done < <(find "$root/scripts/templates" -type f -print0)

python3 - "$rendered" "$workdir/default" "$workdir/nx-nogate" <<'PY' || status=1
import re, sys, pathlib

targets = [pathlib.Path(a).resolve() for a in sys.argv[1:]]

# Nothing is allowlisted. A link that only makes sense with an optional component goes
# in a <!-- local-only --> or <!-- gate-only --> block, which the bootstrap strips, so
# it never reaches a target to dangle in the first place.
ALLOWED = set()

# The prompts name governance files in backticks rather than as links -- run-task
# says "read `.ai/workflows/tier-light.md`" -- so the markdown-link scan above cannot
# see them, and a carve-out that withheld those files shipped a prompt pointing at
# nothing. An agent does not report a missing file, it improvises around it.
#
# Only `.ai/` paths: everything under it is framework content the bootstrap owns and
# must supply. A backticked `docs/specs/...` is project content the target authors
# later, and its absence in a fresh repository is correct. Paths carrying a
# `{placeholder}` or a glob are patterns, not references.
BACKTICKED = re.compile(r"`(\.ai/[^`\s]+)`")

dangling = []
checked = 0
for target in targets:
    for md in sorted(target.rglob("*.md")):
        body = md.read_text()

        for match in BACKTICKED.finditer(body):
            named = match.group(1)
            if "{" in named or "*" in named:
                continue
            checked += 1
            if not (target / named).exists():
                dangling.append(f"[{target.name}] {md.relative_to(target)} -> {named} (named in backticks)")

        for match in re.finditer(r"\]\(([^)#]+?)(?:#[^)]*)?\)", body):
            href = match.group(1).strip()
            if href.startswith(("http", "mailto", "#")):
                continue
            checked += 1
            resolved = (md.parent / href).resolve()
            try:
                rel = resolved.relative_to(target).as_posix()
            except ValueError:
                dangling.append(f"[{target.name}] {md.relative_to(target)} -> {href} (escapes the repository)")
                continue
            if not resolved.exists() and rel not in ALLOWED:
                dangling.append(f"[{target.name}] {md.relative_to(target)} -> {href}")

if dangling:
    print(f"\n{len(dangling)} dangling link(s) in a freshly bootstrapped repository:")
    for d in dangling:
        print(f"  {d}")
    print("\nEither install the file it points at (add it to the manifest in")
    print("scripts/bootstrap-ai-governance.sh) or stop linking to it.")
    raise SystemExit(1)

print(f"bootstrap install: {checked} link(s) checked across {len(targets)} profile(s), none dangling.")
PY

if ((status == 0)); then
  printf 'scripts/templates: %d templated file(s) match their originals.\n' "${#live[@]}"
fi
exit "$status"
