// ADR numbering check.
//
// Two ADR-0001s reached this repository — one on main, one on a stack branch —
// because .ai/standards/adr.md said "allocate the next free NNNN" and nothing
// read it. A numbering rule nothing checks is a convention, not a control.
//
//   node tools/adr/check-numbering.mjs
//
// Exits 1 on: a number used twice, a filename that disagrees with its title, or
// a number outside every declared block.

import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

/** The blocks declared in .ai/standards/adr.md. A new stack branch claims the
 *  next free hundred in both places. */
const BLOCKS = [
  { from: 1, to: 99, scope: 'framework (main)' },
  { from: 101, to: 199, scope: 'stack branch 1' },
  { from: 201, to: 299, scope: 'stack branch 2' },
];

const DIR = 'docs/adr';
const FILE_RE = /^(\d{4})-(.+)\.md$/;
// "# ADR-0101: Drive the Maven build through Nx"
const TITLE_RE = /^#\s*ADR-(\d{4})\b/m;

const problems = [];
const seen = new Map();

const files = readdirSync(DIR)
  .filter((f) => FILE_RE.test(f))
  .sort();
for (const file of files) {
  const num = Number(FILE_RE.exec(file)[1]);
  // 0000 is the reserved template, deliberately outside every block.
  if (num === 0) continue;

  const prev = seen.get(num);
  if (prev) {
    problems.push(
      `ADR-${String(num).padStart(4, '0')} is used twice: ${prev} and ${file}`
    );
  } else {
    seen.set(num, file);
  }

  const body = readFileSync(join(DIR, file), 'utf8');
  const title = TITLE_RE.exec(body);
  if (!title) {
    problems.push(`${file}: no "# ADR-NNNN:" heading`);
  } else if (Number(title[1]) !== num) {
    // A renamed file whose title was not renamed still reads as the old ADR
    // everywhere the title is quoted.
    problems.push(
      `${file}: filename says ${num}, title says ${Number(title[1])}`
    );
  }

  if (!BLOCKS.some((b) => num >= b.from && num <= b.to)) {
    problems.push(
      `${file}: ADR-${String(num).padStart(
        4,
        '0'
      )} is outside every declared block ` +
        `(${BLOCKS.map((b) => `${b.from}-${b.to}`).join(
          ', '
        )}) — see .ai/standards/adr.md`
    );
  }
}

if (files.length === 0) problems.push(`${DIR} contains no ADRs`);

for (const p of problems) console.error(`  ${p}`);
console.log(
  problems.length === 0
    ? `ADR numbering OK — ${seen.size} ADR(s), no duplicates, all inside a declared block`
    : `ADR numbering FAILED — ${problems.length} problem(s)`
);
process.exit(problems.length === 0 ? 0 : 1);
