# Stack Profile — Java Spring Boot (microservices)

Active profile consumed by `.github/prompts/run-task.prompt.md`. Nx stays the build/impact
engine via `@nxrocks/nx-spring-boot` (verified loading on Nx 22.5.1); this profile fills in the
Spring/Java specifics. Place at `docs/specs/stack.md` on the Java demo branch.

## Identity

| Field                        | Value                                                 |
| ---------------------------- | ----------------------------------------------------- |
| Language                     | Java 25 (LTS)                                         |
| Framework                    | Spring Boot 4 (microservices)                         |
| Nx plugin                    | `@nxrocks/nx-spring-boot` (v11.x)                     |
| Package / dependency manager | Maven (via generated `./mvnw`; Gradle also supported) |

## Commands

The pipeline calls these by name. Each executor runs the embedded `./mvnw`/`./gradlew`
(add `--ignoreWrapper` in CI to use a preinstalled `mvn`/`gradle`).

| Purpose                              | Command                                                                                                                                                                                                                                                                                                                                                                                                       |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Scaffold new lib/module              | `nx g @nxrocks/nx-spring-boot:project <path> --projectType application\|library --buildSystem maven-project --javaVersion 25 --dependencies <comma-list>` (add `--proxyUrl <url>` behind a corporate proxy)                                                                                                                                                                                                   |
| Link a dependency edge               | `nx g @nxrocks/nx-spring-boot:link --sourceProjectName <app> --targetProjectName <lib>`                                                                                                                                                                                                                                                                                                                       |
| Affected lint/test/build (main gate) | `nx affected -t check-format,test,build`                                                                                                                                                                                                                                                                                                                                                                      |
| Affected tests only                  | `nx affected -t test`                                                                                                                                                                                                                                                                                                                                                                                         |
| Dependency vulnerability audit       | `nx affected -t dependency-check` — generates a CycloneDX SBOM then scans it with `osv-scanner`. Scans the full transitive tree; a direct-dependency scan misses most Java CVEs. Exits non-zero on findings. Human-gated at Phase 6 of Complex-tier tasks, deliberately **not** part of the CI gate: an unfixable upstream CVE would pin the build red and remove the accept/mitigate decision from the human |

> `build` auto-runs the `install` executor on dependency libraries first (publishes their jar to
> `~/.m2`), so inter-service dependencies resolve without a manual step.

## Conventions (per layer)

| Concern                  | This stack's mechanism                                                                            |
| ------------------------ | ------------------------------------------------------------------------------------------------- |
| Validation / contracts   | Jakarta Bean Validation (`@Valid`, constraint annotations) on records/DTOs                        |
| Data access              | Spring Data JPA repositories — no raw SQL; native queries only where justified and reviewed       |
| Migrations + verify      | Flyway migrations under `src/main/resources/db/migration`; verify with `./mvnw flyway:info`       |
| Access control           | Spring Security — method security (`@PreAuthorize`) + per-request authorization rules             |
| Module / layer structure | Package-by-feature; hexagonal (ports/adapters) for services with external integrations            |
| Auth mechanism           | Spring Security Resource Server — JWT/OAuth2 bearer tokens; no session state (stateless services) |
| Test fixtures location   | `src/test/resources/fixtures`                                                                     |
| Integration test harness | Testcontainers (Postgres, Kafka, etc.) via `@SpringBootTest` slices                               |

## Deploy

| Field                 | Value                                                                                                                                                                         |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Target                | OCI image via `nx run <service>:build-image` (Cloud Native Buildpacks). Built locally; no registry is configured — pushing is out of scope, see docs/architecture/overview.md |
| Preview / verify gate | `docker compose up -d --wait` (service + Postgres, see compose.yaml), then `curl -fsS localhost:8080/actuator/health`, then `docker compose down -v`                          |
| Merge strategy        | Squash-merge to `main`                                                                                                                                                        |

## Notes

- **Prerequisites** the pipeline assumes present: **JDK 25** on PATH, `osv-scanner` for the
  dependency audit (Complex tier only), a running
  **Docker** daemon (Testcontainers backs the integration tests), and — only when generating
  new projects — network reachability to `start.spring.io` (use `--proxyUrl` / `HTTP(S)_PROXY`
  inside a bank network). Formatting needs Spotless >= 2.44 with an explicitly pinned
  `google-java-format`; the version bundled with older Spotless calls a javac internal that
  changed after 21 and fails on 25.
- Layers not present in a given service (e.g. `frontend`) are `N/A` — the pipeline skips those
  per-layer checks. Do not delete rows; mark `N/A`.
- Each microservice is its own Nx `application` project; shared code lives in `library` projects
  linked via the `link` generator so `nx affected` ripples across service boundaries.
