package com.codeaiforge.reconciliation.service;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

/**
 * Supplies the Postgres instance integration tests run against, per the "Integration test harness"
 * row in docs/specs/stack.md. {@code @ServiceConnection} wires the container's JDBC URL, user, and
 * password into the context, so no datasource properties are needed in application.properties.
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
