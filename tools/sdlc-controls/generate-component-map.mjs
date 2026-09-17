// Nx project graph -> git-native-sdlc-controls component map.
//
// The binary (github.com/codeaiforge/git-native-sdlc-controls@v0.2.0) tiers a change
// from a declared component map. Its documented ceiling is that the map is
// hand-maintained, so a high fan-in component nobody remembered to flag is
// under-tiered. This workspace has a computed graph, so it doesn't have to guess:
// topology is derived, and only business criticality stays declared.
//
//   topology  (paths, fan-in -> `shared`)  = computed from the Nx graph
//   criticality                            = read from reviewed Nx project tags
//
// See docs/sdlc-controls-integration.md and config/sdlc-controls/criticality-tags.md.
//
// Usage: node tools/sdlc-controls/generate-component-map.mjs [graph.json] > components.yaml

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

/**
 * Reverse-dependency count at which a project is reported `shared: true`, which
 * escalates the tier by one. Deliberately a constant rather than an env var or a
 * config file: the number that decides how much scrutiny a change gets must not be
 * changeable by a CI variable nobody reviews. Moving it means editing this file,
 * which shows up in a pull request — and self-escalates, because this file is
 * declared `critical` below.
 */
export const SHARED_FANIN_THRESHOLD = 3;

/** Criticality applied to a project carrying no `criticality:` tag. */
export const DEFAULT_CRITICALITY = 'high';

const CRITICALITIES = ['low', 'medium', 'high', 'critical'];

/**
 * Paths that are not Nx projects but are the workspace's own control surface.
 *
 * This is a *declared* table, reviewed in the pull request that changes it — the
 * same human checkpoint the `criticality:` tags get, for paths the project graph
 * does not model. It is not derived from anything, and it is kept short on purpose.
 *
 * It also stands in for the binary's map-governance rule. That rule self-escalates
 * a change that edits the committed component map; ours is generated per run and
 * never committed, so the rule cannot fire. Declaring the generator `critical`
 * instead means a change to the thing that decides tiers is tiered as one.
 */
export const WORKSPACE_COMPONENTS = [
  {
    id: 'sdlc-controls-gate',
    match: [
      'tools/sdlc-controls/**',
      'config/sdlc-controls/**',
      '.github/workflows/sdlc-controls.yml',
      // The commit-msg provenance check. Control machinery: weakening it is how
      // provenance quietly stops being declared.
      '.githooks/**',
    ],
    criticality: 'critical',
    shared: false,
  },
  {
    id: 'ci-pipeline',
    match: ['.github/workflows/**', '.github/actions/**'],
    criticality: 'high',
    shared: false,
  },
  {
    id: 'ai-governance',
    match: [
      '.ai/**',
      '.github/agents/**',
      '.github/prompts/**',
      '.github/skills/**',
      '.claude/**',
      '.codex/**',
      '.cursor/**',
      '.gemini/**',
      '.opencode/**',
      'AGENTS.md',
      'CLAUDE.md',
    ],
    criticality: 'high',
    shared: false,
  },
  {
    id: 'workspace-config',
    match: [
      '.gitignore',
      '.prettierignore',
      '.prettierrc',
      'nx.json',
      'opencode.json',
      'package.json',
      'pnpm-lock.yaml',
      'pnpm-workspace.yaml',
      'tsconfig*.json',
    ],
    criticality: 'high',
    shared: false,
  },
  {
    id: 'docs',
    match: ['docs/**', 'LICENSE', 'README.md'],
    criticality: 'low',
    shared: false,
  },
];

/** Defaults block. `unmatched_path_tier: high` is the binary's own fail-safe: a
 *  path no component claims is the case the map cannot reason about. */
export const DEFAULTS = { unmatched_path_tier: 'high', breadth_threshold: 4 };

/**
 * Reverse-dependency count per project, from the graph's edges.
 *
 * Only edges whose target is itself a project count. Nx also records edges to
 * external npm packages; those say nothing about this repository's blast radius.
 */
export function fanIn(graph) {
  const projects = new Set(Object.keys(graph.nodes ?? {}));
  const counts = new Map([...projects].map((p) => [p, 0]));
  for (const [source, edges] of Object.entries(graph.dependencies ?? {})) {
    if (!projects.has(source)) continue;
    // One source counts once per target, however many files carry the import.
    const targets = new Set(
      (edges ?? [])
        .map((e) => e.target)
        .filter((t) => projects.has(t) && t !== source)
    );
    for (const t of targets) counts.set(t, counts.get(t) + 1);
  }
  return counts;
}

/**
 * Criticality for one project, from its `criticality:<class>` tag.
 *
 * Throws on a tag the binary would reject or on two conflicting tags. The binary
 * fails the run on an invalid map rather than tiering around it, for the reason
 * that `criticality: critcal` is a plausible typo that would otherwise tier a
 * critical component at T0 and pass the change. Failing here keeps that property
 * at the point where the typo is actually readable.
 */
export function criticalityOf(name, tags = []) {
  const declared = tags
    .filter((t) => t.startsWith('criticality:'))
    .map((t) => t.slice('criticality:'.length));
  if (declared.length === 0) return DEFAULT_CRITICALITY;
  if (declared.length > 1) {
    throw new Error(
      `project "${name}" declares several criticality tags: ${declared.join(
        ', '
      )}`
    );
  }
  if (!CRITICALITIES.includes(declared[0])) {
    throw new Error(
      `project "${name}": criticality "${
        declared[0]
      }" is not one of ${CRITICALITIES.join('|')}`
    );
  }
  return declared[0];
}

/** Path globs for a project: its root, plus sourceRoot when that sits outside root. */
export function matchesFor(name, data) {
  const root = (data.root ?? '').replace(/^\.\//, '').replace(/\/+$/, '');
  if (root === '' || root === '.') {
    // A root project's glob would be `**`, which claims every path in the
    // repository and would silently swallow every other component's matches.
    throw new Error(
      `project "${name}" has root "${data.root}": a root project cannot be mapped to a path glob`
    );
  }
  const matches = [`${root}/**`];
  const src = (data.sourceRoot ?? '').replace(/^\.\//, '').replace(/\/+$/, '');
  if (src && src !== root && !src.startsWith(`${root}/`))
    matches.push(`${src}/**`);
  return matches;
}

/** Nx graph -> component map, in the schema the binary reads. Pure and deterministic. */
export function buildComponentMap(graph) {
  const counts = fanIn(graph);
  const fromGraph = Object.entries(graph.nodes ?? {}).map(([name, node]) => {
    const data = node.data ?? {};
    return {
      id: name,
      match: matchesFor(name, data).sort(),
      criticality: criticalityOf(name, data.tags ?? []),
      shared: counts.get(name) >= SHARED_FANIN_THRESHOLD,
    };
  });

  const components = [...WORKSPACE_COMPONENTS, ...fromGraph]
    .map((c) => ({ ...c, match: [...c.match].sort() }))
    .sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0));

  const ids = components.map((c) => c.id);
  const clash = ids.find((id, i) => ids.indexOf(id) !== i);
  if (clash) {
    // The binary rejects a duplicate id anyway; say which kind of clash it is.
    throw new Error(
      `component id "${clash}" is declared twice: an Nx project collides with a workspace component`
    );
  }

  return { version: 1, defaults: { ...DEFAULTS }, components };
}

/** Minimal deterministic YAML for this one shape. Every string is quoted. */
export function toYaml(map) {
  const q = (s) => `"${String(s).replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;
  const lines = [
    '# Generated by tools/sdlc-controls/generate-component-map.mjs — do not edit.',
    '# Topology is computed from the Nx project graph; criticality is read from',
    '# reviewed project tags. See config/sdlc-controls/criticality-tags.md.',
    `version: ${map.version}`,
    'defaults:',
    `  unmatched_path_tier: ${map.defaults.unmatched_path_tier}`,
    `  breadth_threshold: ${map.defaults.breadth_threshold}`,
    'components:',
  ];
  for (const c of map.components) {
    lines.push(`  - id: ${q(c.id)}`);
    lines.push(`    match: [${c.match.map(q).join(', ')}]`);
    lines.push(`    criticality: ${c.criticality}`);
    lines.push(`    shared: ${c.shared}`);
  }
  return lines.join('\n') + '\n';
}

function main(argv) {
  const path = argv[0] ?? 'graph.json';
  let raw;
  try {
    raw = readFileSync(path, 'utf8');
  } catch {
    throw new Error(`cannot read ${path} — run: pnpm nx graph --file=${path}`);
  }
  const { graph } = JSON.parse(raw);
  if (!graph)
    throw new Error(`${path} has no "graph" key: not an nx graph export`);
  process.stdout.write(toYaml(buildComponentMap(graph)));
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try {
    main(process.argv.slice(2));
  } catch (e) {
    console.error(`error: ${e.message}`);
    process.exit(1);
  }
}
