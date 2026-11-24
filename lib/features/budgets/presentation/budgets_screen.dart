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
import 'package:mi_bolsillo/core/widgets/state_feedback_views.dart';
import 'package:mi_bolsillo/features/budgets/application/budgets_controller.dart';
import 'package:mi_bolsillo/features/budgets/domain/budget_item.dart';

/// Screen 10: Presupuestos por categoría con alertas al 80% y estado agotado.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final budgetsState = ref.watch(budgetsControllerProvider);
    final progressList = ref.watch(budgetProgressListProvider);

    final monthly = progressList.where(
      (p) => p.budget.period == BudgetPeriod.monthly,
    );
    final totalLimit = monthly.fold<int>(
      0,
      (sum, item) => sum + item.budget.limitCop,
    );
    final totalSpent = monthly.fold<int>(0, (sum, item) => sum + item.spentCop);
    final totalRemaining = totalLimit - totalSpent;
    final totalPercent = totalLimit <= 0
        ? 0
        : ((totalSpent * 100) / totalLimit).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Presupuestos')),
      body: SafeArea(
        child: budgetsState.isLoading
            ? const LoadingStateView()
            : budgetsState.errorMessage != null && progressList.isEmpty
            ? ErrorStateView(
                message: budgetsState.errorMessage!,
                onRetry: () =>
                    ref.read(budgetsControllerProvider.notifier).loadBudgets(),
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
                        if (budgetsState.errorMessage != null) ...[
                          InlineErrorBanner(
                            message: budgetsState.errorMessage!,
                            onRetry: () => ref
                                .read(budgetsControllerProvider.notifier)
                                .loadBudgets(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                DateFormatter.monthYear(DateTime.now()),
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            BudgetStatusBadge(
                              level: totalSpent >= totalLimit && totalLimit > 0
                                  ? BudgetAlertLevel.exhausted
                                  : totalPercent >= 80
                                  ? BudgetAlertLevel.warning80
                                  : BudgetAlertLevel.healthy,
                              percentUsed: totalPercent,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [semantic.heroStart, semantic.heroEnd],
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusXl,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Presupuesto Mensual Consolidado',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${CopFormatter.format(totalSpent)} / ${CopFormatter.format(totalLimit)}',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusPill,
                                ),
                                child: LinearProgressIndicator(
                                  value: totalLimit <= 0
                                      ? 0
                                      : (totalSpent / totalLimit).clamp(0, 1),
                                  minHeight: 8,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.25,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppColors.secondarySoft,
                                      ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                totalRemaining >= 0
                                    ? 'Disponible en presupuestos: ${CopFormatter.format(totalRemaining)}'
                                    : 'Excedido por ${CopFormatter.format(totalRemaining.abs())}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          onPressed: () => context.push(AppRoutes.createBudget),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Crear nuevo presupuesto'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Presupuestos por categoría',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (progressList.isEmpty)
                          EmptyStateView(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Sin presupuestos configurados',
                            description: 'Define límites mensuales por categoría para recibir alertas al 80%.',
                            actionLabel: 'Crear presupuesto',
                            onAction: () =>
                                context.push(AppRoutes.createBudget),
                          )
                        else
                          ...progressList.map(
                            (progress) => _BudgetCategoryCard(
                              progress: progress,
                              isDeleting: budgetsState.isDeleting,
                              onDelete: () async {
                                final ok = await ConfirmDeleteDialog.show(
                                  context,
                                  title: '¿Eliminar presupuesto?',
                                  description:
                                      'Se eliminará el límite para "${progress.budget.category}".',
                                );
                                if (!ok || !context.mounted) return;
                                try {
                                  await ref
                                      .read(budgetsControllerProvider.notifier)
                                      .deleteBudget(progress.budget.id);
                                  if (!context.mounted) return;
                                  AppSnackbar.showSuccess(
                                    context,
                                    'Presupuesto eliminado correctamente',
                                  );
                                } catch (_) {
                                  if (!context.mounted) return;
                                  AppSnackbar.showError(
                                    context,
                                    'No se pudo eliminar el presupuesto.',
                                  );
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _BudgetCategoryCard extends StatelessWidget {
  const _BudgetCategoryCard({
    required this.progress,
    required this.isDeleting,
    required this.onDelete,
  });

  final BudgetProgress progress;
  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final barColor = switch (progress.alertLevel) {
      BudgetAlertLevel.healthy => semantic.income,
      BudgetAlertLevel.warning80 => AppColors.warning,
      BudgetAlertLevel.exhausted => semantic.expense,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          progress.budget.category,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          progress.budget.period.label,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    BudgetStatusBadge(
                      level: progress.alertLevel,
                      percentUsed: progress.percentUsed,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                child: LinearProgressIndicator(
                  value: progress.budget.limitCop <= 0
                      ? 0
                      : (progress.spentCop / progress.budget.limitCop).clamp(
                          0,
                          1,
                        ),
                  minHeight: 8,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      progress.remainingCop >= 0
                          ? 'Gastado ${CopFormatter.format(progress.spentCop)} · Restan ${CopFormatter.format(progress.remainingCop)}'
                          : 'Gastado ${CopFormatter.format(progress.spentCop)} · Excedido por ${CopFormatter.format(progress.remainingCop.abs())}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: progress.remainingCop < 0
                            ? semantic.expense
                            : null,
                        fontWeight: progress.remainingCop < 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: isDeleting
                        ? null
                        : () => context.push(
                            AppRoutes.createBudget,
                            extra: progress.budget,
                          ),
                    tooltip: 'Editar presupuesto',
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Eliminar presupuesto',
                    onPressed: isDeleting ? null : onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: semantic.expense,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
