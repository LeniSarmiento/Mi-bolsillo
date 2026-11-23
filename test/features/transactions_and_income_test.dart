import 'package:material_ui/material_ui.dart';

import '../support/finance_fixture.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_bolsillo/core/routing/app_routes.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  String initialLocation = AppRoutes.dashboard,
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
    'RegisterIncome hides success initially and shows snackbar only after saving',
    (tester) async {
      await _pumpApp(tester, initialLocation: AppRoutes.dashboard);

      await tester.ensureVisible(find.text('Registrar ingreso'));
      await tester.tap(find.text('Registrar ingreso'));
      await tester.pumpAndSettle();

      expect(find.text('Registrar ingreso adicional'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(
        find.textContaining('Ingreso adicional guardado correctamente'),
        findsNothing,
      );

      // Trigger validation error first.
      await tester.ensureVisible(find.text('Guardar ingreso'));
      await tester.tap(find.text('Guardar ingreso'));
      await tester.pumpAndSettle();
      expect(
        find.text('Ingresa un monto válido en COP y el motivo del ingreso.'),
        findsOneWidget,
      );

      // Fill valid income and save.
      await tester.enterText(find.byType(TextFormField).at(0), '220000');
      await tester.enterText(find.byType(TextFormField).at(1), 'Bono nocturno');
      await tester.ensureVisible(find.text('Guardar ingreso'));
      await tester.tap(find.text('Guardar ingreso'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ingreso adicional guardado correctamente (+\$220.000 COP)'),
        findsOneWidget,
      );
      expect(find.text('\$2.150.000 COP'), findsWidgets);
    },
  );

  testWidgets(
    'Movimientos supports filters, search empty state, delete dialog, and empty states',
    (tester) async {
      await _pumpApp(tester, initialLocation: AppRoutes.transactions);

      expect(find.text('Supermercado Éxito'), findsOneWidget);
      expect(find.text('Trabajo independiente'), findsOneWidget);

      // Filter: Ingresos adicionales.
      await tester.ensureVisible(find.text('Ingresos adicionales'));
      await tester.tap(find.text('Ingresos adicionales'));
      await tester.pumpAndSettle();
      expect(find.text('Trabajo independiente'), findsOneWidget);
      expect(find.text('Supermercado Éxito'), findsNothing);

      // Search with no results -> Sin resultados state.
      await tester.enterText(find.byType(TextField).first, 'zzzz_no_existe');
      await tester.pumpAndSettle();
      expect(find.text('Sin resultados'), findsOneWidget);
      await tester.ensureVisible(find.text('Limpiar filtros'));
      await tester.tap(find.text('Limpiar filtros'));
      await tester.pumpAndSettle();

      // Delete confirmation dialog on first item.
      await tester.ensureVisible(find.text('Eliminar').first);
      await tester.tap(find.text('Eliminar').first);
      await tester.pumpAndSettle();
      expect(find.text('¿Eliminar movimiento?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();
      expect(find.text('Movimiento eliminado correctamente'), findsOneWidget);
    },
  );

  testWidgets(
    'Clearing data via Profile reveals Sin movimientos and Sin ingresos adicionales states',
    (tester) async {
      await _pumpApp(tester, initialLocation: AppRoutes.profile);

      final clearBtn = find.text('Borrar datos locales');
      await tester.ensureVisible(clearBtn);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Borrar todo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();

      expect(find.text('Sin ingresos adicionales'), findsOneWidget);
      expect(find.text('Sin movimientos'), findsOneWidget);
    },
  );
}
