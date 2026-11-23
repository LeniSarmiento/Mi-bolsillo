import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_bolsillo/core/formatting/cop_formatter.dart';
import 'package:mi_bolsillo/core/formatting/date_formatter.dart';
import 'package:mi_bolsillo/core/routing/app_routes.dart';
import 'package:mi_bolsillo/core/theme/app_colors.dart';
import 'package:mi_bolsillo/core/theme/app_spacing.dart';
import 'package:mi_bolsillo/core/widgets/app_snackbar.dart';
import 'package:mi_bolsillo/core/widgets/confirm_delete_dialog.dart';
import 'package:mi_bolsillo/core/widgets/money_amount_text.dart';
import 'package:mi_bolsillo/core/widgets/state_feedback_views.dart';
import 'package:mi_bolsillo/features/automatic_detection/application/automatic_detection_controller.dart';
import 'package:mi_bolsillo/features/automatic_detection/domain/pending_movement.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

/// Screen 9: Movimientos pendientes detectados para confirmar, editar o descartar.
class PendingMovementsScreen extends ConsumerWidget {
  const PendingMovementsScreen({super.key});

  Future<void> _changeCategory(
    BuildContext context,
    WidgetRef ref,
    PendingMovement movement,
  ) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Confirmar categoría para ${movement.merchant}',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: ExpenseCategory.values.map((cat) {
                    return ActionChip(
                      avatar: Icon(cat.icon, size: 18),
                      label: Text(cat.label),
                      onPressed: () =>
                          Navigator.of(sheetContext).pop(cat.label),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked == null || !context.mounted) return;
    await ref
        .read(automaticDetectionControllerProvider.notifier)
        .confirmOne(movement, category: picked);
    if (!context.mounted) return;
    AppSnackbar.showSuccess(
      context,
      'Movimiento "${movement.merchant}" confirmado en $picked',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final state = ref.watch(automaticDetectionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos pendientes')),
      body: SafeArea(
        child: state.isLoading
            ? const LoadingStateView()
            : SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.pagePadding(context)),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: AppSpacing.maxContentWidth(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.pending.isEmpty)
                          EmptyStateView(
                            icon: Icons.task_alt_rounded,
                            title: 'No tienes movimientos pendientes',
                            description: 'Todos los avisos detectados ya fueron revisados.',
                            actionLabel: 'Ir al inicio',
                            onAction: () => context.go(AppRoutes.dashboard),
                          )
                        else ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${state.pending.length} nuevos por revisar',
                                          style: theme.textTheme.titleMedium,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      MoneyAmountText(
                                        amountCop: state.totalPendingCop,
                                        isIncome: false,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  FilledButton.icon(
                                    onPressed: () async {
                                      final count = state.pending.length;
                                      await ref
                                          .read(
                                            automaticDetectionControllerProvider
                                                .notifier,
                                          )
                                          .confirmAll();
                                      if (!context.mounted) return;
                                      AppSnackbar.showSuccess(
                                        context,
                                        '$count movimientos confirmados correctamente',
                                      );
                                    },
                                    icon: const Icon(Icons.done_all_rounded),
                                    label: Text(
                                      'Confirmar todos (${state.pending.length})',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ...state.pending.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            backgroundColor:
                                                semantic.incomeContainer,
                                            child: Icon(
                                              Icons.bolt_rounded,
                                              color: semantic.income,
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.merchant,
                                                  style: theme
                                                      .textTheme
                                                      .titleMedium,
                                                ),
                                                Text(
                                                  '${item.sourceApp} · ${DateFormatter.shortDateTime(item.detectedAt)}',
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                              ],
                                            ),
                                          ),
                                          MoneyAmountText(
                                            amountCop: item.amountCop,
                                            isIncome: false,
                                            showCurrency: false,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(
                                          AppSpacing.xs,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusSm,
                                          ),
                                        ),
                                        child: Text(
                                          item.notificationPreview,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Chip(
                                        avatar: const Icon(
                                          Icons.auto_awesome_rounded,
                                          size: 16,
                                        ),
                                        label: Text(
                                          'Sugerido: ${item.suggestedCategory} (${item.confidencePercent}%)',
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          FilledButton.icon(
                                            onPressed: () async {
                                              await ref
                                                  .read(
                                                    automaticDetectionControllerProvider
                                                        .notifier,
                                                  )
                                                  .confirmOne(item);
                                              if (!context.mounted) return;
                                              AppSnackbar.showSuccess(
                                                context,
                                                '"${item.merchant}" agregado a tus movimientos',
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.check_rounded,
                                              size: 18,
                                            ),
                                            label: const Text('Confirmar'),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () => _changeCategory(
                                              context,
                                              ref,
                                              item,
                                            ),
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 18,
                                            ),
                                            label: const Text('Editar'),
                                          ),
                                          TextButton.icon(
                                            onPressed: () async {
                                              final ok =
                                                  await ConfirmDeleteDialog.show(
                                                    context,
                                                    title: '¿Descartar movimiento?',
                                                    description:
                                                        'Se descartará la notificación de "${item.merchant}" (${CopFormatter.format(item.amountCop)}).',
                                                    confirmLabel: 'Descartar',
                                                  );
                                              if (!ok || !context.mounted) {
                                                return;
                                              }
                                              await ref
                                                  .read(
                                                    automaticDetectionControllerProvider
                                                        .notifier,
                                                  )
                                                  .discardOne(item.id);
                                              if (!context.mounted) return;
                                              AppSnackbar.showSuccess(
                                                context,
                                                'Movimiento pendiente descartado',
                                              );
                                            },
                                            icon: Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: semantic.expense,
                                            ),
                                            label: Text(
                                              'Descartar',
                                              style: TextStyle(
                                                color: semantic.expense,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
