import '../features/transactions/domain/transaction_item.dart';

/// Bounds apply before any restored data replaces the current database.
class RecurrenceLimits {
  static const maxRules = 200;
  static const maxCatchUp = 10000;
  static const maxRows = 100000;

  static void date(DateTime value, DateTime now) {
    if (value.isBefore(DateTime(2000)) ||
        !value.isBefore(DateTime(now.year + 21))) {
      throw const FormatException('La fecha está fuera del periodo admitido.');
    }
  }

  static int catchUp(
    DateTime due,
    RecurrenceFrequency frequency,
    DateTime now,
  ) {
    date(due, now);
    final today = DateTime(now.year, now.month, now.day);
    if (due.isAfter(today)) return 0;
    if (frequency == RecurrenceFrequency.none) {
      throw const FormatException('Programación inválida.');
    }
    if (frequency == RecurrenceFrequency.monthly) {
      // Conservative upper bound, independent of month-end anchor adjustments.
      return (today.year - due.year) * 12 + today.month - due.month + 1;
    }
    return today.difference(due).inDays ~/
            (frequency == RecurrenceFrequency.weekly ? 7 : 14) +
        1;
  }

  static void totals(int rules, int occurrences) {
    if (rules > maxRules || occurrences > maxCatchUp) {
      throw const FormatException(
        'La programación supera el límite de repeticiones. Revisa las fechas antes de continuar.',
      );
    }
  }
}
