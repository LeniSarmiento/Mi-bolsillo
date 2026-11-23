import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_bolsillo/core/routing/app_routes.dart';
import 'package:mi_bolsillo/core/theme/app_colors.dart';
import 'package:mi_bolsillo/core/theme/app_spacing.dart';
import 'package:mi_bolsillo/core/widgets/app_snackbar.dart';
import 'package:mi_bolsillo/features/automatic_detection/application/automatic_detection_controller.dart';

/// Screen 8: Detección automática (simulada localmente sin permisos reales).
class AutoDetectionScreen extends ConsumerWidget {
  const AutoDetectionScreen({super.key});

  static const _supportedApps = [
    (
      'Bancolombia',
      'Notificaciones de compras con tarjeta o QR',
      Icons.account_balance_rounded,
    ),
    (
      'Nequi',
      'Pagos, envíos y compras desde tu bolsillo digital',
      Icons.smartphone_rounded,
    ),
    (
      'Daviplata',
      'Movimientos de pagos y recargas locales',
      Icons.payments_outlined,
    ),
    (
      'Tarjetas de Crédito / Débito',
      'Alertas de compras en comercios',
      Icons.credit_card_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final state = ref.watch(automaticDetectionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Detección automática')),
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
                    child: SwitchListTile(
                      value: state.isEnabled,
                      onChanged: (val) async {
                        await ref
                            .read(automaticDetectionControllerProvider.notifier)
                            .setEnabled(val);
                        if (!context.mounted) return;
                        AppSnackbar.showSuccess(
                          context,
                          val
                              ? 'Detección automática activada (simulación)'
                              : 'Detección automática pausada',
                        );
                      },
                      title: const Text('Detección activa'),
                      subtitle: Text(
                        state.isEnabled
                            ? 'Identifica pagos en tu teléfono antes de guardarlos.'
                            : 'Pausada: solo registrarás movimientos manualmente.',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    color: semantic.incomeContainer.withValues(alpha: 0.7),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                      leading: CircleAvatar(
                        backgroundColor: semantic.income,
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        'Movimientos pendientes · ${state.pending.length} listos',
                        style: theme.textTheme.titleMedium,
                      ),
                      subtitle: const Text(
                        'Revisa, edita o confirma los gastos detectados.',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(AppRoutes.pendingMovements),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('¿Cómo funciona?', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ejemplo de notificación bancaria simulada:',
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                            child: const Text(
                              'Bancolombia: Compraste \$78.500 COP en ÉXITO CALLE 80 con tu tarjeta.',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                color: semantic.income,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              const Expanded(
                                child: Text(
                                  'Privacidad 100% garantizada: el análisis ocurre en tu dispositivo sin enviar datos a servidores externos.',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Aplicaciones reconocidas',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ..._supportedApps.map(
                    (app) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(
                              app.$3,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            app.$1,
                            style: theme.textTheme.titleSmall,
                          ),
                          subtitle: Text(app.$2),
                          trailing: Icon(
                            Icons.check_circle_rounded,
                            color: state.isEnabled
                                ? semantic.income
                                : semantic.mutedText,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: () {
                      AppSnackbar.showSuccess(
                        context,
                        'Simulación lista: los permisos reales de Android se conectarán en una fase posterior.',
                      );
                    },
                    icon: const Icon(Icons.settings_suggest_rounded),
                    label: const Text('Configurar permisos de Android'),
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
