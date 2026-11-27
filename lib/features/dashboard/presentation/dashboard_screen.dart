import 'package:material_ui/material_ui.dart';

import '../../transactions/domain/transaction_item.dart';
import '../../transactions/presentation/edit_movement.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_bolsillo/app/providers.dart';
import 'package:mi_bolsillo/core/formatting/cop_formatter.dart';
import 'package:mi_bolsillo/core/formatting/date_formatter.dart';
import 'package:mi_bolsillo/core/routing/app_routes.dart';
import 'package:mi_bolsillo/core/theme/app_colors.dart';
import 'package:mi_bolsillo/core/theme/app_spacing.dart';
import 'package:mi_bolsillo/core/widgets/app_snackbar.dart';
import 'package:mi_bolsillo/core/widgets/confirm_delete_dialog.dart';
import 'package:mi_bolsillo/core/widgets/mi_bolsillo_logo.dart';
import 'package:mi_bolsillo/core/widgets/money_amount_text.dart';
import 'package:mi_bolsillo/core/widgets/state_feedback_views.dart';
import 'package:mi_bolsillo/features/automatic_detection/application/automatic_detection_controller.dart';
import 'package:mi_bolsillo/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:mi_bolsillo/features/income/application/income_controller.dart';
import 'package:mi_bolsillo/features/profile/application/settings_controller.dart';
import 'package:mi_bolsillo/features/transactions/application/transactions_controller.dart';

/// Screen 3: Dashboard principal — Disponible = Ingreso mensual + Adicionales - Gastos.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _reload(WidgetRef ref) async {
    await Future.wait([
      ref.read(transactionsControllerProvider.notifier).loadTransactions(),
      ref.read(incomeControllerProvider.notifier).loadIncomes(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final settings = ref.watch(settingsControllerProvider);
    final summary = ref.watch(dashboardSummaryProvider);
    final incomeState = ref.watch(incomeControllerProvider);
    final txState = ref.watch(transactionsControllerProvider);
    final combined = ref.watch(combinedMovementsProvider);
    final pendingCount = ref.watch(
      automaticDetectionControllerProvider.select((s) => s.pending.length),
    );
    final bridgeSupported = ref.watch(bridgeProvider).supported;

    final isInitialLoading = txState.isLoading || incomeState.isLoading;
    final errorMessage = txState.errorMessage ?? incomeState.errorMessage;
    final recentMovements = combined.take(4).toList();
    final now = DateTime.now();
    final remainingDays =
        DateTime(now.year, now.month + 1, 0).day - now.day + 1;
    final currentIncomes = incomeState.items.where(
      (i) =>
          i.date.year == now.year &&
          i.date.month == now.month &&
          i.date.day <= now.day,
    );
    final dailyPaceCop = summary.availableCop > 0
        ? summary.availableCop ~/ remainingDays
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const MiBolsilloLogo(
          variant: MiBolsilloLogoVariant.horizontal,
          height: 32,
        ),
        actions: [
          IconButton(
            tooltip: 'Movimientos pendientes ($pendingCount)',
            onPressed: () => context.push(AppRoutes.pendingMovements),
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Perfil y configuración',
              onPressed: () => context.go(AppRoutes.profile),
              icon: CircleAvatar(
                radius: 17,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  settings.firstName.isEmpty
                      ? 'C'
                      : settings.firstName[0].toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isInitialLoading
            ? const LoadingStateView()
            : errorMessage != null && combined.isEmpty
            ? ErrorStateView(message: errorMessage, onRetry: () => _reload(ref))
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding(context),
                  AppSpacing.md,
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
                            onRetry: () => _reload(ref),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        _GreetingHeader(
                          firstName: settings.firstName,
                          hideBalances: settings.hideBalances,
                          isNegative: summary.isNegative,
                          dailyPaceCop: dailyPaceCop,
                          remainingDays: remainingDays,
                        ),
                        if (settings.autoDetectionBannerVisible) ...[
                          const SizedBox(height: AppSpacing.md),
                          _AutoDetectionBanner(
                            pendingCount: pendingCount,
                            bridgeSupported: bridgeSupported,
                            onActivate: () =>
                                context.push(AppRoutes.autoDetection),
                            onDismiss: () => ref
                                .read(settingsControllerProvider.notifier)
                                .dismissAutoDetectionBanner(),
                          ),
                        ],
                        if (summary.isNegative && !settings.hideBalances) ...[
                          const SizedBox(height: AppSpacing.md),
                          NegativeBalanceBanner(
                            deficitCopText: CopFormatter.format(
                              summary.availableCop.abs(),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        _HeroBalanceCard(
                          summary: summary,
                          hideBalances: settings.hideBalances,
                          onToggleHide: () => ref
                              .read(settingsControllerProvider.notifier)
                              .toggleHideBalances(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _SeparateSummaryGrid(
                          summary: summary,
                          hideBalances: settings.hideBalances,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Acciones rápidas',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _QuickActionsGrid(
                          onExpense: () =>
                              context.push(AppRoutes.registerExpense),
                          onIncome: () =>
                              context.push(AppRoutes.registerIncome),
                          onAnalysis: () => context.go(AppRoutes.analysis),
                          onBudgets: () => context.push(AppRoutes.budgets),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Entradas de dinero',
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  context.push(AppRoutes.registerIncome),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Agregar'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (currentIncomes.isEmpty)
                          EmptyStateView(
                            icon: Icons.savings_outlined,
                            title: 'Sin ingresos adicionales',
                            description: 'Aún no has registrado horas extras, ventas o trabajos independientes este mes.',
                            actionLabel: 'Registrar ingreso adicional',
                            onAction: () =>
                                context.push(AppRoutes.registerIncome),
                          )
                        else
                          ...currentIncomes.map(
                            (income) => Padding(
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
                                        children: [
                                          CircleAvatar(
                                            backgroundColor:
                                                semantic.incomeContainer,
                                            child: Icon(
                                              Icons.trending_up_rounded,
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
                                                  income.reason,
                                                  style: theme
                                                      .textTheme
                                                      .titleMedium,
                                                ),
                                                Text(
                                                  '${income.origin} · ${income.receptionMethod} · ${income.recurrence.label}',
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          Flexible(
                                            child: MoneyAmountText(
                                              hidden: settings.hideBalances,
                                              amountCop: income.amountCop,
                                              isIncome: true,
                                              showCurrency: false,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Wrap(
                                          spacing: 4,
                                          children: [
                                            TextButton.icon(
                                              onPressed: incomeState.isDeleting
                                                  ? null
                                                  : () => editMovement(
                                                      context,
                                                      ref,
                                                      combined.firstWhere(
                                                        (m) =>
                                                            m.linkedIncomeId ==
                                                            income.id,
                                                      ),
                                                    ),
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 18,
                                              ),
                                              label: const Text('Editar'),
                                            ),
                                            TextButton.icon(
                                              onPressed: incomeState.isDeleting
                                                  ? null
                                                  : () async {
                                                      final confirmed =
                                                          await ConfirmDeleteDialog.show(
                                                            context,
                                                            title: '¿Eliminar ingreso adicional?',
                                                            description:
                                                                'Se eliminará "${income.reason}" de tus entradas confirmadas.${income.recurrence != RecurrenceFrequency.none ? ' También se cancelarán las próximas repeticiones; las anteriores se conservan.' : ''}',
                                                          );
                                                      if (!confirmed ||
                                                          !context.mounted) {
                                                        return;
                                                      }
                                                      try {
                                                        await ref
                                                            .read(
                                                              incomeControllerProvider
                                                                  .notifier,
                                                            )
                                                            .deleteIncome(
                                                              income.id,
                                                            );
                                                        if (!context.mounted) {
                                                          return;
                                                        }
                                                        AppSnackbar.showSuccess(
                                                          context,
                                                          'Ingreso adicional eliminado correctamente',
                                                        );
                                                      } catch (_) {
                                                        if (!context.mounted) {
                                                          return;
                                                        }
                                                        AppSnackbar.showError(
                                                          context,
                                                          'No se pudo eliminar el ingreso adicional.',
                                                        );
                                                      }
                                                    },
                                              icon: Icon(
                                                Icons.delete_outline_rounded,
                                                size: 18,
                                                color: semantic.expense,
                                              ),
                                              label: Text(
                                                'Eliminar',
                                                style: TextStyle(
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
                            ),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Movimientos recientes',
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.go(AppRoutes.transactions),
                              child: Text('Ver todos (${combined.length})'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (recentMovements.isEmpty)
                          EmptyStateView(
                            icon: Icons.receipt_long_outlined,
                            title: 'Sin movimientos',
                            description: 'Registra tu primer gasto o ingreso para verlo aquí.',
                            actionLabel: 'Registrar gasto',
                            onAction: () =>
                                context.push(AppRoutes.registerExpense),
                          )
                        else
                          ...recentMovements.map(
                            (tx) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xs,
                              ),
                              child: Card(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.xs,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: tx.isIncome
                                        ? semantic.incomeContainer
                                        : semantic.expenseContainer,
                                    child: Icon(
                                      tx.isIncome
                                          ? Icons.south_west_rounded
                                          : Icons.north_east_rounded,
                                      color: tx.isIncome
                                          ? semantic.income
                                          : semantic.expense,
                                    ),
                                  ),
                                  title: Text(
                                    tx.description,
                                    style: theme.textTheme.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${tx.categoryOrOrigin} · ${DateFormatter.shortDateTime(tx.date)}${tx.isAutomatic ? ' · Auto' : ''}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  trailing: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 120,
                                    ),
                                    child: MoneyAmountText(
                                      hidden: settings.hideBalances,
                                      amountCop: tx.amountCop,
                                      isIncome: tx.isIncome,
                                      showCurrency: false,
                                    ),
                                  ),
                                  onTap: () =>
                                      context.go(AppRoutes.transactions),
                                ),
                              ),
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

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({
    required this.firstName,
    required this.isNegative,
    required this.dailyPaceCop,
    required this.remainingDays,
    required this.hideBalances,
  });

  final String firstName;
  final bool isNegative;
  final int dailyPaceCop;
  final int remainingDays;
  final bool hideBalances;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                firstName == 'Mi' ? '¡Hola!' : '¡Hola, $firstName!',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 2),
              Text(
                hideBalances
                    ? 'Montos ocultos en Inicio'
                    : isNegative
                    ? 'Atención · Disponible en déficit'
                    : '$remainingDays días restantes · ~${CopFormatter.format(dailyPaceCop)} / día',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        if (!hideBalances)
          Semantics(
            label: isNegative ? 'Estado: déficit' : 'Estado: al día',
            child: ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isNegative
                      ? semantic.expenseContainer
                      : semantic.incomeContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isNegative
                          ? Icons.error_outline_rounded
                          : Icons.verified_rounded,
                      size: 16,
                      color: isNegative ? semantic.expense : semantic.income,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isNegative ? 'Déficit' : 'Al día',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isNegative ? semantic.expense : semantic.income,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AutoDetectionBanner extends StatelessWidget {
  const _AutoDetectionBanner({
    required this.pendingCount,
    required this.bridgeSupported,
    required this.onActivate,
    required this.onDismiss,
  });

  final int pendingCount;
  final bool bridgeSupported;
  final VoidCallback onActivate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final bodyText = pendingCount > 0
        ? 'Tienes $pendingCount movimientos detectados por revisar.'
        : bridgeSupported
        ? 'En Android puedes revisar posibles compras de tus apps financieras.'
        : 'La detección automática está disponible en Android. En web registra movimientos manualmente.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: semantic.incomeContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: semantic.income.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.bolt_rounded, color: semantic.income),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detección automática · Nuevo',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(bodyText, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ocultar aviso',
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onActivate,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                bridgeSupported ? 'Revisar movimientos' : 'Ver detalle',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBalanceCard extends StatelessWidget {
  const _HeroBalanceCard({
    required this.summary,
    required this.hideBalances,
    required this.onToggleHide,
  });

  final DashboardSummary summary;
  final bool hideBalances;
  final VoidCallback onToggleHide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final balanceText = hideBalances
        ? '\$ ••••••• COP'
        : CopFormatter.format(summary.availableCop);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: summary.isNegative && !hideBalances
              ? [const Color(0xFF7F1D1D), const Color(0xFF991B1B)]
              : [semantic.heroStart, semantic.heroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Disponible este mes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              IconButton(
                tooltip: hideBalances ? 'Mostrar montos' : 'Ocultar montos',
                onPressed: onToggleHide,
                icon: Icon(
                  hideBalances
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              balanceText,
              style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Presupuesto mensual: ingreso base previsto + adicionales confirmados − gastos. No es el saldo de tus cuentas.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!hideBalances)
            Semantics(
              label:
                  '${summary.committedPercent} por ciento comprometido de tus ingresos',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                child: LinearProgressIndicator(
                  value: summary.committedPercent / 100,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    summary.isNegative
                        ? const Color(0xFFFCA5A5)
                        : AppColors.secondarySoft,
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hideBalances
                ? 'Ingresos, gastos y proporciones ocultos'
                : '${summary.committedPercent}% comprometido · ${CopFormatter.format(summary.expensesCop)} de ${CopFormatter.format(summary.totalIncomeCop)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeparateSummaryGrid extends StatelessWidget {
  const _SeparateSummaryGrid({
    required this.summary,
    required this.hideBalances,
  });

  final DashboardSummary summary;
  final bool hideBalances;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    String maskOrFormat(String formatted) =>
        hideBalances ? '\$ ••••••' : formatted;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 310;
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: narrow ? 1 : 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisExtent: narrow ? 88 : 96,
          ),
          children: [
            _MetricCard(
              label: 'Ingreso base previsto',
              value: maskOrFormat(
                CopFormatter.format(summary.monthlyIncomeCop),
              ),
              icon: Icons.account_balance_wallet_outlined,
              accentColor: semantic.income,
              bgColor: semantic.incomeContainer,
            ),
            _MetricCard(
              label: 'Ingresos adicionales',
              value: maskOrFormat(
                CopFormatter.formatSigned(
                  summary.additionalIncomeCop,
                  isPositive: true,
                ),
              ),
              icon: Icons.add_circle_outline_rounded,
              accentColor: semantic.income,
              bgColor: semantic.incomeContainer,
            ),
            _MetricCard(
              label: 'Gastos',
              value: maskOrFormat(
                CopFormatter.formatSigned(
                  summary.expensesCop,
                  isPositive: false,
                ),
              ),
              icon: Icons.arrow_circle_down_rounded,
              accentColor: semantic.expense,
              bgColor: semantic.expenseContainer,
            ),
            _MetricCard(
              label: 'Disponible este mes',
              value: maskOrFormat(CopFormatter.format(summary.availableCop)),
              icon: summary.isNegative && !hideBalances
                  ? Icons.warning_amber_rounded
                  : Icons.savings_outlined,
              accentColor: summary.isNegative && !hideBalances
                  ? semantic.expense
                  : semantic.income,
              bgColor: summary.isNegative && !hideBalances
                  ? semantic.expenseContainer
                  : semantic.incomeContainer,
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(icon, size: 18, color: accentColor),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.onExpense,
    required this.onIncome,
    required this.onAnalysis,
    required this.onBudgets,
  });

  final VoidCallback onExpense;
  final VoidCallback onIncome;
  final VoidCallback onAnalysis;
  final VoidCallback onBudgets;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 310;
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: narrow ? 1 : 2,
            mainAxisSpacing: AppSpacing.xs,
            crossAxisSpacing: AppSpacing.xs,
            mainAxisExtent: 54,
          ),
          children: [
            OutlinedButton.icon(
              onPressed: onExpense,
              icon: const Icon(Icons.remove_circle_outline_rounded),
              label: const Text(
                'Registrar gasto',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            OutlinedButton.icon(
              onPressed: onIncome,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text(
                'Registrar ingreso',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            OutlinedButton.icon(
              onPressed: onAnalysis,
              icon: const Icon(Icons.analytics_outlined),
              label: const Text(
                'Ver análisis',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            OutlinedButton.icon(
              onPressed: onBudgets,
              icon: const Icon(Icons.account_balance_outlined),
              label: const Text(
                'Presupuestos',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}
