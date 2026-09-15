// node --test tools/sdlc-controls/
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  buildComponentMap,
  toYaml,
  fanIn,
  criticalityOf,
  matchesFor,
  SHARED_FANIN_THRESHOLD,
  DEFAULT_CRITICALITY,
} from './generate-component-map.mjs';

/**
 * A fixture graph: one critical service, one library four projects depend on
 * (above the fan-in threshold), one leaf nobody depends on, and three consumers
 * that exist to give the shared library its fan-in.
 */
const graph = {
  nodes: {
    'payments-api': {
      name: 'payments-api',
      type: 'app',
      data: { root: 'packages/payments-api', sourceRoot: 'packages/payments-api/src', tags: ['criticality:critical'] },
    },
    'shared-utils': {
      name: 'shared-utils',
      type: 'lib',
      data: { root: 'packages/shared-utils', tags: ['criticality:low'] },
    },
    'marketing-site': {
      name: 'marketing-site',
      type: 'app',
      data: { root: 'packages/marketing-site', tags: ['criticality:low'] },
    },
    'untagged-lib': { name: 'untagged-lib', type: 'lib', data: { root: 'packages/untagged-lib', tags: [] } },
    'consumer-a': { name: 'consumer-a', type: 'lib', data: { root: 'packages/consumer-a', tags: ['criticality:low'] } },
    'consumer-b': { name: 'consumer-b', type: 'lib', data: { root: 'packages/consumer-b', tags: ['criticality:low'] } },
  },
  dependencies: {
    'payments-api': [
      { source: 'payments-api', target: 'shared-utils', type: 'static' },
      // A second edge to the same target: many imports, still one dependent.
      { source: 'payments-api', target: 'shared-utils', type: 'static' },
      { source: 'payments-api', target: 'npm:express', type: 'static' },
    ],
    'consumer-a': [{ source: 'consumer-a', target: 'shared-utils', type: 'static' }],
    'consumer-b': [{ source: 'consumer-b', target: 'shared-utils', type: 'static' }],
    'marketing-site': [{ source: 'marketing-site', target: 'untagged-lib', type: 'static' }],
    'shared-utils': [],
    'untagged-lib': [],
  },
};

const byId = (map, id) => map.components.find((c) => c.id === id);

test('fan-in counts distinct dependents, ignoring npm targets and duplicate edges', () => {
  const counts = fanIn(graph);
  assert.equal(counts.get('shared-utils'), 3, 'payments-api, consumer-a, consumer-b — counted once each');
  assert.equal(counts.get('untagged-lib'), 1);
  assert.equal(counts.get('payments-api'), 0);
  assert.ok(!counts.has('npm:express'), 'external packages are not components');
});

test('a library at or above the fan-in threshold is shared; a leaf is not', () => {
  const map = buildComponentMap(graph);
  assert.equal(SHARED_FANIN_THRESHOLD, 3, 'the documented threshold this fixture is built around');
  assert.equal(byId(map, 'shared-utils').shared, true);
  assert.equal(byId(map, 'marketing-site').shared, false);
  assert.equal(byId(map, 'untagged-lib').shared, false, 'fan-in 1 is below the threshold');
});

test('criticality comes from the tag, never from fan-in', () => {
  const map = buildComponentMap(graph);
  assert.equal(byId(map, 'payments-api').criticality, 'critical', 'from criticality:critical');
  // The whole point of splitting the two signals: shared-utils is the most
  // depended-on project in the graph and is still declared low.
  assert.equal(byId(map, 'shared-utils').criticality, 'low');
  assert.equal(byId(map, 'shared-utils').shared, true);
});

test('an untagged project falls back to the conservative default', () => {
  assert.equal(DEFAULT_CRITICALITY, 'high');
  assert.equal(byId(buildComponentMap(graph), 'untagged-lib').criticality, 'high');
});

test('path globs cover the project root', () => {
  const map = buildComponentMap(graph);
  assert.deepEqual(byId(map, 'payments-api').match, ['packages/payments-api/**']);
});

test('a sourceRoot outside the project root gets its own glob', () => {
  assert.deepEqual(matchesFor('p', { root: 'packages/p', sourceRoot: 'generated/p/src' }).sort(), [
    'generated/p/src/**',
    'packages/p/**',
  ]);
});

test('a bad criticality tag fails rather than being tiered around', () => {
  assert.throws(() => criticalityOf('p', ['criticality:critcal']), /not one of low\|medium\|high\|critical/);
  assert.throws(() => criticalityOf('p', ['criticality:low', 'criticality:high']), /several criticality tags/);
});

test('a root project is rejected: its glob would claim every path', () => {
  assert.throws(() => matchesFor('rooty', { root: '.' }), /cannot be mapped to a path glob/);
});

test('an Nx project colliding with a workspace component is rejected', () => {
  const colliding = { nodes: { docs: { name: 'docs', data: { root: 'packages/docs', tags: [] } } }, dependencies: {} };
  assert.throws(() => buildComponentMap(colliding), /declared twice/);
});

test('output is deterministic and sorted regardless of graph key order', () => {
  const reversed = {
    nodes: Object.fromEntries(Object.entries(graph.nodes).reverse()),
    dependencies: Object.fromEntries(Object.entries(graph.dependencies).reverse()),
  };
  assert.equal(toYaml(buildComponentMap(graph)), toYaml(buildComponentMap(reversed)));

  const ids = buildComponentMap(graph).components.map((c) => c.id);
  assert.deepEqual(ids, [...ids].sort(), 'components are ordered by id');
});

test('an empty graph still yields a valid map: the workspace components alone', () => {
  const map = buildComponentMap({ nodes: {}, dependencies: {} });
  // A map with no components is an exit-2 error from the binary, which would
  // fail the gate open-endedly on a workspace that has not grown projects yet.
  assert.ok(map.components.length > 0);
  assert.equal(byId(map, 'sdlc-controls-gate').criticality, 'critical', 'the generator governs itself');
});
