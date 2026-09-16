package com.codeaiforge.reconciliation.service;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;

@Import(TestcontainersConfiguration.class)
@SpringBootTest
class ReconciliationServiceApplicationTests {

  @Test
  void contextLoads(org.springframework.context.ApplicationContext context) {
    // A context that loads but wires nothing is a green test proving very little.
    assertThat(context.getBeanDefinitionCount()).isPositive();
  }
}
