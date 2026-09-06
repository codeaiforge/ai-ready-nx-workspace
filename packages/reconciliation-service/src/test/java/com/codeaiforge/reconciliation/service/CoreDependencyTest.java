package com.codeaiforge.reconciliation.service;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.codeaiforge.reconciliation.core.money.Money;
import org.junit.jupiter.api.Test;

/**
 * Exercises the service -> core dependency for real.
 *
 * <p>The Nx `link` generator only records `implicitDependencies` in project.json, which makes `nx
 * affected` ripple without the service being able to compile against core. This test fails to
 * compile if the Maven dependency is ever dropped, so the graph edge and the build edge cannot
 * silently diverge.
 */
class CoreDependencyTest {

  @Test
  void consumesTheSharedDomainModel() {
    assertEquals(Money.of(300, "EUR"), Money.of(100, "EUR").plus(Money.of(200, "EUR")));
  }
}
