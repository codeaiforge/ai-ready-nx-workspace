package com.codeaiforge.reconciliation.service;

import org.springframework.boot.security.autoconfigure.actuate.web.servlet.EndpointRequest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Provisional security configuration.
 *
 * <p>Its only job today is to let the deploy verify gate reach {@code /actuator/health}
 * unauthenticated, per docs/specs/stack.md. Everything else stays authenticated by default.
 *
 * <p>See ADR-0005 (docs/adr/0005-unauthenticated-health-endpoint.md) for why health is
 * unauthenticated and nothing else is exposed.
 *
 * <p>Roadmap task 2.4 (Role-based access control, NFR-2.1) owns the real policy and is expected to
 * replace this class, carrying the ADR-0005 rule forward. Do not build on it.
 */
@Configuration
class SecurityConfig {

  @Bean
  SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    return http.authorizeHttpRequests(
            auth ->
                auth.requestMatchers(EndpointRequest.to("health"))
                    .permitAll()
                    .anyRequest()
                    .authenticated())
        .httpBasic(basic -> {})
        .build();
  }
}
