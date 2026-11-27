import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_bolsillo/app/app.dart';
import 'package:mi_bolsillo/app/providers.dart';
import 'package:mi_bolsillo/core/routing/app_routes.dart';
import 'package:mi_bolsillo/data/finance_database.dart';
import 'package:mi_bolsillo/data/ledger.dart';
import 'package:mi_bolsillo/data/local_detection.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

class _OfflineBridge extends NotificationBridge {
  @override
  bool get supported => false;
}

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));
  for (final scenario in [
    (TransactionType.expense, AppRoutes.transactions),
    (TransactionType.additionalIncome, AppRoutes.transactions),
    (TransactionType.additionalIncome, AppRoutes.dashboard),
  ]) {
    testWidgets(
      '${scenario.$1} desde ${scenario.$2}: editar futuras mantiene historial y permite detener',
      (tester) async {
        final db = FinanceDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await tester.binding.setSurfaceSize(const Size(412, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final now = DateTime.now();
        final cutoff = DateTime(now.year, now.month, now.day + 1);
        final ledger = Ledger(db);
        await tester.runAsync(() async {
          await ledger.save(
            TransactionItem(
              id: '',
              description: 'Serie de prueba',
              amountCop: 100000,
              type: scenario.$1,
              categoryOrOrigin: scenario.$1 == TransactionType.expense
                  ? 'Compras'
                  : 'Horas extras',
              date: DateTime(now.year, now.month - 1),
              paymentMethod: 'Efectivo',
              isAutomatic: false,
              recurrence: RecurrenceFrequency.monthly,
            ),
          );
          await ledger.generateDue();
        });
        final before = await tester.runAsync(
          () => db.select(db.movements).get(),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              bridgeProvider.overrideWithValue(_OfflineBridge()),
            ],
            child: MiBolsilloApp(initialLocation: scenario.$2),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Editar').first);
        await tester.tap(find.text('Editar').first);
        await tester.pumpAndSettle();
        expect(find.text('Solo este movimiento'), findsOneWidget);
        await tester.tap(find.text('Próximas repeticiones'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            scenario.$1 == TransactionType.expense
                ? 'Próximos gastos'
                : 'Próximos ingresos',
          ),
          findsOneWidget,
        );
        expect(find.text('Primera repetición'), findsOneWidget);
        await tester.enterText(find.byType(TextFormField).first, '150000');
        await tester.ensureVisible(find.text('Guardar próximas repeticiones'));
        await tester.tap(find.text('Guardar próximas repeticiones'));
        await tester.pumpAndSettle();
        final after = (await tester.runAsync(
          () => db.select(db.movements).get(),
        ))!;
        expect(
          after
              .where((m) => m.occurred.isBefore(cutoff))
              .map((m) => '${m.id}:${m.amount}:${m.occurred}'),
          unorderedEquals(
            before!.map((m) => '${m.id}:${m.amount}:${m.occurred}'),
          ),
        );
        expect(
          after.where((m) => !m.occurred.isBefore(cutoff)).single.amount,
          150000,
        );
        expect(tester.takeException(), isNull);
        // Home keeps the same history entry; History shows the planned template.
        await tester.ensureVisible(find.text('Editar').first);
        await tester.tap(find.text('Editar').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Próximas repeticiones'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Detener próximas repeticiones'));
        await tester.tap(find.text('Detener próximas repeticiones'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Detener'));
        await tester.pumpAndSettle();
        final stopped = (await tester.runAsync(
          () => db.select(db.movements).get(),
        ))!;
        expect(stopped, hasLength(before.length));
        expect(stopped.every((m) => m.nextDue == null), isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
