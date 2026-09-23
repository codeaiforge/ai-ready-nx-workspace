#!/usr/bin/env bash
# Bootstrap the portable authority layers (shared AI governance and adapters).
# It deliberately does not invent project architecture or overwrite local policy.

set -euo pipefail

apply_changes=false
check_only=false
force=false
kind="auto"
adapters="codex"
target="."
with_sdlc_controls=false
package_manager="auto"
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
# Files that ship verbatim are read from this repository, not from a copy under
# scripts/templates/. A copy would have to be committed alongside every edit to the
# original and policed for drift; reading the original makes the drift impossible
# instead of detectable. Only files needing package-manager substitution are templates.
source_root=$(cd "$script_dir/.." && pwd -P)

usage() {
  cat <<'USAGE'
Usage: bootstrap-ai-governance.sh [options]

Creates the portable authority layers in an existing repository. It is dry-run
by default and never overwrites an existing file unless --force is supplied.

An existing file is compared, not skipped: it is reported CURRENT when it already
matches what this script installs, and STALE when it differs. STALE files are left
alone; --apply --force takes this script's version, discarding local edits.

Options:
  --target PATH             Repository root to initialise (default: .)
  --kind auto|nx|generic    Authority-1 model (default: auto; detects nx.json)
  --adapters LIST           Comma-separated adapters: codex, claude, gemini,
                            cursor, opencode, copilot (default: codex)
  --with-sdlc-controls      Also install the GitHub PR risk gate and the provenance
                            standard it enforces. With --kind nx the component map is
                            projected from the project graph per run; otherwise a
                            starter map is committed at
                            config/sdlc-controls/components.yaml for you to split.
  --package-manager NAME    npm or pnpm for the generated GitHub workflow
                            (--kind nx only; default: auto-detect)
  --apply                   Write the planned files
  --check                   Read-only: exit non-zero if any managed file is
                            missing or differs. For a bootstrapped repo's CI.
  --force                   Replace existing bootstrap-managed files; requires --apply
  -h, --help                Show this help

Examples:
  scripts/bootstrap-ai-governance.sh --target ../another-workspace --kind nx
  scripts/bootstrap-ai-governance.sh --target ../service --kind generic \
    --adapters codex,claude --apply
  scripts/bootstrap-ai-governance.sh --target ../nx-workspace --kind nx \
    --with-sdlc-controls --apply
  scripts/bootstrap-ai-governance.sh --target ../java-service --kind generic \
    --with-sdlc-controls --apply
USAGE
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

while (($#)); do
  case "$1" in
    --target) target=${2:?"--target needs a path"}; shift 2 ;;
    --kind) kind=${2:?"--kind needs a value"}; shift 2 ;;
    --adapters) adapters=${2:?"--adapters needs a value"}; shift 2 ;;
    --with-sdlc-controls) with_sdlc_controls=true; shift ;;
    --package-manager) package_manager=${2:?"--package-manager needs a value"}; shift 2 ;;
    --apply) apply_changes=true; shift ;;
    --check) check_only=true; shift ;;
    --force) force=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

[[ -d "$target" ]] || die "target directory does not exist: $target"
root=$(cd "$target" && pwd -P)
[[ "$root" != "/" ]] || die "refusing to initialise the filesystem root"

case "$kind" in
  auto)
    if [[ -f "$root/nx.json" ]]; then kind="nx"; else kind="generic"; fi
    ;;
  nx|generic) ;;
  *) die "--kind must be auto, nx, or generic" ;;
esac

if "$force" && ! "$apply_changes"; then
  die "--force requires --apply"
fi

if "$check_only" && "$apply_changes"; then
  die "--check is read-only; do not combine it with --apply"
fi

# The package manager is an Nx-profile concern: that profile installs the workspace to
# run the map generator. A generic target has no manifest to install from, and reaches
# ajv through `npx --yes`.
if "$with_sdlc_controls" && [[ "$kind" == "nx" ]]; then
  case "$package_manager" in
    auto)
      if [[ -f "$root/pnpm-lock.yaml" ]] || grep -q '"packageManager"[[:space:]]*:[[:space:]]*"pnpm@' "$root/package.json" 2>/dev/null; then
        package_manager="pnpm"
      elif [[ -f "$root/package-lock.json" ]]; then
        package_manager="npm"
      else
        die "cannot detect a package manager; pass --package-manager npm or pnpm"
      fi
      ;;
    npm|pnpm) ;;
    *) die "--package-manager must be npm or pnpm" ;;
  esac
fi

written=0
current=0
adapter_content=false
stale=()
# An existing file gets compared, not assumed. "It is already there" says nothing about
# whether it is the version this script would install: a repository bootstrapped before
# the component-map adapter was fixed still has the broken one, and a run that only
# reported SKIP would let it stay broken silently.
install_template() {
  local relative=$1 content destination existed=false
  content=$(cat)
  destination="$root/$relative"

  if [[ -e "$destination" ]]; then
    existed=true
    [[ -f "$destination" ]] || die "refusing to write over a non-regular file: $relative"
    # $(cat) strips trailing newlines on both sides, so this compares like for like.
    if [[ "$content" == "$(cat "$destination")" ]]; then
      printf '%-7s %s\n' CURRENT "$relative"
      ((current += 1))
      return
    fi
    if [[ "$force" == false ]]; then
      printf '%-7s %s (differs; left alone)\n' STALE "$relative"
      stale+=("$relative")
      return
    fi
  fi

  if "$apply_changes"; then
    mkdir -p "$(dirname "$destination")"
    printf '%s\n' "$content" > "$destination"
    printf '%-7s %s\n' "$($existed && echo UPDATE || echo CREATE)" "$relative"
  else
    printf '%-7s %s\n' CREATE "$relative"
  fi
  ((written += 1))
}

# A <!-- local-only --> block cites something only this repository has; a
# <!-- gate-only --> block explains how the PR gate consumes something; <!-- nx-only -->
# and <!-- generic-only --> are the two ways a component map is produced, and exactly one
# of them is true of any target. Strip what the target will not have, so no installed
# file links to a file that was left behind or describes machinery it did not get. The
# markers themselves never ship.
marker_filter() {
  local script='/<!-- local-only:start -->/,/<!-- local-only:end -->/d'
  if "$with_sdlc_controls"; then
    script="$script;/<!-- gate-only:\(start\|end\) -->/d"
  else
    script="$script;/<!-- gate-only:start -->/,/<!-- gate-only:end -->/d"
  fi
  if [[ "$kind" == "nx" ]]; then
    script="$script;/<!-- nx-only:\(start\|end\) -->/d"
    script="$script;/<!-- generic-only:start -->/,/<!-- generic-only:end -->/d"
  else
    script="$script;/<!-- nx-only:start -->/,/<!-- nx-only:end -->/d"
    script="$script;/<!-- generic-only:\(start\|end\) -->/d"
  fi
  printf '%s' "$script"
}

# Deleting a conditional block leaves the blank line before it next to the blank line
# after it. Markdown renders one or two the same, but prettier does not: it wants a
# blank line on each side of an HTML comment, and a repository that runs it would
# reformat what this script just wrote. Collapsing the run keeps the marker padded in
# the source and the output clean. Markdown only -- a run of blank lines is not
# always noise elsewhere, and .githooks/commit-msg goes through here too.
emit_template() {
  local relative=$1
  if [[ "$relative" == *.md ]]; then
    install_template "$relative" < <(cat -s)
  else
    install_template "$relative" < <(cat)
  fi
}

install_template_file() {
  local relative=$1 source=$2
  [[ -f "$source" ]] || die "bootstrap template is missing: $source"
  sed "$(marker_filter)" "$source" | emit_template "$relative"
}

install_executable_template_file() {
  local relative=$1 source=$2
  install_template_file "$relative" "$source"
  if "$apply_changes" && [[ -f "$root/$relative" ]]; then
    chmod +x "$root/$relative"
  fi
}

# Substitutes the target's package manager into a template. __PNPM_ONLY_*__ brackets
# lines that exist only for pnpm; a file without them is unaffected. __MAP__ is where the
# gate reads its component map, which is the one thing the two profiles genuinely
# disagree about: projected from the graph per run, or committed and reviewed.
install_rendered() {
  local relative=$1 source=$2
  local content install_command nx_command dlx_command map_path
  [[ -f "$source" ]] || die "bootstrap template is missing: $source"
  if [[ "$kind" != "nx" ]]; then
    # Nothing to install and no graph to project. The steps that would have used these
    # are inside <!-- nx-only --> and are about to be stripped; `npx --yes` fetches ajv
    # on demand, which is all that is left needing Node.
    install_command=':'
    nx_command=':'
    dlx_command='npx --yes'
    map_path='config/sdlc-controls/components.yaml'
    content=$(sed '/__PNPM_ONLY_START__/,/__PNPM_ONLY_END__/d' "$source")
    content=${content//__MAP__/$map_path}
    content=${content//__DLX__/$dlx_command}
    printf '%s\n' "$content" | sed "$(marker_filter)" | emit_template "$relative"
    return
  fi
  map_path='${RUNNER_TEMP}/components.yaml'
  case "$package_manager" in
    pnpm)
      install_command='pnpm install --frozen-lockfile'
      nx_command='pnpm exec nx'
      dlx_command='pnpm dlx'
      # actions/setup-node needs pnpm on PATH before it can cache for it.
      content=$(sed '/__PNPM_ONLY_\(START\|END\)__/d' "$source")
      ;;
    npm)
      install_command='npm ci'
      nx_command='npx nx'
      dlx_command='npx --yes'
      content=$(sed '/__PNPM_ONLY_START__/,/__PNPM_ONLY_END__/d' "$source")
      ;;
  esac
  content=${content//__CACHE__/$package_manager}
  content=${content//__MAP__/$map_path}
  content=${content//__INSTALL__/$install_command}
  content=${content//__NX__/$nx_command}
  content=${content//__DLX__/$dlx_command}
  printf '%s\n' "$content" | sed "$(marker_filter)" | emit_template "$relative"
}

install_template AGENTS.md <<'EOF'
# Repository authority

Follow this authority order whenever information conflicts:

1. Machine-readable system structure and dependency declarations.
2. `docs/` — repository architecture, requirements, and ADRs.
3. `.ai/` — shared governance: standards, roles, task playbooks, and workflows.
4. Agent folders such as `.codex/` and `.claude/` — implementation adapters only.

Agents consume the architecture and governance above; adapters must not duplicate or
override them. Keep project-specific architectural facts in the system model and `docs/`.
EOF

install_template .ai/README.md <<'EOF'
# Shared AI governance

This directory is the shared, tool-neutral authority layer for agents working in this
repository. It contains standards, role guidance, task playbooks, and workflows.

It is subordinate to the repository's machine-readable architecture and `docs/`.
Agent-specific folders must reference this directory rather than copy its rules.
EOF

if [[ "$kind" == "nx" ]]; then
  install_template .ai/context/workspace.md <<'EOF'
# Workspace context

The Nx project graph is the canonical, machine-readable model of this repository's
projects and dependency boundaries. Use the workspace package manager to query the graph
before proposing structural changes. `docs/` records the intent behind that graph.

Project tags and dependency constraints are part of the architecture. Update the graph
and its documented intent together; do not encode architecture independently in an agent
adapter.
EOF
else
  install_template .ai/context/workspace.md <<'EOF'
# Workspace context

Before relying on this file, name the repository's actual machine-readable source of
structure: for example a package/workspace manifest, Maven or Gradle modules, Cargo
workspace, build graph, or infrastructure configuration. That source is authority layer
1. `docs/` explains its intent.

Do not describe a project graph as authoritative unless the repository can generate it.
EOF
fi

install_template .ai/standards/authority.md <<'EOF'
# Authority and adapter standard

Use the repository authority order in `AGENTS.md`. Architecture is derived from the
machine-readable system model and `docs/`; `.ai/` supplies shared operating guidance.

Agent adapters are intentionally thin. They may configure a tool and link to shared
guidance, but they must not restate architectural decisions, boundaries, or governance
rules that belong in higher authority layers.
EOF

IFS=',' read -r -a adapter_list <<< "$adapters"
for adapter in "${adapter_list[@]}"; do
  adapter=$(printf '%s' "$adapter" | tr -d '[:space:]')
  case "$adapter" in
    codex|claude|gemini|cursor|opencode|copilot) ;;
    *) die "unsupported adapter: $adapter" ;;
  esac
  # GitHub Copilot reads .github/ rather than a dotted directory of its own.
  if [[ "$adapter" == copilot ]]; then
    adapter_dirs=("$source_root/.github/skills" "$source_root/.github/agents")
  else
    adapter_dirs=("$source_root/.$adapter")
  fi
  adapter_dir=${adapter_dirs[0]}

  # This workspace's adapter content is Nx-flavoured throughout — plugin config, an
  # nx-workspace skill, graph-aware commands — so a generic target gets the pointer
  # README instead of content that would describe a build system it does not use.
  if [[ "$kind" != "nx" || ! -d "$adapter_dir" ]]; then
    install_template ".${adapter}/README.md" <<EOF
# ${adapter} adapter

This directory configures the ${adapter} tool for this repository. It is an implementation
adapter, not an architecture or governance source of truth.

Read \`AGENTS.md\`, \`docs/\`, and \`.ai/\` before making decisions. Consume the shared
standards, roles, task playbooks, and workflows from \`.ai/\`; do not duplicate them here.
EOF
    continue
  fi

  while IFS= read -r -d '' source; do
    relative=${source#"$source_root/"}
    # monitor-ci drives Nx Cloud, which this workspace removed from its own CI. Shipping
    # it would hand a target a command for a service the pipeline does not use.
    [[ "$relative" == *monitor-ci* || "$relative" == *ci-monitor* ]] && continue
    install_template_file "$relative" "$source"
  done < <(find "${adapter_dirs[@]}" -type f -print0 2>/dev/null | sort -z)

  # A tool that keeps its entry point at the repository root rather than inside its
  # own directory. Same status as .claude/settings.json: adapter configuration.
  case "$adapter" in
    claude)    install_template_file CLAUDE.md "$source_root/CLAUDE.md" ;;
    opencode)  install_template_file opencode.json "$source_root/opencode.json" ;;
  esac

  adapter_content=true
done

if "$with_sdlc_controls"; then
  template_root="$script_dir/templates/sdlc-controls"
  install_rendered .github/workflows/sdlc-controls.yml "$template_root/sdlc-controls.yml.tmpl"
  if [[ "$kind" == "nx" ]]; then
    install_template_file tools/sdlc-controls/generate-component-map.mjs "$source_root/tools/sdlc-controls/generate-component-map.mjs"
    install_template_file tools/sdlc-controls/generate-component-map.test.mjs "$source_root/tools/sdlc-controls/generate-component-map.test.mjs"
    install_template_file tools/sdlc-controls/README.md "$source_root/tools/sdlc-controls/README.md"
    install_template_file config/sdlc-controls/criticality-tags.md "$source_root/config/sdlc-controls/criticality-tags.md"
  else
    # No graph to project a map from, so the map is a committed file -- which the
    # binary's map-governance rule can then actually see in a diff. Shipped as a
    # starting point, not a finished map: one catch-all component, to be split.
    install_template_file config/sdlc-controls/components.yaml "$template_root/components.yaml"
  fi
  install_rendered docs/sdlc-controls-integration.md "$template_root/integration.md"
fi


# In a non-applying run nothing existing is ever written, so `written` counts exactly
# the managed files this repository does not have yet.

install_executable_template_file .githooks/commit-msg "$source_root/.githooks/commit-msg"

# Framework-level and portable: the git workflow, and the commit format the hook above
# and the PR gate both read. Both live on main and carry no stack-specific content.
install_template_file .github/git-workflow.md "$source_root/.github/git-workflow.md"
install_template_file docs/commit-message-conventions.md "$source_root/docs/commit-message-conventions.md"
install_template_file docs/adr/0000-template.md "$source_root/docs/adr/0000-template.md"
install_template_file docs/adr/README.md "$source_root/docs/adr/README.md"
install_template_file docs/architecture/README.md "$source_root/docs/architecture/README.md"
install_template_file docs/diagrams/README.md "$source_root/docs/diagrams/README.md"
install_template_file docs/specs/README.md "$source_root/docs/specs/README.md"
# A numbering rule nothing checks is a convention, not a control — the point
# .ai/standards/adr.md makes, so the standard ships with its enforcement.
install_template_file tools/adr/check-numbering.mjs "$source_root/tools/adr/check-numbering.mjs"

# .ai/ is the governance layer this script exists to install, so all of it ships.
# The manifest is derived from this repository rather than listed, so a governance
# file added here reaches bootstrapped repositories without editing this script.
#
# That includes .ai/workflows/ whether or not the gate ships. run-task.prompt.md and
# sprint-conductor.prompt.md read those files by name, so withholding them left an
# installed prompt pointing at phase definitions the target does not have — and a
# missing file is not an error an agent reports, it is one it improvises around. The
# paragraphs that only make sense with the gate are bracketed <!-- gate-only --> and
# stripped by marker_filter instead, which is what that marker is for.
#
# One list carves out the exceptions. It is short on purpose: a file that needs an
# entry is usually a file that should have been written to be portable.
ai_never_ships=(
  # Documents this script, which the target does not have.
  .ai/tasks/bootstrap-governance.md
  # Superseded by the .ai/context/workspace.md this script writes per --kind.
  .ai/context/nx-workspace.md
  # Documents formats owned by .github/prompts/, so it ships only with the adapter
  # content that brings that store along — see the adapter block below.
  .ai/sprints/README.md
)

contains() {
  local needle=$1 item
  shift
  for item in "$@"; do [[ "$item" == "$needle" ]] && return 0; done
  return 1
}

while IFS= read -r -d '' source; do
  relative=${source#"$source_root/"}
  contains "$relative" "${ai_never_ships[@]}" && continue
  install_template_file "$relative" "$source"
done < <(find "$source_root/.ai" -name '*.md' -print0 | sort -z)

if "$adapter_content"; then
  # .<adapter>/commands/* are three-line wrappers that delegate here, so the store ships
  # with them or the commands point at nothing. The prompts read project docs a target
  # has not written yet, so the templates they name ship too.
  for relative in \
    .github/prompts/commit.prompt.md \
    .github/prompts/run-task.prompt.md \
    .github/prompts/sprint-conductor.prompt.md \
    docs/specs/stack-template.md \
    docs/specs/roadmap-template.md \
    docs/specs/requirements-template.md \
    docs/specs/sprint-progress-template.md
  do
    install_template_file "$relative" "$source_root/$relative"
  done

  # Unblocked by the prompt store above: it documents formats those prompts own.
  install_template_file .ai/sprints/README.md "$source_root/.ai/sprints/README.md"
fi

if "$check_only"; then
  if ((written == 0 && ${#stale[@]} == 0)); then
    printf '\nUp to date: %d managed file(s) match this script.\n' "$current"
    exit 0
  fi
  printf '\nThis repository is not up to date with the governance bootstrap.\n'
  ((written)) && printf '  %d file(s) missing (shown CREATE above)\n' "$written"
  ((${#stale[@]})) && printf '  %d file(s) differ (shown STALE above)\n' "${#stale[@]}"
  printf '\nRun without --check to see the plan; --apply installs what is missing and\n'
  printf -- '--apply --force also takes this script'"'"'s version of the differing files.\n'
  exit 1
fi

if "$apply_changes"; then
  printf '\nWrote %d file(s); %d already current.\n' "$written" "$current"
else
  printf '\nDry run: %d file(s) to write; %d already current.\n' "$written" "$current"
fi

if ((${#stale[@]})); then
  printf '\n%d file(s) exist but differ from what this script installs:\n' "${#stale[@]}"
  printf '  %s\n' "${stale[@]}"
  printf '\nThey were left alone. Diff them against the source of truth, then re-run with\n'
  printf -- '--apply --force to take this script'"'"'s version. Local edits are overwritten.\n'
fi

if ! "$apply_changes"; then
  printf '\nRun again with --apply to write the plan.\n'
fi
