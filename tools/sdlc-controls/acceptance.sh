#!/usr/bin/env bash
# End-to-end gate behaviour: the real binary, the real adapter, a throwaway repo.
#
# The unit tests cover the adapter in isolation. This covers the thing that
# actually matters — that a change gets the tier it deserves and that the gate
# blocks when the tier's controls are not met. It builds a fixture workspace,
# commits against it, and asserts on the emitted evidence/0 record.
#
#   Usage: tools/sdlc-controls/acceptance.sh
#   Needs: sdlc-controls on PATH (go install ...@v0.2.0), node, git, jq.
set -euo pipefail

BIN="${SDLC_CONTROLS_BIN:-sdlc-controls}"
command -v "$BIN" >/dev/null || { echo "sdlc-controls not on PATH; set SDLC_CONTROLS_BIN"; exit 2; }
ADAPTER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate-component-map.mjs"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
REPO="$WORK/repo"
MAP="$WORK/components.yaml"
EV="$WORK/evidence.json"

pass=0 fail=0
# check <name> <expected-exit> -- runs tier and compares the exit code.
# Extra args are passed through to tier.
run_tier() {
  local base="$1" author="$2" approvers="$3"; shift 3
  set +e
  "$BIN" tier --repo "$REPO" --base "$base" --head HEAD \
    --config "$MAP" --change-id acceptance --author "$author" \
    --approvers "$approvers" --approvers-known --evidence-out "$EV" > "$WORK/out.txt" 2>&1
  local rc=$?
  set -e
  echo "$rc"
}
expect() {
  local what="$1" got="$2" want="$3"
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); printf '  ok   %s (%s)\n' "$what" "$got"
  else
    fail=$((fail + 1)); printf '  FAIL %s: got %s, want %s\n' "$what" "$got" "$want"
    sed 's/^/       | /' "$WORK/out.txt" 2>/dev/null | head -20
  fi
}
ev() { jq -r "$1" "$EV"; }
# git does not track empty directories, so a reset back to base removes the
# fixture project folders along with the change under test.
reset_repo() {
  git -C "$REPO" reset -q --hard "$BASE"
  mkdir -p "$REPO/packages/marketing-site" "$REPO/packages/payments-api" "$REPO/packages/shared-utils"
}

# --- fixture workspace -------------------------------------------------------
# A critical service, a low-criticality library three projects depend on (so the
# graph makes it shared), and a low-criticality leaf nobody depends on.
mkdir -p "$REPO"
cat > "$WORK/graph.json" <<'JSON'
{"graph":{"nodes":{
  "payments-api":{"name":"payments-api","type":"app","data":{"root":"packages/payments-api","tags":["criticality:critical"]}},
  "shared-utils":{"name":"shared-utils","type":"lib","data":{"root":"packages/shared-utils","tags":["criticality:low"]}},
  "marketing-site":{"name":"marketing-site","type":"app","data":{"root":"packages/marketing-site","tags":["criticality:low"]}},
  "consumer-a":{"name":"consumer-a","type":"lib","data":{"root":"packages/consumer-a","tags":["criticality:low"]}},
  "consumer-b":{"name":"consumer-b","type":"lib","data":{"root":"packages/consumer-b","tags":["criticality:low"]}}
},"dependencies":{
  "payments-api":[{"source":"payments-api","target":"shared-utils","type":"static"}],
  "consumer-a":[{"source":"consumer-a","target":"shared-utils","type":"static"}],
  "consumer-b":[{"source":"consumer-b","target":"shared-utils","type":"static"}],
  "shared-utils":[],"marketing-site":[]
}}}
JSON
node "$ADAPTER" "$WORK/graph.json" > "$MAP"
"$BIN" binding --config "$MAP" > /dev/null || { echo "the generated map is not binding-valid"; exit 1; }

git -C "$REPO" init -q
git -C "$REPO" config user.email acceptance@example.com
git -C "$REPO" config user.name acceptance
mkdir -p "$REPO/packages/marketing-site" "$REPO/packages/payments-api" "$REPO/packages/shared-utils"
echo base > "$REPO/README.md"
git -C "$REPO" add -A && git -C "$REPO" commit -qm 'chore: base'
BASE="$(git -C "$REPO" rev-parse HEAD)"

echo "gate behaviour"

# --- 1. low-risk, human-authored, approved -----------------------------------
echo x > "$REPO/packages/marketing-site/index.ts"
git -C "$REPO" add -A && git -C "$REPO" commit -qm 'feat(marketing): copy tweak'
expect "low-risk change exits 0" "$(run_tier "$BASE" alice bob)" 0
expect "  tier is T0" "$(ev .tier)" T0
expect "  human commit records ai_assisted:false" "$(ev .ai_assisted)" false
expect "  evidence names the affected component" "$(ev '.affected_set[0]')" marketing-site
reset_repo

# --- 2. fan-in is computed, criticality is not -------------------------------
# shared-utils is declared `low` and has three dependents. The graph escalates it;
# the tag does not. This is the split the whole adapter exists to make.
echo x > "$REPO/packages/shared-utils/index.ts"
git -C "$REPO" add -A && git -C "$REPO" commit -qm 'feat(utils): helper'
expect "high fan-in escalates a low-criticality lib" "$(run_tier "$BASE" alice bob)" 0
expect "  tier is T1 (low + shared)" "$(ev .tier)" T1
expect "  escalation reason is recorded" \
  "$(ev '.reasons | map(select(contains("shared=true"))) | length')" 1
reset_repo

# --- 3. high-risk change with controls unmet ---------------------------------
echo x > "$REPO/packages/payments-api/charge.ts"
git -C "$REPO" add -A && git -C "$REPO" commit -qm 'feat(payments): charge path'
expect "high-risk change, one approver, blocks" "$(run_tier "$BASE" alice alice)" 1
expect "  tier is T3" "$(ev .tier)" T3
expect "  T3 demands two approvers" "$(ev .controls_enforced.min_approvers)" 2
expect "  evidence is still written on a block" "$(test -f "$EV" && echo yes)" yes
expect "  record says it failed" "$(ev .result.pass)" false
expect "  exit code is in the record" "$(ev .result.exit_code)" 1

# --- 4. high-risk change with controls met -----------------------------------
expect "high-risk change, two independent approvers, passes" "$(run_tier "$BASE" alice alice,bob)" 0
expect "  approver distinct from author" "$(ev .approver_ne_author)" true
expect "  accountable approver named" "$(ev .accountable_approver)" bob
reset_repo

# --- 5. AI-authored high-risk change: CAF-SDLC-011 ---------------------------
echo x > "$REPO/packages/payments-api/charge.ts"
git -C "$REPO" add -A
git -C "$REPO" commit -qm 'feat(payments): charge path

AI-Assisted: true
AI-Tool: claude-code
AI-Session: 4f2c1a80-7d3e-4b19-9c55-0ae61b2d8f34
Prompt-Ref: #12'
expect "AI-authored T3 self-approved blocks" "$(run_tier "$BASE" alice alice)" 1
expect "  provenance round-trips: ai_assisted" "$(ev .ai_assisted)" true
expect "  provenance round-trips: ai_tool" "$(ev .ai_tool)" claude-code
expect "  provenance round-trips: ai_session" "$(ev .ai_session)" 4f2c1a80-7d3e-4b19-9c55-0ae61b2d8f34
expect "  provenance round-trips: prompt_ref" "$(ev .prompt_ref)" '#12'
expect "  self-approval is the violation" \
  "$(ev '.result.violations | map(select(contains("CAF-SDLC-011"))) | length')" 1
expect "AI-authored T3 with an independent approver passes" "$(run_tier "$BASE" alice alice,bob)" 0
reset_repo

# --- 6. provenance that understates itself -----------------------------------
# Naming a tool implies assistance, so a missing AI-Assisted trailer cannot hide it.
echo x > "$REPO/packages/marketing-site/index.ts"
git -C "$REPO" add -A
git -C "$REPO" commit -qm 'feat(marketing): copy

AI-Tool: claude-code'
run_tier "$BASE" alice bob > /dev/null
expect "a tool trailer alone still marks the change AI-assisted" "$(ev .ai_assisted)" true
reset_repo

# --- 7. AI-assisted with no tool is a provenance violation -------------------
echo x > "$REPO/packages/marketing-site/index.ts"
git -C "$REPO" add -A
git -C "$REPO" commit -qm 'feat(marketing): copy

AI-Assisted: true'
expect "AI-assisted with no AI-Tool blocks" "$(run_tier "$BASE" alice bob)" 1
expect "  CAF-SDLC-010 is the violation" \
  "$(ev '.result.violations | map(select(contains("CAF-SDLC-010"))) | length')" 1
reset_repo

# --- 8. a tool error is never a pass -----------------------------------------
set +e
"$BIN" tier --repo "$REPO" --base "$BASE" --head HEAD --config "$WORK/does-not-exist.yaml" \
  > /dev/null 2>&1
rc=$?
set -e
expect "an unreadable map exits 2, not 0" "$rc" 2

echo
echo "${pass} passed, ${fail} failed"
[ "$fail" -eq 0 ]
