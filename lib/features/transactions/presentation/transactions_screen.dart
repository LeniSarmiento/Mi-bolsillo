import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_bolsillo/core/formatting/cop_formatter.dart';
import 'package:mi_bolsillo/core/formatting/date_formatter.dart';
import 'package:mi_bolsillo/core/formatting/exports.dart';
import 'package:mi_bolsillo/core/routing/app_routes.dart';
import 'package:mi_bolsillo/core/theme/app_colors.dart';
import 'package:mi_bolsillo/core/theme/app_spacing.dart';
import 'package:mi_bolsillo/core/widgets/app_snackbar.dart';
import 'package:mi_bolsillo/core/widgets/confirm_delete_dialog.dart';
import 'package:mi_bolsillo/core/widgets/money_amount_text.dart';
import 'package:mi_bolsillo/core/widgets/state_feedback_views.dart';
import 'package:mi_bolsillo/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:mi_bolsillo/features/income/application/income_controller.dart';
import 'package:mi_bolsillo/features/transactions/application/transactions_controller.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

import 'edit_movement.dart';

enum MovementFilter {
  all('Todos'),
  expenses('Gastos'),
  incomes('Ingresos'),
  additionalIncomes('Ingresos adicionales');

  const MovementFilter(this.label);
  final String label;
}

/// Screen 6: Movimientos — Full ledger with search, 4 filters, grouped dates,
/// badges (Automático/Manual + Recurrencia), edit, and delete confirmation.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  MovementFilter _filter = MovementFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    await Future.wait([
      ref.read(transactionsControllerProvider.notifier).loadTransactions(),
      ref.read(incomeControllerProvider.notifier).loadIncomes(),
    ]);
  }

  List<TransactionItem> _applyFilters(List<TransactionItem> source) {
    final query = _searchController.text.trim().toLowerCase();
    return source.where((tx) {
      final matchesFilter = switch (_filter) {
        MovementFilter.all => true,
        MovementFilter.expenses => tx.type == TransactionType.expense,
        MovementFilter.incomes => tx.type != TransactionType.expense,
        MovementFilter.additionalIncomes =>
          tx.type == TransactionType.additionalIncome,
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return tx.description.toLowerCase().contains(query) ||
          tx.categoryOrOrigin.toLowerCase().contains(query) ||
          tx.paymentMethod.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _editMovement(TransactionItem tx) async {
    await editMovement(context, ref, tx);
  }

  Future<void> _deleteMovement(TransactionItem tx) async {
    if (tx.type == TransactionType.baseIncome) {
      AppSnackbar.showError(
        context,
        'El ingreso base se modifica desde Perfil. Allí puedes cambiar el monto o desactivar su repetición.',
      );
      return;
    }
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: '¿Eliminar movimiento?',
      description:
          'Se eliminará "${tx.description}" (${CopFormatter.formatSigned(tx.amountCop, isPositive: tx.isIncome)}) de tu historial.${tx.recurrence != RecurrenceFrequency.none ? ' También se cancelarán sus próximas repeticiones; las anteriores se conservan.' : ''}',
    );
    if (!confirmed || !mounted) return;

    try {
      if (tx.linkedIncomeId != null) {
        await ref
            .read(incomeControllerProvider.notifier)
            .deleteIncome(tx.linkedIncomeId!);
      } else {
        await ref
            .read(transactionsControllerProvider.notifier)
            .deleteTransaction(tx.id);
      }
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Movimiento eliminado correctamente');
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'No se pudo eliminar el movimiento.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final txState = ref.watch(transactionsControllerProvider);
    final incomeState = ref.watch(incomeControllerProvider);
    final summary = ref.watch(dashboardSummaryProvider);
    final allItems = ref.watch(combinedMovementsProvider);
    final filtered = _applyFilters(allItems);

    final isLoading = txState.isLoading || incomeState.isLoading;
    final isDeleting = txState.isDeleting || incomeState.isDeleting;
    final errorMessage = txState.errorMessage ?? incomeState.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        actions: [
          IconButton(
            tooltip: 'Exportar movimientos a CSV',
            onPressed: filtered.isEmpty
                ? null
                : () => exportLedger(context, filtered),
            icon: const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const LoadingStateView()
            : errorMessage != null && allItems.isEmpty
            ? ErrorStateView(message: errorMessage, onRetry: _reload)
            : SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding(context),
                  AppSpacing.sm,
                  AppSpacing.pagePadding(context),
                  96,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: AppSpacing.maxContentWidth(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (errorMessage != null) ...[
                          InlineErrorBanner(
                            message: errorMessage,
                            onRetry: _reload,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ingresos del mes',
                                        style: theme.textTheme.labelSmall,
                                      ),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          CopFormatter.formatSigned(
                                            summary.totalIncomeCop,
                                            isPositive: true,
                                          ),
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: semantic.income,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Gastos del mes',
                                        style: theme.textTheme.labelSmall,
                                      ),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          CopFormatter.formatSigned(
                                            summary.expensesCop,
                                            isPositive: false,
                                          ),
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: semantic.expense,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText:
                                'Buscar descripción, categoría o medio...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    tooltip: 'Limpiar búsqueda',
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: MovementFilter.values.map((filter) {
                              final selected = _filter == filter;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    filter == MovementFilter.all
                                        ? '${filter.label} (${allItems.length})'
                                        : filter.label,
                                  ),
                                  selected: selected,
                                  onSelected: (_) =>
                                      setState(() => _filter = filter),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (allItems.isEmpty)
                          EmptyStateView(
                            icon: Icons.receipt_long_outlined,
                            title: 'Sin movimientos',
                            description: 'Todavía no tienes gastos ni ingresos registrados.',
                            actionLabel: 'Registrar gasto',
                            onAction: () =>
                                context.push(AppRoutes.registerExpense),
                          )
                        else if (_filter == MovementFilter.additionalIncomes &&
                            filtered.isEmpty &&
                            _searchController.text.trim().isEmpty)
                          EmptyStateView(
                            icon: Icons.savings_outlined,
                            title: 'Sin ingresos adicionales',
                            description: 'No has registrado horas extras ni entradas adicionales.',
                            actionLabel: 'Registrar ingreso adicional',
                            onAction: () =>
                                context.push(AppRoutes.registerIncome),
                          )
                        else if (filtered.isEmpty)
                          EmptyStateView(
                            icon: Icons.search_off_rounded,
                            title: 'Sin resultados',
                            description: 'No encontramos movimientos con los filtros actuales.',
                            actionLabel: 'Limpiar filtros',
                            onAction: () {
                              _searchController.clear();
                              setState(() => _filter = MovementFilter.all);
                            },
                          )
                        else
                          ..._buildGroupedItems(
                            context,
                            filtered,
                            isDeleting: isDeleting,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  List<Widget> _buildGroupedItems(
    BuildContext context,
    List<TransactionItem> items, {
    required bool isDeleting,
  }) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final widgets = <Widget>[];
    String? lastHeader;

    for (final tx in items) {
      final header = DateFormatter.dayGroupHeader(tx.date);
      if (header != lastHeader) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(header, style: theme.textTheme.titleSmall),
          ),
        );
        lastHeader = header;
      }

      final isScheduledFuture = tx.date.isAfter(endOfToday);

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: tx.isIncome
                            ? semantic.incomeContainer
                            : semantic.expenseContainer,
                        child: Icon(
                          tx.isIncome
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          size: 18,
                          color: tx.isIncome
                              ? semantic.income
                              : semantic.expense,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.description,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${tx.categoryOrOrigin} · ${tx.paymentMethod}',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    DateFormatter.shortDateTime(tx.date),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  MoneyAmountText(
                                    amountCop: tx.amountCop,
                                    isIncome: tx.isIncome,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MetaPill(
                        icon: tx.isAutomatic
                            ? Icons.bolt_rounded
                            : Icons.edit_note_rounded,
                        label: tx.source == MovementSource.recurring
                            ? 'Recurrente'
                            : tx.isAutomatic
                            ? 'Automático'
                            : 'Manual',
                      ),
                      _MetaPill(
                        icon: Icons.repeat_rounded,
                        label: tx.parentId != null
                            ? 'Parte de una serie'
                            : tx.recurrence == RecurrenceFrequency.none
                            ? 'Único'
                            : tx.recurrence.label,
                      ),
                      if (tx.type == TransactionType.additionalIncome)
                        const _MetaPill(
                          icon: Icons.add_chart_rounded,
                          label: 'Ingreso adicional',
                        ),
                      if (isScheduledFuture)
                        const _MetaPill(
                          icon: Icons.schedule_rounded,
                          label: 'Programado',
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 4,
                      children: [
                        TextButton.icon(
                          onPressed: isDeleting
                              ? null
                              : () => _editMovement(tx),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Editar'),
                        ),
                        TextButton.icon(
                          onPressed: isDeleting
                              ? null
                              : () => _deleteMovement(tx),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: semantic.expense,
                          ),
                          label: Text(
                            'Eliminar',
                            style: TextStyle(color: semantic.expense),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
