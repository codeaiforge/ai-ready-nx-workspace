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
