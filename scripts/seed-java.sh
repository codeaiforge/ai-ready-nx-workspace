#!/usr/bin/env bash
# Seed the Payment Reconciliation slice so the Nx graph is non-empty and `affected`
# ripples across projects — the Java equivalent of seed-demo.sh, aligned to the names
# the implementation-roadmap builds into.
#
#   reconciliation-core     (library)     — pure domain: Money value objects, matching engine
#   reconciliation-service  (application) — Spring Boot: ingestion API, JPA/Flyway, audit, security
#   service --link--> core
#
# Uses @nxrocks/nx-spring-boot (verified loading on Nx 22.5.1). Generation calls
# Spring Initializr (start.spring.io), so this needs:
#   - JDK 25 on PATH
#   - Docker running (Testcontainers is the integration test harness per docs/specs/stack.md)
#   - network to start.spring.io  (behind a corporate proxy, export PROXY_URL first)
#
# Run from the workspace root:  bash scripts/seed-java.sh
# Installs dependencies and the Nx plugin itself. Idempotent — re-running skips any
# project that already exists, so it is safe to re-run after a partial failure.
#
# Once the generated projects are committed, this script is maintainer-only: it records
# how packages/ was produced. Contributors only need `pnpm install`.
set -euo pipefail
export NX_DAEMON=false

GROUP="com.codeaiforge.reconciliation"
PROXY_ARG=""
if [ -n "${PROXY_URL:-}" ]; then PROXY_ARG="--proxyUrl ${PROXY_URL}"; fi

# --- preflight: fail here, with a readable message, rather than inside Maven ---

fail() { echo "ERROR: $*" >&2; exit 1; }

command -v pnpm >/dev/null 2>&1 || fail "pnpm not on PATH. Install Node 20+ and pnpm first."
command -v java >/dev/null 2>&1 || fail "No JDK on PATH. This seed needs a JDK 25."
command -v python3 >/dev/null 2>&1 || fail "python3 not on PATH (used to patch the generated pom)."

JAVA_MAJOR="$(java -version 2>&1 | sed -n '1s/.*version "\([0-9]*\).*/\1/p')"
if [ "${JAVA_MAJOR:-0}" -lt 25 ]; then
  fail "JDK ${JAVA_MAJOR:-unknown} on PATH; this demo compiles with release 25 (see .tool-versions)."
fi

docker info >/dev/null 2>&1 || {
  echo "WARN: Docker is not running. Generation will succeed, but the Testcontainers" >&2
  echo "      integration tests in docs/specs/stack.md cannot run without it." >&2
}

curl -sSf -o /dev/null --max-time 10 https://start.spring.io/actuator/health 2>/dev/null || {
  echo "WARN: start.spring.io not reachable. If generation fails, set PROXY_URL and re-run." >&2
}

# --- dependencies ---

# `pnpm ls` exits 0 whether or not the package is found, so test package.json —
# it is the source of truth and readable before node_modules exists.
if grep -q '"@nxrocks/nx-spring-boot"' package.json; then
  echo "==> @nxrocks/nx-spring-boot already declared"
  echo "==> installing workspace dependencies"
  pnpm install
else
  echo "==> installing workspace dependencies"
  pnpm install
  echo "==> installing @nxrocks/nx-spring-boot"
  pnpm add -D -w @nxrocks/nx-spring-boot
fi

# --- generation (idempotent: skip what already exists) ---

if [ -d packages/reconciliation-core ]; then
  echo "==> reconciliation-core exists, skipping"
else
  echo "==> shared domain library: reconciliation-core"
  pnpm exec nx g @nxrocks/nx-spring-boot:project packages/reconciliation-core \
    --projectType library --buildSystem maven-project --javaVersion 25 \
    --groupId "$GROUP" --artifactId reconciliation-core \
    --name reconciliation-core --packageName "$GROUP.core" \
    --skipFormat false \
    --dependencies "validation" $PROXY_ARG --no-interactive
fi

if [ -d packages/reconciliation-service ]; then
  echo "==> reconciliation-service exists, skipping"
else
  echo "==> service application: reconciliation-service"
  pnpm exec nx g @nxrocks/nx-spring-boot:project packages/reconciliation-service \
    --projectType application --buildSystem maven-project --javaVersion 25 \
    --groupId "$GROUP" --artifactId reconciliation-service \
    --name reconciliation-service --packageName "$GROUP.service" \
    --skipFormat false \
    --dependencies "web,validation,data-jpa,security,flyway,postgresql" $PROXY_ARG --no-interactive
fi

# The link generator writes `implicitDependencies` onto the TARGET project, naming the
# SOURCE — i.e. target depends on source, the inverse of how the schema description reads.
# So to get `service depends on core`, core is the source and service is the target.
# It touches project.json only, never the pom, and re-running duplicates the entry —
# so guard on the edge already being present.
if grep -q "reconciliation-core" packages/reconciliation-service/project.json 2>/dev/null; then
  echo "==> link already present, skipping"
else
  echo "==> link the service to the shared library (creates the Nx dependency edge)"
  pnpm exec nx g @nxrocks/nx-spring-boot:link \
    --sourceProjectName reconciliation-core --targetProjectName reconciliation-service \
    --no-interactive
fi

# --- make the formatter work on a modern JDK ---
#
# The generator writes Spotless 2.23.0 with a bare <googleJavaFormat/>. That bundles a
# formatter version which calls com.sun.tools.javac.util.Log$DeferredDiagnosticHandler
# .getDiagnostics() — removed after JDK 21 — so spotless:check/apply die with
# NoSuchMethodError on 25. Bumping Spotless and pinning the formatter fixes it.

if grep -q "1.28.0" packages/reconciliation-core/pom.xml; then
  echo "==> spotless already modernized, skipping"
else
  echo "==> bumping spotless + pinning google-java-format for JDK 25"
  python3 - <<'PYEOF'
for proj in ("reconciliation-core", "reconciliation-service"):
    p = f"packages/{proj}/pom.xml"
    s = open(p).read()
    s = s.replace("<version>2.23.0</version>", "<version>2.44.5</version>")
    s = s.replace("<googleJavaFormat/>", "<googleJavaFormat><version>1.28.0</version></googleJavaFormat>")
    open(p, "w").write(s)
PYEOF
fi

# --- make the dependency REAL at the Maven level ---
#
# The `link` generator only writes `implicitDependencies` into project.json — an Nx-graph
# assertion. Without a <dependency> in the service pom, `nx affected` ripples but the
# service cannot actually import core's classes, so the demo would show orchestration
# without real code reuse. Nx runs core's `install` target first, publishing its jar.

if grep -q "reconciliation-core" packages/reconciliation-service/pom.xml; then
  echo "==> Maven dependency on core already present, skipping"
else
  echo "==> adding the Maven dependency: service -> core"
  python3 - <<'PYEOF'
p = "packages/reconciliation-service/pom.xml"
s = open(p).read()
dep = """\t\t<dependency>
\t\t\t<groupId>com.codeaiforge.reconciliation</groupId>
\t\t\t<artifactId>reconciliation-core</artifactId>
\t\t\t<version>0.0.1-SNAPSHOT</version>
\t\t</dependency>
"""
anchor = "\t<dependencies>\n"
assert s.count(anchor) == 1, f"expected one <dependencies>, got {s.count(anchor)}"
open(p, "w").write(s.replace(anchor, anchor + dep, 1))
PYEOF
fi

# --- wire Testcontainers into the service (Initializr cannot do this) ---
#
# The service is generated with data-jpa + flyway + postgresql but no datasource, so the
# default `contextLoads` test cannot start a context and the build gate is red out of the
# box. docs/specs/stack.md names Testcontainers as the integration test harness, so supply
# a Postgres container via @ServiceConnection.
#
# NOTE Testcontainers 2.x (managed by Spring Boot 4's parent) renamed the artifacts:
#      postgresql -> testcontainers-postgresql, junit-jupiter -> testcontainers-junit-jupiter.

SVC_PKG=packages/reconciliation-service/src/test/java/com/codeaiforge/reconciliation/service
if [ -f "$SVC_PKG/TestcontainersConfiguration.java" ]; then
  echo "==> Testcontainers already wired, skipping"
else
  echo "==> wiring Testcontainers (Postgres) into reconciliation-service"

  python3 - <<'PYEOF'
p = "packages/reconciliation-service/pom.xml"
s = open(p).read()
deps = """		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-testcontainers</artifactId>
			<scope>test</scope>
		</dependency>
		<dependency>
			<groupId>org.testcontainers</groupId>
			<artifactId>testcontainers-postgresql</artifactId>
			<scope>test</scope>
		</dependency>
		<dependency>
			<groupId>org.testcontainers</groupId>
			<artifactId>testcontainers-junit-jupiter</artifactId>
			<scope>test</scope>
		</dependency>
	</dependencies>"""
close = "\t</dependencies>"
assert s.count(close) == 1, f"expected one </dependencies>, got {s.count(close)}"
open(p, "w").write(s.replace(close, deps, 1))
PYEOF

  cat > "$SVC_PKG/TestcontainersConfiguration.java" <<'JAVAEOF'
package com.codeaiforge.reconciliation.service;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

/**
 * Supplies the Postgres instance integration tests run against, per the
 * "Integration test harness" row in docs/specs/stack.md. {@code @ServiceConnection}
 * wires the container's JDBC URL, user, and password into the context, so no
 * datasource properties are needed in application.properties.
 *
 * <p>Requires a running Docker daemon.
 */
@TestConfiguration(proxyBeanMethods = false)
class TestcontainersConfiguration {

    @Bean
    @ServiceConnection
    PostgreSQLContainer<?> postgresContainer() {
        return new PostgreSQLContainer<>(DockerImageName.parse("postgres:16-alpine"));
    }
}
JAVAEOF

  cat > "$SVC_PKG/ReconciliationServiceApplicationTests.java" <<'JAVAEOF'
package com.codeaiforge.reconciliation.service;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;

@Import(TestcontainersConfiguration.class)
@SpringBootTest
class ReconciliationServiceApplicationTests {

    @Test
    void contextLoads() {}
}
JAVAEOF
fi

# --- replace the plugin's library sample with real domain content ---
#
# For a library project the plugin lays down a fixed sample (MyService / ServiceProperties)
# whose class names are hardcoded in its templates — no generator option renames them. Swap
# it for a Money value object, which is what the roadmap has core holding (tasks 1.3/1.4),
# and add a service-side test that actually imports it so the graph edge and the Maven
# dependency cannot silently diverge.

CORE_MONEY=packages/reconciliation-core/src/main/java/com/codeaiforge/reconciliation/core/money
if [ -f "$CORE_MONEY/Money.java" ]; then
  echo "==> core domain content already present, skipping"
else
  echo "==> replacing the library sample with the Money value object"
  rm -rf packages/reconciliation-core/src/main/java/com/codeaiforge/reconciliation/core/service \
         packages/reconciliation-core/src/test/java/com/codeaiforge/reconciliation/core/service
  mkdir -p "$CORE_MONEY" \
           packages/reconciliation-core/src/test/java/com/codeaiforge/reconciliation/core/money

  cat > "$CORE_MONEY/Money.java" <<'JAVAEOF'
package com.codeaiforge.reconciliation.core.money;

import java.util.Currency;
import java.util.Objects;

/**
 * A monetary amount held as integer minor units (cents, pence) in an ISO-4217 currency.
 *
 * <p>Reconciliation compares amounts for exact equality, so no floating point is used
 * anywhere: {@code 0.1 + 0.2} in binary floating point is not {@code 0.3}, and a settlement
 * file that fails to match on a rounding artefact is indistinguishable from a real break.
 */
public record Money(long minorUnits, Currency currency) {

  public Money {
    Objects.requireNonNull(currency, "currency");
  }

  /**
   * @param currencyCode an ISO-4217 alphabetic code, e.g. {@code "EUR"}
   * @throws IllegalArgumentException if the code is not valid ISO-4217
   */
  public static Money of(long minorUnits, String currencyCode) {
    return new Money(minorUnits, Currency.getInstance(currencyCode));
  }

  /**
   * @throws IllegalArgumentException if the currencies differ — cross-currency arithmetic is
   *     a defect, not something to silently coerce
   * @throws ArithmeticException if the result overflows
   */
  public Money plus(Money other) {
    if (!currency.equals(other.currency)) {
      throw new IllegalArgumentException(
          "cannot add %s to %s".formatted(other.currency.getCurrencyCode(), currency.getCurrencyCode()));
    }
    return new Money(Math.addExact(minorUnits, other.minorUnits), currency);
  }
}
JAVAEOF

  cat > packages/reconciliation-core/src/test/java/com/codeaiforge/reconciliation/core/money/MoneyTest.java <<'JAVAEOF'
package com.codeaiforge.reconciliation.core.money;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

class MoneyTest {

  @Test
  void addsAmountsInTheSameCurrency() {
    assertEquals(Money.of(300, "EUR"), Money.of(100, "EUR").plus(Money.of(200, "EUR")));
  }

  @Test
  void rejectsCrossCurrencyAddition() {
    assertThrows(
        IllegalArgumentException.class, () -> Money.of(100, "EUR").plus(Money.of(100, "USD")));
  }

  @Test
  void rejectsUnknownCurrencyCode() {
    assertThrows(IllegalArgumentException.class, () -> Money.of(1, "XYZ123"));
  }

  @Test
  void detectsOverflowRatherThanWrapping() {
    assertThrows(
        ArithmeticException.class, () -> Money.of(Long.MAX_VALUE, "EUR").plus(Money.of(1, "EUR")));
  }
}
JAVAEOF

  cat > packages/reconciliation-service/src/test/java/com/codeaiforge/reconciliation/service/CoreDependencyTest.java <<'JAVAEOF'
package com.codeaiforge.reconciliation.service;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.codeaiforge.reconciliation.core.money.Money;
import org.junit.jupiter.api.Test;

/**
 * Exercises the service -> core dependency for real.
 *
 * <p>The Nx `link` generator only records `implicitDependencies` in project.json, which makes
 * `nx affected` ripple without the service being able to compile against core. This test fails
 * to compile if the Maven dependency is ever dropped, so the graph edge and the build edge
 * cannot silently diverge.
 */
class CoreDependencyTest {

  @Test
  void consumesTheSharedDomainModel() {
    assertEquals(Money.of(300, "EUR"), Money.of(100, "EUR").plus(Money.of(200, "EUR")));
  }
}
JAVAEOF
fi

# --- define the format targets explicitly ---
#
# @nxrocks/nx-spring-boot infers targets from the pom, but its skipFormat condition is
# INVERTED (src/utils/plugin-utils.js): Spotless present => skipFormat=true => the
# format targets are omitted; Spotless absent => they are registered and then fail with
# "No plugin found for prefix 'spotless'". Either way `check-format` — named in the
# docs/specs/stack.md gate — never works, and `nx run-many` SILENTLY SKIPS unknown
# targets, so the gate would look green while never formatting anything. Define them.

echo "==> defining check-format / apply-format targets"
python3 - <<'PYEOF'
import json
for proj in ("reconciliation-core", "reconciliation-service"):
    p = f"packages/{proj}/project.json"
    d = json.load(open(p))
    d.setdefault("targets", {})
    for tgt, goal in (("check-format", "spotless:check"), ("apply-format", "spotless:apply")):
        d["targets"][tgt] = {
            "executor": "nx:run-commands",
            "options": {"command": f"./mvnw -q {goal}", "cwd": f"packages/{proj}"},
        }
    json.dump(d, open(p, "w"), indent=2)
    open(p, "a").write("\n")
PYEOF

echo "==> normalizing formatting of the generated sources"
pnpm exec nx run-many -t apply-format --projects=reconciliation-core,reconciliation-service

# The project.json files above are written with json.dump(indent=2), which puts short
# arrays on multiple lines; prettier collapses them. Without this, a fresh seed leaves
# the workspace failing `nx format:check` — i.e. CI red straight after regeneration.
echo "==> normalizing non-Java formatting (prettier)"
pnpm exec nx format:write

echo "==> projects now in the graph:"
pnpm exec nx show projects

echo "==> ripple proof: mark reconciliation-core changed, expect BOTH affected"
pnpm exec nx show projects --affected --files=packages/reconciliation-core/pom.xml

cat <<'NOTE'

Seed complete.
  - Visual graph:   pnpm exec nx graph   (expect reconciliation-service -> reconciliation-core)
  - Build ripple:   pnpm exec nx affected -t build --base=HEAD
  - Run the service: pnpm exec nx serve reconciliation-service

If `affected` does NOT show both projects, the implicit link did not register —
verify the edge in `nx graph` before building the demo on top of it.
NOTE
