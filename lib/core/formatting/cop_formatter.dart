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
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return null;
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
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final parsed = CopFormatter.parseDigits(digits);
    if (parsed == null) return oldValue;
    final formatted = CopFormatter.formatDigits(parsed);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
