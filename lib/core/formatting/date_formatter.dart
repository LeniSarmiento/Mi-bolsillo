import 'package:intl/intl.dart';

/// Colombian Spanish date and time formatting helpers using `intl`.
abstract final class DateFormatter {
  static String dayGroupHeader(DateTime date, {DateTime? reference}) {
    final now = reference ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final dayMonth = _capitalize(
      DateFormat("d 'de' MMMM", 'es_CO').format(date),
    );
    if (target == today) {
      return 'Hoy — $dayMonth';
    }
    if (target == today.subtract(const Duration(days: 1))) {
      return 'Ayer — $dayMonth';
    }
    return dayMonth;
  }

  static String shortDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'es_CO').format(date);
  }

  static String shortDateTime(DateTime date) {
    final dayPart = DateFormat('d MMM', 'es_CO').format(date);
    final timePart = DateFormat('h:mm a', 'es_CO').format(date);
    return '$dayPart · $timePart';
  }

  static String monthYear(DateTime date) {
    return _capitalize(DateFormat('MMMM yyyy', 'es_CO').format(date));
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
