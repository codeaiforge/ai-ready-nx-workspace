package com.codeaiforge.reconciliation.core.money;

import java.util.Currency;
import java.util.Objects;

/**
 * A monetary amount held as integer minor units (cents, pence) in an ISO-4217 currency.
 *
 * <p>Reconciliation compares amounts for exact equality, so no floating point is used anywhere:
 * {@code 0.1 + 0.2} in binary floating point is not {@code 0.3}, and a settlement file that fails
 * to match on a rounding artefact is indistinguishable from a real break.
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
   * @throws IllegalArgumentException if the currencies differ — cross-currency arithmetic is a
   *     defect, not something to silently coerce
   * @throws ArithmeticException if the result overflows
   */
  public Money plus(Money other) {
    if (!currency.equals(other.currency)) {
      throw new IllegalArgumentException(
          "cannot add %s to %s"
              .formatted(other.currency.getCurrencyCode(), currency.getCurrencyCode()));
    }
    return new Money(Math.addExact(minorUnits, other.minorUnits), currency);
  }
}
