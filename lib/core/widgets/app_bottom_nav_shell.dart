import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_bolsillo/core/routing/app_routes.dart';
import 'package:mi_bolsillo/core/theme/app_colors.dart';
import 'package:mi_bolsillo/core/theme/app_spacing.dart';

/// Persistent Material 3 navigation shell for Dashboard, Movimientos, Análisis, and Perfil,
/// paired with the `+ Registrar` extended FAB from the Stitch design.
class AppBottomNavShell extends StatelessWidget {
  const AppBottomNavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _openQuickRegisterSheet(BuildContext context) {
    final semantic = context.semanticColors;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '¿Qué deseas registrar?',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  minVerticalPadding: 14,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  tileColor: semantic.expenseContainer.withValues(alpha: 0.45),
                  leading: CircleAvatar(
                    backgroundColor: semantic.expenseContainer,
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      color: semantic.expense,
                    ),
                  ),
                  title: const Text('Registrar gasto'),
                  subtitle: const Text(
                    'Descuenta de tu disponible y presupuestos',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push(AppRoutes.registerExpense);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  minVerticalPadding: 14,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  tileColor: semantic.incomeContainer.withValues(alpha: 0.45),
                  leading: CircleAvatar(
                    backgroundColor: semantic.incomeContainer,
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: semantic.income,
                    ),
                  ),
                  title: const Text('Registrar ingreso adicional'),
                  subtitle: const Text(
                    'Suma horas extras, ventas o trabajos aparte',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push(AppRoutes.registerIncome);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    final showFab =
        currentIndex != 3; // Stitch shows FAB on Inicio, Movimientos, Análisis

    return Scaffold(
      body: navigationShell,
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => _openQuickRegisterSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Registrar'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Movimientos',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: Icon(Icons.pie_chart_rounded),
            label: 'Análisis',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
