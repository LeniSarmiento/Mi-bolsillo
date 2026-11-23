import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_bolsillo/core/routing/app_routes.dart';
import 'package:mi_bolsillo/core/widgets/app_bottom_nav_shell.dart';
import 'package:mi_bolsillo/features/analysis/presentation/analysis_screen.dart';
import 'package:mi_bolsillo/features/automatic_detection/presentation/auto_detection_screen.dart';
import 'package:mi_bolsillo/features/automatic_detection/presentation/pending_movements_screen.dart';
import 'package:mi_bolsillo/features/budgets/presentation/budgets_screen.dart';
import 'package:mi_bolsillo/features/budgets/presentation/create_budget_screen.dart';
import 'package:mi_bolsillo/features/dashboard/presentation/dashboard_screen.dart';
import 'package:mi_bolsillo/features/income/domain/additional_income.dart';
import 'package:mi_bolsillo/features/income/presentation/register_income_screen.dart';
import 'package:mi_bolsillo/features/onboarding/presentation/initial_income_screen.dart';
import 'package:mi_bolsillo/features/onboarding/presentation/welcome_screen.dart';
import 'package:mi_bolsillo/features/profile/presentation/profile_screen.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';
import 'package:mi_bolsillo/features/transactions/presentation/register_expense_screen.dart';
import 'package:mi_bolsillo/features/transactions/presentation/transactions_screen.dart';

/// Builds the GoRouter configuration connecting all 12 Mi Bolsillo screens.
GoRouter createAppRouter({String initialLocation = AppRoutes.welcome}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingIncome,
        builder: (context, state) => const InitialIncomeScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppBottomNavShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.transactions,
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.analysis,
                builder: (context, state) => const AnalysisScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.registerExpense,
        builder: (context, state) {
          final existing = state.extra is TransactionItem
              ? state.extra as TransactionItem
              : null;
          return RegisterExpenseScreen(existingTransaction: existing);
        },
      ),
      GoRoute(
        path: AppRoutes.registerIncome,
        builder: (context, state) {
          final existing = state.extra is AdditionalIncome
              ? state.extra as AdditionalIncome
              : null;
          return RegisterIncomeScreen(existingIncome: existing);
        },
      ),
      GoRoute(
        path: AppRoutes.autoDetection,
        builder: (context, state) => const AutoDetectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.pendingMovements,
        builder: (context, state) => const PendingMovementsScreen(),
      ),
      GoRoute(
        path: AppRoutes.budgets,
        builder: (context, state) => const BudgetsScreen(),
      ),
      GoRoute(
        path: AppRoutes.createBudget,
        builder: (context, state) => const CreateBudgetScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Ruta no encontrada')),
      body: Center(
        child: FilledButton(
          onPressed: () => context.go(AppRoutes.dashboard),
          child: const Text('Volver al inicio'),
        ),
      ),
    ),
  );
}
