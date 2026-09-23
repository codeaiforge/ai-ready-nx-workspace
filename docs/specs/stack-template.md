# Stack Profile — `<stack name>`

Defines the language- and framework-specific commands and conventions that the SDLC
pipeline (`.github/prompts/run-task.prompt.md`) invokes **by reference**. The pipeline
orchestration — phases, tiers, gates, roles, commit checkpoint — is stack-neutral;
everything a phase needs to *do concretely* for a given stack lives here.

**One active profile per project/branch**, at `docs/specs/stack.md`. Copy this template to
that path and fill every field. A different branch = a different `stack.md`; the pipeline on
`main` is never edited per stack.

> The build/impact engine stays **Nx** across stacks (it delegates to the underlying build
> tool via `@nx/js`, `@nx/gradle`, etc.). This profile fills in the language/framework
> specifics Nx does not know about.

## Identity

| Field | Value |
| ----- | ----- |
| Language | <e.g. TypeScript 5 / Java 21> |
| Framework | <e.g. Next.js 15 / Spring Boot 3> |
| Nx plugin | <e.g. @nx/js / @nx/gradle> |
| Package / dependency manager | <e.g. pnpm / Gradle> |

## Commands

The pipeline calls these by name. Fill each with the concrete command for this stack.

| Purpose | Command |
| ------- | ------- |
| Scaffold new lib/module | <e.g. `pnpm nx g @nx/js:lib …` / `pnpm nx g @nx/gradle:app …`> |
| Affected lint/test/build (main gate) | <e.g. `pnpm nx affected -t lint,test,build`> |
| Affected tests only | <e.g. `pnpm nx affected -t test`> |
| Dependency vulnerability audit | <e.g. `pnpm audit` / `pnpm nx affected -t dependency-check` (OWASP)> |

## Conventions (per layer)

Fill each. Mark `N/A` for a layer this stack does not have, and `Not selected` for one it
has but has not decided — the pipeline skips the first and surfaces the second.

| Concern | This stack's mechanism |
| ------- | ---------------------- |
| Validation / contracts | <e.g. Zod schemas / Jakarta Bean Validation + records> |
| Data access | <e.g. Drizzle ORM, no raw SQL / Spring Data JPA, no raw SQL> |
| Migrations + verify | <e.g. Drizzle migrations, `supabase status` / Flyway, `./gradlew flywayInfo`> |
| Access control | <e.g. Postgres RLS per table / Spring Security method + row rules> |
| Module / layer structure | <e.g. FSD (frontend) / package-by-feature or hexagonal> |
| Auth mechanism | <e.g. Supabase-native sessions & tokens / Spring Security + OAuth2/JWT> |
| Test fixtures location | <e.g. `__fixtures__/` / `src/test/resources/fixtures`> |
| Integration test harness | <e.g. local Supabase / Testcontainers> |

## Deploy

| Field | Value |
| ----- | ----- |
| Target | <e.g. Vercel / container image to registry → k8s> |
| Preview / verify gate | <e.g. Vercel preview URL verified / staging smoke test> |
| Merge strategy | <e.g. squash-merge to `main`> |

## Notes

- Every row needs a value, and three kinds count as one:
  - a concrete command or convention;
  - `N/A — <why>`: the check does not apply to this stack, so the pipeline **skips** it;
  - `Not selected — <who decides it>`: it applies and is undecided, so the pipeline
    **surfaces** it instead. An outstanding decision is a finding, not an exemption, and
    collapsing the two into `N/A` is how a decision nobody made becomes a check nobody runs.
- Do not delete a row, and do not leave one blank. A deleted row cannot be looked up by the
  name a phase reads, and a blank one is indistinguishable from both markers above. Either
  way the phase check is skipped in silence, which is the one thing none of the three mean.