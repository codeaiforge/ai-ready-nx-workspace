# ADR-0001: Drive the Maven build through Nx as the impact engine

- **Status**: Accepted
- **Date**: 2026-09-06
- **Deciders**: Architect, DevOps Engineer
- **Trace**: Infra

## Context

The workspace is an Nx monorepo whose governance layer treats the Nx project graph as the
canonical architecture (see the Authority Order in the root README). The services in this
demo are Java, built by Maven. Two build systems now describe the same repository, and they
can disagree about what depends on what.

That disagreement matters beyond tidiness: the SDLC pipeline's quality gate is expressed as
an affected-set (`nx affected -t check-format,test,build`). If the Nx graph does not reflect
real Maven dependencies, the gate either runs too much — making CI slow enough that people
route around it — or too little, which lets a change land without its dependents being
rebuilt.

## Decision

We will keep Nx as the build and impact engine and delegate execution to Maven, using
`@nxrocks/nx-spring-boot` to infer Nx targets and dependency edges from each `pom.xml`. An
inter-project dependency is declared **once**, as a Maven `<dependency>`; the plugin derives
the Nx graph edge from it. `implicitDependencies` is not used.

## Options Considered

- **Option A — Nx as impact engine, Maven executes (chosen)**: one gate expression across a
  polyglot workspace; Nx caching and affected apply to Java, and the graph is derived from
  the build files rather than asserted alongside them. Costs a plugin dependency, and the
  plugin is third-party with known defects — its format-target inference is gated on an
  inverted condition.
- **Option B — Maven multi-module reactor, Nx unaware of Java**: idiomatic for Java teams
  and no plugin needed, but the governance layer loses sight of the Java projects entirely.
  `affected` cannot see them, so the pipeline's gate would have to be expressed differently
  per stack — which contradicts having a single stack-agnostic pipeline.
- **Option C — Gradle with the Nx Gradle plugin**: better Nx integration than Maven, but
  swaps a well-understood build tool for one the target audience uses less, to solve a
  problem Option A already solves.

## Consequences

The pipeline gate is one expression regardless of stack, and Nx caching applies to Maven
builds. `nx graph` becomes a true picture of the system, which is what the governance layer
assumes.

Because the edge is derived rather than asserted, the graph cannot outlive the dependency:
removing the Maven `<dependency>` removes the edge in the same act. The rejected alternative
— the plugin's `link` generator, which writes `implicitDependencies` into `project.json` —
would have created a second, independent claim that keeps rippling for a dependency the code
no longer has. `CoreDependencyTest` in the service additionally makes the removal a compile
failure rather than a silent one.

We also inherit the plugin's defects. Format targets are declared explicitly in each
`project.json` rather than inferred, because inference is unreliable — and `nx run-many`
silently skips targets that do not exist, so an unnoticed inference failure would present as
a passing gate.
