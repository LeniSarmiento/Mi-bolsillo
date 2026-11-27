import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../income/application/income_controller.dart';
import '../application/transactions_controller.dart';
import '../domain/transaction_item.dart';
import '../domain/recurrence_repository.dart';

/// Shared by History and Home so both entry points offer the same edit scope.
Future<void> editMovement(
  BuildContext context,
  WidgetRef ref,
  TransactionItem item,
) async {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  if (item.type == TransactionType.baseIncome) {
    final today = DateTime.now();
    if (item.date.year != today.year || item.date.month != today.month) {
      AppSnackbar.showError(
        context,
        'El ingreso base de este mes ya está cerrado',
      );
      return;
    }
    await context.push(AppRoutes.onboardingIncome);
    return;
  }
  final template = item.parentId == null
      ? item
      : ref
            .read(combinedMovementsProvider)
            .where((m) => (m.linkedIncomeId ?? m.id) == item.parentId)
            .firstOrNull;
  final active =
      template != null && template.recurrence != RecurrenceFrequency.none;
  var futureOnly = false;
  if (active) {
    final scope = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar movimiento recurrente'),
        content: const Text(
          'Edita solo este movimiento o programa los próximos desde una fecha futura. Los demás registros del historial conservarán su monto y fecha.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Solo este movimiento'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Próximas repeticiones'),
          ),
        ],
      ),
    );
    if (scope == null || !context.mounted) return;
    futureOnly = scope;
    if (futureOnly) item = template;
  }
  final today = DateTime.now();
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  final firstFuture = !item.date.isBefore(tomorrow)
      ? item.date
      : item.nextOccurrence ?? tomorrow;
  if (item.linkedIncomeId != null) {
    final income = ref
        .read(incomeControllerProvider)
        .items
        .where((i) => i.id == item.linkedIncomeId)
        .firstOrNull;
    if (income == null) return;
    await context.push(
      AppRoutes.registerIncome,
      extra: futureOnly
          ? FutureSeriesEdit(income.copyWith(date: firstFuture))
          : income,
    );
  } else {
    await context.push(
      AppRoutes.registerExpense,
      extra: futureOnly
          ? FutureSeriesEdit(item.copyWith(date: firstFuture))
          : item,
    );
  }
}
