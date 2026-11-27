import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_bolsillo/app/providers.dart';
import 'package:mi_bolsillo/core/routing/app_routes.dart';
import 'package:mi_bolsillo/core/theme/app_colors.dart';
import 'package:mi_bolsillo/core/theme/app_spacing.dart';
import 'package:mi_bolsillo/core/widgets/app_snackbar.dart';
import 'package:mi_bolsillo/core/widgets/state_feedback_views.dart';
import 'package:mi_bolsillo/features/automatic_detection/application/automatic_detection_controller.dart';

/// Screen 8: Detección automática con consentimiento en Android.
class AutoDetectionScreen extends ConsumerWidget {
  const AutoDetectionScreen({super.key});

  static const _supportedApps = [
    (
      'Bancolombia',
      'Notificaciones de compras con tarjeta o QR',
      Icons.account_balance_rounded,
    ),
    ('Nequi', 'Notificaciones de compras y pagos', Icons.smartphone_rounded),
    ('Daviplata', 'Notificaciones de compras y pagos', Icons.payments_outlined),
  ];

  Future<void> _change(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    if (enabled) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Acceso a notificaciones'),
          content: const Text(
            'Android concede acceso a las notificaciones. Mi Bolsillo revisa avisos de compra de las aplicaciones indicadas y guarda en este dispositivo el comercio, monto, fecha y origen para que los confirmes. Puedes desactivarlo aquí o revocar el acceso en Ajustes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (accepted != true || !context.mounted) return;
    }
    try {
      await ref
          .read(automaticDetectionControllerProvider.notifier)
          .setEnabled(enabled);
      if (context.mounted) {
        AppSnackbar.showSuccess(
          context,
          !enabled
              ? 'Detección automática pausada'
              : ref.read(automaticDetectionControllerProvider).isEnabled
              ? 'Detección automática activada'
              : 'Autoriza el acceso en Ajustes de Android y vuelve a la aplicación.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.showError(context, 'No se pudo configurar el acceso');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final state = ref.watch(automaticDetectionControllerProvider);
    final supported = ref.watch(bridgeProvider).supported;

    return Scaffold(
      appBar: AppBar(title: const Text('Detección automática')),
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
                        if (!supported) ...[
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: semantic.warningContainer,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: semantic.warning,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    kIsWeb
                                        ? 'La detección automática está disponible en Android. En la versión web puedes registrar tus gastos e ingresos manualmente.'
                                        : 'La detección automática está disponible únicamente en Android.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: semantic.warning,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        Card(
                          child: SwitchListTile(
                            value: state.isEnabled,
                            onChanged: !supported || state.isSaving
                                ? null
                                : (val) => _change(context, ref, val),
                            title: const Text('Detección activa'),
                            subtitle: Text(
                              !supported
                                  ? 'Disponible únicamente en Android'
                                  : state.isEnabled
                                  ? 'Identifica pagos en tu teléfono antes de guardarlos.'
                                  : 'Pausada: solo registrarás movimientos manualmente.',
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Card(
                          color: semantic.incomeContainer.withValues(
                            alpha: 0.7,
                          ),
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
                            onTap: () =>
                                context.push(AppRoutes.pendingMovements),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          '¿Cómo funciona?',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ejemplo de notificación reconocida:',
                                  style: theme.textTheme.labelMedium,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                  ),
                                  child: const Text(
                                    'Bancolombia: Compraste \$78.500 COP en ÉXITO CALLE 80 con tu tarjeta.',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                const Text(
                                  'Solo se revisan formatos de compra reconocidos de las aplicaciones indicadas. Los avisos ambiguos, sin monto o no reconocidos requieren registro manual. No existe conexión directa con tu banco.',
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
                                        'La información se procesa y almacena localmente en tu dispositivo.',
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
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
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
                          onPressed: !supported || state.isSaving
                              ? null
                              : () => _change(context, ref, true),
                          icon: state.isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.settings_suggest_rounded),
                          label: Text(
                            state.isSaving
                                ? 'Configurando...'
                                : 'Configurar permisos de Android',
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
