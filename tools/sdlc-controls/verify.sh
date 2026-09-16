#!/usr/bin/env bash
# Preflight for the sdlc-controls gate, run against this workspace as it stands.
#
# acceptance.sh proves the gate's *logic* against a synthetic fixture graph, in a
# throwaway repo it deletes. This proves the gate works on *this* repository: the
# real Nx graph, the real HEAD, a real evidence record kept on disk. The two are
# complementary, not duplicates — see tools/sdlc-controls/README.md.
#
# Every expectation below is an assertion. Exit 0 means all of them held.
#
#   Usage:
#     tools/sdlc-controls/verify.sh [base-ref]           # defaults to main
#     SDLC_EXPECT=path/to/expected.json  tools/…/verify.sh
#
#   Needs: sdlc-controls on PATH (or SDLC_CONTROLS_BIN), node, pnpm, jq, go.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

# Outputs live in the repository, not a temp dir. On a tool whose whole claim is
# that the evidence is on the record, writing the record somewhere that is wiped
# on exit argues against the product. Git-ignored, so it is never committed.
OUT="$ROOT/.sdlc-controls"
mkdir -p "$OUT"

BASE="${1:-main}"
EXPECT="${SDLC_EXPECT:-}"
BIN="${SDLC_CONTROLS_BIN:-sdlc-controls}"
ADAPTER="$ROOT/tools/sdlc-controls/generate-component-map.mjs"
WORKFLOW="$ROOT/.github/workflows/sdlc-controls.yml"

# The pinned version is read from the workflow rather than repeated here, so a
# bump to the gate's pin cannot leave this script validating against a different
# release than CI does.
VERSION="$(sed -n 's/^[[:space:]]*SDLC_CONTROLS_VERSION:[[:space:]]*//p' "$WORKFLOW" | head -1)"
[ -n "$VERSION" ] || { echo "FAIL: no SDLC_CONTROLS_VERSION in $WORKFLOW"; exit 1; }

pass=0 fail=0
ok()   { pass=$((pass + 1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail + 1)); printf '  FAIL %s\n' "$1"; }
check(){ if [ "$2" = "$3" ]; then ok "$1 ($2)"; else bad "$1: got '$2', want '$3'"; fi; }
need() { command -v "$1" >/dev/null || { echo "FAIL: $1 is not on PATH"; exit 1; }; }

need node; need jq; need go; need pnpm
command -v "$BIN" >/dev/null || {
  echo "FAIL: sdlc-controls not on PATH. Install the pinned build:"
  echo "      go install github.com/codeaiforge/git-native-sdlc-controls/cmd/sdlc-controls@${VERSION}"
  exit 1
}

echo "sdlc-controls preflight  (base=${BASE}, pin=${VERSION})"
echo "  output: ${OUT#"$ROOT"/}"
echo

# --- produce the artifacts ---------------------------------------------------
pnpm exec nx graph --file="$OUT/graph.json" >/dev/null
node "$ADAPTER" "$OUT/graph.json" > "$OUT/components.yaml"

# The map as JSON, built by the adapter's own exported function. `binding
# --format json` carries the tier table and escalation rules but no components,
# so it cannot answer "what criticality did this project get" — the map can.
ADAPTER="$ADAPTER" GRAPH="$OUT/graph.json" node --input-type=module -e '
  import {readFileSync} from "node:fs";
  import {pathToFileURL} from "node:url";
  const m = await import(pathToFileURL(process.env.ADAPTER).href);
  const {graph} = JSON.parse(readFileSync(process.env.GRAPH, "utf8"));
  console.log(JSON.stringify(m.buildComponentMap(graph), null, 2));
' > "$OUT/components.json"

"$BIN" binding --config "$OUT/components.yaml" --format json > "$OUT/binding.json"

# tier is informational in a preflight: a change that would be blocked is a
# finding to read, not a reason for this script to fail. Only exit 2 — the tool
# failing to reach a decision — is a failure here.
set +e
"$BIN" tier --base "$BASE" --head HEAD --config "$OUT/components.yaml" \
  --format json --evidence-out "$OUT/evidence.json" > "$OUT/tier.json" 2>"$OUT/tier.err"
tier_rc=$?
set -e
if [ "$tier_rc" -eq 2 ]; then
  echo "FAIL: tier exited 2 — the gate did not reach a decision"
  sed 's/^/       | /' "$OUT/tier.err"
  exit 1
fi

# --- assertions --------------------------------------------------------------
echo "artifacts"
for f in graph.json components.yaml components.json binding.json evidence.json; do
  if [ -s "$OUT/$f" ]; then ok "$f written"; else bad "$f missing or empty"; fi
done

echo "binding"
check "binding.json parses" "$(jq -e 'type' "$OUT/binding.json" 2>/dev/null || echo invalid)" '"object"'
check "declares a tier table T0-T3" \
  "$(jq -r '[.tiers | keys[]] | sort | join(",")' "$OUT/binding.json")" "T0,T1,T2,T3"
check "every tier states min_approvers" \
  "$(jq '[.tiers[] | select(.min_approvers == null)] | length' "$OUT/binding.json")" 0

echo "evidence"
check "evidence.json parses" "$(jq -e 'type' "$OUT/evidence.json" 2>/dev/null || echo invalid)" '"object"'
check "tier is on the T0-T3 scale" \
  "$(jq -r '[.tier] | inside(["T0","T1","T2","T3"])' "$OUT/evidence.json")" true

# Same schema, same validator, same flags as .github/workflows/sdlc-controls.yml.
# The schema is read out of the Go module cache at the pinned tag, so it cannot
# drift from the binary that produced the record.
SCHEMA="$(go env GOMODCACHE)/github.com/codeaiforge/git-native-sdlc-controls@${VERSION}/schemas/evidence/0/evidence.schema.json"
if [ ! -f "$SCHEMA" ]; then
  echo "  ..  fetching the pinned schema (one-off)"
  go mod download "github.com/codeaiforge/git-native-sdlc-controls@${VERSION}"
fi
if [ ! -f "$SCHEMA" ]; then
  bad "evidence/0 schema not in the module cache; run: go mod download github.com/codeaiforge/git-native-sdlc-controls@${VERSION}"
elif pnpm dlx ajv-cli@5.0.0 validate --spec=draft2020 --strict=false \
       -s "$SCHEMA" -d "$OUT/evidence.json" >"$OUT/ajv.log" 2>&1; then
  ok "validates against evidence/0"
else
  bad "does not validate against evidence/0"
  sed 's/^/       | /' "$OUT/ajv.log" | head -20
fi

check "tool.version matches the pin" "$(jq -r .tool.version "$OUT/evidence.json")" "${VERSION#v}"

# --- optional, workspace-specific expectations -------------------------------
# Kept out of this file on purpose: project names and criticalities are facts
# about one workspace, and this script has to serve any of them.
if [ -n "$EXPECT" ]; then
  [ -f "$EXPECT" ] || { echo "FAIL: SDLC_EXPECT=$EXPECT not found"; exit 1; }
  echo "expectations (${EXPECT})"

  while IFS=$'\t' read -r src tgt; do
    [ -n "$src" ] || continue
    found="$(jq -r --arg s "$src" --arg t "$tgt" \
      '[.graph.dependencies[$s][]? | select(.target == $t)] | length > 0' "$OUT/graph.json")"
    check "edge ${src} -> ${tgt}" "$found" true
  done < <(jq -r '.edges[]? | @tsv' "$EXPECT")

  while IFS=$'\t' read -r id want; do
    [ -n "$id" ] || continue
    got="$(jq -r --arg i "$id" \
      '(.components[] | select(.id == $i) | .criticality) // "absent"' "$OUT/components.json")"
    check "criticality ${id}" "$got" "$want"
  done < <(jq -r '.criticality // {} | to_entries[] | [.key, .value] | @tsv' "$EXPECT")
fi

# --- summary -----------------------------------------------------------------
echo
printf 'tier %s  affected: %s\n' \
  "$(jq -r .tier "$OUT/evidence.json")" \
  "$(jq -r 'if (.affected_set | length) > 0 then (.affected_set | join(", ")) else "(none)" end' "$OUT/evidence.json")"
[ "$tier_rc" -eq 1 ] && echo "note: tier would block this change — $(jq -r '.result.violations | join("; ")' "$OUT/evidence.json")"
# The map lives inside the repository here and in $RUNNER_TEMP in CI, so the
# record's map-governance warning differs between the two. Neither run can
# self-escalate on a map that is generated and never committed; CI says so out
# loud and this one does not. See docs/sdlc-controls-integration.md.
echo "note: local evidence omits CI's 'control file is outside the repository' warning"
echo

if [ "$fail" -eq 0 ]; then
  echo "PASS  ${pass} checks"
else
  echo "FAIL  ${fail} of $((pass + fail)) checks failed"
fi
[ "$fail" -eq 0 ]
