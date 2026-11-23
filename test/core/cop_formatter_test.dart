import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_bolsillo/core/formatting/cop_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  group('CopFormatter', () {
    test('formats integer COP amounts with Colombian dot separators', () {
      expect(CopFormatter.format(1250000), '\$1.250.000 COP');
      expect(CopFormatter.format(2400000), '\$2.400.000 COP');
      expect(CopFormatter.format(1930000), '\$1.930.000 COP');
      expect(CopFormatter.format(-100000), '-\$100.000 COP');
    });

    test('formats signed amounts explicitly for income and expense', () {
      expect(
        CopFormatter.formatSigned(480000, isPositive: true),
        '+\$480.000 COP',
      );
      expect(
        CopFormatter.formatSigned(950000, isPositive: false),
        '-\$950.000 COP',
      );
    });

    test('parses user digits into integer without floating point', () {
      expect(CopFormatter.parseDigits('1.250.000'), 1250000);
      expect(CopFormatter.parseDigits('\$ 480.000 COP'), 480000);
      expect(CopFormatter.parseDigits(''), isNull);
    });
  });
}
