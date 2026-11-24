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
    var merchant = movement.merchant;
    var amount = movement.amountCop;
    var category =
        ExpenseCategory.values.any((c) => c.label == movement.suggestedCategory)
        ? movement.suggestedCategory
        : ExpenseCategory.other.label;
    final key = GlobalKey<FormState>();

    final updated = await showModalBottomSheet<PendingMovement>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.viewInsetsOf(sheet).bottom + 16,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Editar movimiento pendiente',
                    style: Theme.of(sheet).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    initialValue: merchant,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Comercio'),
                    onChanged: (s) => merchant = s.trim(),
                    validator: (_) =>
                        merchant.isEmpty ? 'Ingresa el comercio' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    initialValue: CopFormatter.formatDigits(amount),
                    decoration: const InputDecoration(
                      labelText: 'Monto en COP',
                      prefixText: '\$ ',
                      suffixText: 'COP',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CopFormatter.inputFormatter],
                    onChanged: (s) => amount = CopFormatter.parseDigits(s) ?? 0,
                    validator: (_) =>
                        amount <= 0 ? 'Ingresa un monto válido' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: ExpenseCategory.values
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.label,
                            child: Text(c.label),
                          ),
                        )
                        .toList(),
                    onChanged: (s) => category = s ?? category,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () {
                      if (key.currentState!.validate()) {
                        Navigator.pop(
                          sheet,
                          movement.copyWith(
                            merchant: merchant,
                            amountCop: amount,
                            suggestedCategory: category,
                          ),
                        );
                      }
                    },
                    child: const Text('Guardar cambios'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (updated == null || !context.mounted) return;
    try {
      await ref
          .read(automaticDetectionControllerProvider.notifier)
          .editPending(updated);
      if (context.mounted) {
        AppSnackbar.showSuccess(context, 'Movimiento pendiente actualizado');
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.showError(
          context,
          'No se pudo actualizar el movimiento pendiente',
        );
      }
    }
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
            : state.errorMessage != null && state.pending.isEmpty
            ? ErrorStateView(
                message: state.errorMessage!,
                onRetry: () => ref
                    .read(automaticDetectionControllerProvider.notifier)
                    .load(),
              )
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
                        if (state.errorMessage != null) ...[
                          InlineErrorBanner(
                            message: state.errorMessage!,
                            onRetry: () => ref
                                .read(
                                  automaticDetectionControllerProvider.notifier,
                                )
                                .load(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
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
                                    onPressed: state.isSaving
                                        ? null
                                        : () async {
                                            final count = state.pending.length;
                                            try {
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
                                            } catch (_) {
                                              if (!context.mounted) return;
                                              AppSnackbar.showError(
                                                context,
                                                'No se pudieron confirmar todos los movimientos',
                                              );
                                            }
                                          },
                                    icon: state.isSaving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.done_all_rounded),
                                    label: Text(
                                      state.isSaving
                                          ? 'Procesando...'
                                          : 'Confirmar todos (${state.pending.length})',
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
                                          const SizedBox(width: AppSpacing.xs),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 120,
                                            ),
                                            child: MoneyAmountText(
                                              amountCop: item.amountCop,
                                              isIncome: false,
                                              showCurrency: false,
                                            ),
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
                                          'Categoría: ${item.suggestedCategory}',
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          FilledButton.icon(
                                            onPressed: state.isSaving
                                                ? null
                                                : () async {
                                                    try {
                                                      await ref
                                                          .read(
                                                            automaticDetectionControllerProvider
                                                                .notifier,
                                                          )
                                                          .confirmOne(item);
                                                      if (!context.mounted) {
                                                        return;
                                                      }
                                                      AppSnackbar.showSuccess(
                                                        context,
                                                        '"${item.merchant}" agregado a tus movimientos',
                                                      );
                                                    } catch (_) {
                                                      if (!context.mounted) {
                                                        return;
                                                      }
                                                      AppSnackbar.showError(
                                                        context,
                                                        'No se pudo confirmar "${item.merchant}"',
                                                      );
                                                    }
                                                  },
                                            icon: const Icon(
                                              Icons.check_rounded,
                                              size: 18,
                                            ),
                                            label: const Text('Confirmar'),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: state.isSaving
                                                ? null
                                                : () => _changeCategory(
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
                                            onPressed: state.isSaving
                                                ? null
                                                : () async {
                                                    final ok =
                                                        await ConfirmDeleteDialog.show(
                                                          context,
                                                          title: '¿Descartar movimiento?',
                                                          description:
                                                              'Se descartará la notificación de "${item.merchant}" (${CopFormatter.format(item.amountCop)}).',
                                                          confirmLabel:
                                                              'Descartar',
                                                        );
                                                    if (!ok ||
                                                        !context.mounted) {
                                                      return;
                                                    }
                                                    try {
                                                      await ref
                                                          .read(
                                                            automaticDetectionControllerProvider
                                                                .notifier,
                                                          )
                                                          .discardOne(item.id);
                                                      if (!context.mounted) {
                                                        return;
                                                      }
                                                      AppSnackbar.showSuccess(
                                                        context,
                                                        'Movimiento pendiente descartado',
                                                      );
                                                    } catch (_) {
                                                      if (!context.mounted) {
                                                        return;
                                                      }
                                                      AppSnackbar.showError(
                                                        context,
                                                        'No se pudo descartar el movimiento',
                                                      );
                                                    }
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
