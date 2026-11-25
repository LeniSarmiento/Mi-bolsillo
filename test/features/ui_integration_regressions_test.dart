import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_bolsillo/app/app.dart';
import 'package:mi_bolsillo/app/providers.dart';
import 'package:mi_bolsillo/core/notifications/app_notifications.dart';
import 'package:mi_bolsillo/core/routing/app_routes.dart';
import 'package:mi_bolsillo/data/finance_database.dart';
import 'package:mi_bolsillo/data/local_detection.dart';
import 'package:mi_bolsillo/features/automatic_detection/data/mock_automatic_detection_repository.dart';
import 'package:mi_bolsillo/features/budgets/data/mock_budget_repository.dart';
import 'package:mi_bolsillo/features/income/data/mock_income_repository.dart';
import 'package:mi_bolsillo/features/income/domain/additional_income.dart';
import 'package:mi_bolsillo/features/profile/data/mock_settings_repository.dart';
import 'package:mi_bolsillo/features/transactions/data/mock_transaction_repository.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

import '../support/finance_fixture.dart';

class _FlakyTransactionRepository extends MockTransactionRepository {
  bool shouldFailLoad = true;

  @override
  Future<List<TransactionItem>> getTransactions() async {
    if (shouldFailLoad) {
      throw StateError('Error simulado de lectura');
    }
    return super.getTransactions();
  }
}

class _SlowIncomeRepository extends MockIncomeRepository {
  final Completer<void> saveGate = Completer<void>();

  @override
  Future<AdditionalIncome> addAdditionalIncome(AdditionalIncome income) async {
    await saveGate.future;
    return super.addAdditionalIncome(income);
  }
}

class _DeniedNotifications implements AppNotifications {
  @override
  bool get supported => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> showBudgetAlert({
    required int id,
    required String category,
    required int percentUsed,
    required bool exhausted,
  }) async => false;

  @override
  Future<bool> syncDailyReminder(bool enabled) async => false;
}

class _UnsupportedBridge extends NotificationBridge {
  @override
  bool get supported => false;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  testWidgets(
    'Key screens render without overflow at 320, 360, 412, 600, and 1024 px',
    (tester) async {
      const widths = [320.0, 360.0, 412.0, 600.0, 1024.0];
      const routes = [
        AppRoutes.dashboard,
        AppRoutes.transactions,
        AppRoutes.analysis,
        AppRoutes.budgets,
      ];

      for (final width in widths) {
        for (final route in routes) {
          await tester.binding.setSurfaceSize(Size(width, 800));
          final database = await pumpFinance(tester, route);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          await database.close();
        }
      }
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'Dashboard shows ErrorStateView and recovers when tapping Reintentar',
    (tester) async {
      final repo = _FlakyTransactionRepository();
      final emptyIncomeRepo = MockIncomeRepository();
      await emptyIncomeRepo.clearAll();
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(repo),
            incomeRepositoryProvider.overrideWithValue(emptyIncomeRepo),
            budgetRepositoryProvider.overrideWithValue(MockBudgetRepository()),
            settingsRepositoryProvider.overrideWithValue(
              MockSettingsRepository(),
            ),
            automaticDetectionRepositoryProvider.overrideWithValue(
              MockAutomaticDetectionRepository(),
            ),
            bridgeProvider.overrideWithValue(_UnsupportedBridge()),
          ],
          child: const MiBolsilloApp(initialLocation: AppRoutes.dashboard),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No pudimos cargar tu información'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);

      repo.shouldFailLoad = false;
      await emptyIncomeRepo.resetToMockDefaults();
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Disponible este mes'), findsWidgets);
      expect(find.text('\$1.930.000 COP'), findsWidgets);
    },
  );

  testWidgets(
    'RegisterIncome disables submit button while saving to prevent double submit',
    (tester) async {
      final slowIncomeRepo = _SlowIncomeRepository();
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(
              MockTransactionRepository(),
            ),
            incomeRepositoryProvider.overrideWithValue(slowIncomeRepo),
            budgetRepositoryProvider.overrideWithValue(MockBudgetRepository()),
            settingsRepositoryProvider.overrideWithValue(
              MockSettingsRepository(),
            ),
            automaticDetectionRepositoryProvider.overrideWithValue(
              MockAutomaticDetectionRepository(),
            ),
            bridgeProvider.overrideWithValue(_UnsupportedBridge()),
          ],
          child: const MiBolsilloApp(initialLocation: AppRoutes.registerIncome),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), '150000');
      await tester.enterText(find.byType(TextFormField).at(1), 'Tutoría');
      await tester.ensureVisible(find.text('Guardar ingreso'));
      await tester.tap(find.text('Guardar ingreso'));
      await tester.pump();

      expect(find.text('Guardando...'), findsOneWidget);
      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Guardando...'),
      );
      expect(saveButton.onPressed, isNull);

      slowIncomeRepo.saveGate.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Profile shows snackbar when notification permission is denied', (
    tester,
  ) async {
    final db = FinanceDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          bridgeProvider.overrideWithValue(_UnsupportedBridge()),
          appNotificationsProvider.overrideWithValue(_DeniedNotifications()),
        ],
        child: const MiBolsilloApp(initialLocation: AppRoutes.profile),
      ),
    );
    await tester.pumpAndSettle();

    final reminderSwitch = find.widgetWithText(
      SwitchListTile,
      'Recordatorio diario 8:00 PM',
    );
    await tester.ensureVisible(reminderSwitch);
    await tester.tap(reminderSwitch);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Activa el permiso de notificaciones en tu dispositivo para usar el recordatorio.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'AutoDetection shows Android-only guidance when unsupported and edits pending item',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpFinance(tester, AppRoutes.autoDetection);

      expect(
        find.textContaining('disponible únicamente en Android'),
        findsWidgets,
      );

      await tester.tap(find.textContaining('Movimientos pendientes'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Editar').first);
      await tester.tap(find.text('Editar').first);
      await tester.pumpAndSettle();

      expect(find.text('Editar movimiento pendiente'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Comercio'),
        'Éxito Poblado',
      );
      await tester.ensureVisible(find.text('Guardar cambios'));
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(find.text('Éxito Poblado'), findsOneWidget);
    },
  );

  testWidgets('Budgets screen opens Edit Budget flow and updates title', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpFinance(tester, AppRoutes.budgets);

    await tester.ensureVisible(find.byTooltip('Editar presupuesto').first);
    await tester.tap(find.byTooltip('Editar presupuesto').first);
    await tester.pumpAndSettle();

    expect(find.text('Editar presupuesto'), findsOneWidget);
    await tester.ensureVisible(find.text('Guardar presupuesto'));
    await tester.tap(find.text('Guardar presupuesto'));
    await tester.pumpAndSettle();

    expect(find.text('Presupuestos'), findsOneWidget);
  });
}
