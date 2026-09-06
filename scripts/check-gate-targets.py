#!/usr/bin/env python3
"""Assert every Nx target named in docs/specs/stack.md actually exists in the graph.

`nx run-many` and `nx affected` silently skip targets that do not exist. A gate naming a
missing target therefore reports success having checked nothing — which has happened four
times in this workspace (check-format, CI's lint/typecheck, and dependency-check). That
failure is invisible in CI output, so it needs an explicit assertion.

Run from the workspace root. Exits non-zero, naming the offenders, if any target referenced
by the stack profile is absent from every project.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

STACK = Path("docs/specs/stack.md")

# Targets named by the pipeline but supplied by Nx itself rather than a project.
IGNORED = {"graph"}


def stack_targets(text: str) -> set[str]:
    """Target names the stack profile tells the pipeline to run."""
    found: set[str] = set()

    # `nx affected -t a,b,c` / `nx run-many -t a b c`
    for match in re.finditer(r"-t\s+([a-z0-9,\s-]+)", text):
        for name in re.split(r"[,\s]+", match.group(1).strip()):
            if name and not name.startswith("-"):
                found.add(name)

    # `nx run <project>:<target>`
    for match in re.finditer(r"nx run\s+\S+?:([a-z0-9-]+)", text):
        found.add(match.group(1))

    return found - IGNORED


def graph_targets() -> dict[str, set[str]]:
    """Every target defined on every project in the graph."""
    projects = json.loads(
        subprocess.run(
            ["pnpm", "exec", "nx", "show", "projects", "--json"],
            capture_output=True, text=True, check=True,
        ).stdout
    )
    out: dict[str, set[str]] = {}
    for project in projects:
        detail = json.loads(
            subprocess.run(
                ["pnpm", "exec", "nx", "show", "project", project, "--json"],
                capture_output=True, text=True, check=True,
            ).stdout
        )
        out[project] = set(detail.get("targets", {}))
    return out


def main() -> int:
    if not STACK.is_file():
        print(f"ERROR: {STACK} not found — run from the workspace root.", file=sys.stderr)
        return 2

    wanted = stack_targets(STACK.read_text())
    if not wanted:
        print(f"ERROR: no targets parsed from {STACK}; the parser is broken.", file=sys.stderr)
        return 2

    by_project = graph_targets()
    if not by_project:
        print("No projects in the graph; nothing to check.")
        return 0

    defined = set().union(*by_project.values())
    missing = sorted(wanted - defined)

    for name in sorted(wanted):
        holders = [p for p, t in by_project.items() if name in t]
        status = ", ".join(holders) if holders else "NOT DEFINED ON ANY PROJECT"
        print(f"  {name:<20} {status}")

    if missing:
        print(
            "\nERROR: docs/specs/stack.md names target(s) that exist nowhere: "
            + ", ".join(missing)
            + "\nNx skips unknown targets silently, so a gate using these passes without"
            "\nrunning them. Define the target, or remove it from the stack profile.",
            file=sys.stderr,
        )
        return 1

    print(f"\nAll {len(wanted)} targets named in {STACK} exist.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
