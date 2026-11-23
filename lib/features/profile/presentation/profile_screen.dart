import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_bolsillo/core/formatting/cop_formatter.dart';
import 'package:mi_bolsillo/core/routing/app_routes.dart';
import 'package:mi_bolsillo/core/theme/app_colors.dart';
import 'package:mi_bolsillo/core/theme/app_spacing.dart';
import 'package:mi_bolsillo/core/widgets/app_snackbar.dart';
import 'package:mi_bolsillo/core/widgets/confirm_delete_dialog.dart';
import 'package:mi_bolsillo/features/automatic_detection/application/automatic_detection_controller.dart';
import 'package:mi_bolsillo/features/budgets/application/budgets_controller.dart';
import 'package:mi_bolsillo/features/income/application/income_controller.dart';
import 'package:mi_bolsillo/features/profile/application/settings_controller.dart';
import 'package:mi_bolsillo/features/transactions/application/transactions_controller.dart';

/// Screen 12: Perfil y configuración (ThemeMode claro/oscuro, alertas y reinicio de datos simulados).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final settings = ref.watch(settingsControllerProvider);
    final autoDetectEnabled = ref.watch(
      automaticDetectionControllerProvider.select((s) => s.isEnabled),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil y Configuración')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.pagePadding(context)),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              settings.firstName.isEmpty
                                  ? 'C'
                                  : settings.firstName[0].toUpperCase(),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  settings.userName,
                                  style: theme.textTheme.titleLarge,
                                ),
                                Text(
                                  '100% Local · Datos simulados · v1.0.0',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Preferencias Financieras',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.account_balance_wallet_outlined,
                          ),
                          title: const Text('Ingreso mensual base'),
                          subtitle: Text(
                            CopFormatter.format(settings.monthlyIncomeCop),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push(AppRoutes.onboardingIncome),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.event_repeat_rounded),
                          title: const Text('Frecuencia de pago'),
                          subtitle: Text(settings.payFrequency.label),
                        ),
                        const Divider(height: 1),
                        const ListTile(
                          leading: Icon(Icons.payments_outlined),
                          title: Text('Moneda predeterminada'),
                          subtitle: Text('Peso colombiano (COP \$)'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Automatización y Alertas',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.bolt_rounded),
                          title: const Text('Detección automática'),
                          subtitle: Text(
                            autoDetectEnabled ? 'Activa (simulada)' : 'Pausada',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push(AppRoutes.autoDetection),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          value: settings.dailyReminderEnabled,
                          onChanged: (val) => ref
                              .read(settingsControllerProvider.notifier)
                              .toggleDailyReminder(val),
                          title: const Text('Recordatorio diario 8:00 PM'),
                          subtitle: const Text(
                            'Recordar revisar gastos del día.',
                          ),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          value: settings.budget80AlertEnabled,
                          onChanged: (val) => ref
                              .read(settingsControllerProvider.notifier)
                              .toggleBudget80Alert(val),
                          title: const Text('Alertas de presupuesto al 80 %'),
                          subtitle: const Text(
                            'Aviso preventivo antes de agotar un tope.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Preferencias de la Aplicación',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: settings.themeMode == ThemeMode.dark,
                          onChanged: (isDark) => ref
                              .read(settingsControllerProvider.notifier)
                              .toggleThemeMode(isDark),
                          secondary: const Icon(Icons.dark_mode_outlined),
                          title: const Text('Modo oscuro'),
                          subtitle: const Text(
                            'Alterna entre tema claro y oscuro Emerald Warmth.',
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.slideshow_outlined),
                          title: const Text('Ver bienvenida nuevamente'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.go(AppRoutes.welcome),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Control de Datos Simulados',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(settingsControllerProvider.notifier)
                          .resetDefaults();
                      await ref
                          .read(transactionsControllerProvider.notifier)
                          .resetDefaults();
                      await ref
                          .read(incomeControllerProvider.notifier)
                          .resetDefaults();
                      await ref
                          .read(budgetsControllerProvider.notifier)
                          .resetDefaults();
                      await ref
                          .read(automaticDetectionControllerProvider.notifier)
                          .resetDefaults();
                      if (!context.mounted) return;
                      AppSnackbar.showSuccess(
                        context,
                        'Datos simulados restaurados a valores iniciales',
                      );
                    },
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Restaurar datos simulados'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: semantic.expense,
                      side: BorderSide(color: semantic.expense),
                    ),
                    onPressed: () async {
                      final ok = await ConfirmDeleteDialog.show(
                        context,
                        title: '¿Borrar datos locales y vaciar listas?',
                        description: 'Se vaciarán los movimientos e ingresos adicionales simulados en memoria para probar los estados vacíos.',
                        confirmLabel: 'Borrar todo',
                      );
                      if (!ok || !context.mounted) return;
                      await ref
                          .read(transactionsControllerProvider.notifier)
                          .clearAll();
                      await ref
                          .read(incomeControllerProvider.notifier)
                          .clearAll();
                      if (!context.mounted) return;
                      AppSnackbar.showSuccess(
                        context,
                        'Datos locales simulados borrados',
                      );
                    },
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: const Text('Borrar datos locales y probar vacíos'),
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
