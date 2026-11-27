import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Colombian Peso (COP) formatter using integer amounts only (never double).
abstract final class CopFormatter {
  static final NumberFormat _numberFormat = NumberFormat('#,##0', 'es_CO');

  /// Formats an integer COP amount as `$1.250.000 COP` or `-$950.000 COP`.
  static String format(int amountCop, {bool includeCurrency = true}) {
    final isNegative = amountCop < 0;
    final formattedDigits = _numberFormat.format(amountCop.abs());
    final prefix = isNegative ? '-\$' : '\$';
    return includeCurrency
        ? '$prefix$formattedDigits COP'
        : '$prefix$formattedDigits';
  }

  /// Formats a positive magnitude with explicit sign: `+$480.000 COP` or `-$950.000 COP`.
  static String formatSigned(
    int amountCop, {
    required bool isPositive,
    bool includeCurrency = true,
  }) {
    final formattedDigits = _numberFormat.format(amountCop.abs());
    final sign = isPositive ? '+\$' : '-\$';
    return includeCurrency
        ? '$sign$formattedDigits COP'
        : '$sign$formattedDigits';
  }

  /// Formats digits only with Colombian dot separators: `2.400.000`.
  static String formatDigits(int amountCop) {
    return _numberFormat.format(amountCop.abs());
  }

  /// Parses user-entered COP text into an integer. Returns null if empty/invalid.
  static int? parseDigits(String raw) {
    final match = RegExp(
      r'^(?:COP\s*)?\$?\s*((?:\d{1,3}(?:\.\d{3})+|\d+))(?:,00)?(?:\s*COP)?$',
      caseSensitive: false,
    ).firstMatch(raw.trim());
    if (match == null) return null;
    final digitsOnly = match.group(1)!.replaceAll('.', '');
    final value = int.tryParse(digitsOnly);
    return value != null && value <= 9007199254740991 ? value : null;
  }

  /// Formats integer COP input live with thousands separators while typing.
  static TextInputFormatter get inputFormatter => _CopThousandsInputFormatter();
}

class _CopThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(text: '');
    }
    var parsed = CopFormatter.parseDigits(newValue.text);
    // A single digit edit can temporarily break existing thousands groups.
    // Only normalize that edit; pasted malformed/decimal text stays invalid
    // and visible so the form cannot silently save a different amount.
    if (parsed == null && CopFormatter.parseDigits(oldValue.text) != null) {
      var prefix = 0;
      while (prefix < oldValue.text.length &&
          prefix < newValue.text.length &&
          oldValue.text[prefix] == newValue.text[prefix]) {
        prefix++;
      }
      var oldEnd = oldValue.text.length;
      var newEnd = newValue.text.length;
      while (oldEnd > prefix &&
          newEnd > prefix &&
          oldValue.text[oldEnd - 1] == newValue.text[newEnd - 1]) {
        oldEnd--;
        newEnd--;
      }
      final inserted = newValue.text.substring(prefix, newEnd);
      final removed = oldEnd - prefix;
      if ((RegExp(r'^\d$').hasMatch(inserted) && removed <= 1) ||
          (inserted.isEmpty && removed == 1)) {
        parsed = CopFormatter.parseDigits(newValue.text.replaceAll('.', ''));
      }
    }
    if (parsed == null) return newValue;
    final formatted = CopFormatter.formatDigits(parsed);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
