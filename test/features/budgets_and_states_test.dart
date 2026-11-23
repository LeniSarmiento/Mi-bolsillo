import 'package:material_ui/material_ui.dart';

import '../support/finance_fixture.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_bolsillo/core/routing/app_routes.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  String initialLocation = AppRoutes.budgets,
}) async {
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await pumpFinance(tester, initialLocation);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  testWidgets(
    'Budgets screen displays 80% warning and Agotado states, and creates new budget',
    (tester) async {
      await _pumpApp(tester, initialLocation: AppRoutes.budgets);

      expect(find.textContaining('Alerta 80%'), findsOneWidget);
      expect(find.textContaining('Agotado'), findsOneWidget);

      await tester.tap(find.text('Crear nuevo presupuesto'));
      await tester.pumpAndSettle();

      expect(find.text('Crear presupuesto'), findsOneWidget);
      await tester.tap(find.text('Salud'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Guardar presupuesto'));
      await tester.tap(find.text('Guardar presupuesto'));
      await tester.pumpAndSettle();

      expect(find.text('Salud'), findsOneWidget);
    },
  );

  testWidgets(
    'Pending movements screen confirms detected expense into ledger',
    (tester) async {
      await _pumpApp(tester, initialLocation: AppRoutes.autoDetection);

      expect(find.text('Detección automática'), findsOneWidget);
      await tester.tap(find.textContaining('Movimientos pendientes'));
      await tester.pumpAndSettle();

      expect(find.text('Éxito Calle 80'), findsOneWidget);
      await tester.ensureVisible(find.text('Confirmar').first);
      await tester.tap(find.text('Confirmar').first);
      await tester.pumpAndSettle();

      expect(
        find.text('"Éxito Calle 80" agregado a tus movimientos'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Analysis screen renders category donut breakdown and switches periods',
    (tester) async {
      await _pumpApp(tester, initialLocation: AppRoutes.analysis);

      expect(find.text('Gastos por Categoría'), findsOneWidget);
      expect(find.text('Alimentación'), findsOneWidget);

      await tester.tap(find.text('Anual'));
      await tester.pumpAndSettle();
      expect(find.text('Flujo de Dinero (Anual)'), findsOneWidget);
    },
  );
}
