import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_bolsillo/app/app.dart';
import 'package:mi_bolsillo/core/routing/app_routes.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  String initialLocation = AppRoutes.welcome,
}) async {
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(child: MiBolsilloApp(initialLocation: initialLocation)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  testWidgets('Onboarding flow navigates from Welcome to Income to Dashboard', (
    tester,
  ) async {
    await _pumpApp(tester, initialLocation: AppRoutes.welcome);

    expect(find.text('Toma el control de tu dinero'), findsOneWidget);
    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();

    expect(find.text('Configuración Inicial'), findsOneWidget);
    expect(
      find.text('¿Cuánto dinero recibes normalmente al mes?'),
      findsOneWidget,
    );

    // Clear amount to verify form error state.
    await tester.tap(find.byTooltip('Limpiar monto'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Crear mi presupuesto'));
    await tester.tap(find.text('Crear mi presupuesto'));
    await tester.pumpAndSettle();
    expect(
      find.text('Ingresa un ingreso mensual válido en pesos colombianos.'),
      findsOneWidget,
    );

    // Enter valid base income and submit.
    await tester.enterText(find.byType(TextFormField).first, '2400000');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Crear mi presupuesto'));
    await tester.tap(find.text('Crear mi presupuesto'));
    await tester.pumpAndSettle();

    expect(find.text('Disponible este mes'), findsWidgets);
    expect(find.text('\$1.930.000 COP'), findsWidgets);
  });

  testWidgets(
    'Dashboard shows separated totals, Entradas de dinero, and negative balance state',
    (tester) async {
      await _pumpApp(tester, initialLocation: AppRoutes.dashboard);

      expect(find.text('Ingreso mensual'), findsOneWidget);
      expect(find.text('\$2.400.000 COP'), findsOneWidget);
      expect(find.text('Ingresos adicionales'), findsOneWidget);
      expect(find.text('+\$480.000 COP'), findsWidgets);
      expect(find.text('Gastos'), findsOneWidget);
      expect(find.text('-\$950.000 COP'), findsOneWidget);
      expect(find.text('\$1.930.000 COP'), findsWidgets);

      expect(find.text('Entradas de dinero'), findsOneWidget);
      expect(find.text('Horas extras'), findsWidgets);
      expect(find.text('Trabajo independiente'), findsWidgets);

      // Register a large expense to verify Negative Balance state.
      await tester.ensureVisible(find.text('Registrar gasto'));
      await tester.tap(find.text('Registrar gasto'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), '2500000');
      await tester.enterText(find.byType(TextFormField).at(1), 'Compra equipo');
      await tester.ensureVisible(find.text('Guardar gasto'));
      await tester.tap(find.text('Guardar gasto'));
      await tester.pumpAndSettle();

      expect(find.text('Saldo negativo este mes'), findsOneWidget);
    },
  );

  testWidgets('Profile screen toggles dark mode', (tester) async {
    await _pumpApp(tester, initialLocation: AppRoutes.profile);

    final switchFinder = find.widgetWithText(SwitchListTile, 'Modo oscuro');
    expect(switchFinder, findsOneWidget);
    await tester.ensureVisible(switchFinder);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.dark);
  });
}
