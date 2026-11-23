import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_bolsillo/app/providers.dart';
import 'package:mi_bolsillo/features/automatic_detection/domain/pending_movement.dart';
import 'package:mi_bolsillo/features/transactions/application/transactions_controller.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

class AutomaticDetectionState {
  const AutomaticDetectionState({
    this.isEnabled = true,
    this.pending = const [],
    this.isLoading = false,
  });

  final bool isEnabled;
  final List<PendingMovement> pending;
  final bool isLoading;

  int get totalPendingCop =>
      pending.fold(0, (sum, item) => sum + item.amountCop);

  AutomaticDetectionState copyWith({
    bool? isEnabled,
    List<PendingMovement>? pending,
    bool? isLoading,
  }) {
    return AutomaticDetectionState(
      isEnabled: isEnabled ?? this.isEnabled,
      pending: pending ?? this.pending,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AutomaticDetectionController extends Notifier<AutomaticDetectionState> {
  @override
  AutomaticDetectionState build() {
    Future.microtask(load);
    return const AutomaticDetectionState(isLoading: true);
  }

  Future<void> load() async {
    final repo = ref.read(automaticDetectionRepositoryProvider);
    final enabled = await repo.isEnabled();
    final items = await repo.getPendingMovements();
    state = AutomaticDetectionState(
      isEnabled: enabled,
      pending: items,
      isLoading: false,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    await ref.read(automaticDetectionRepositoryProvider).setEnabled(enabled);
    state = state.copyWith(isEnabled: enabled);
  }

  Future<void> confirmOne(PendingMovement movement, {String? category}) async {
    await ref
        .read(transactionsControllerProvider.notifier)
        .addExpense(
          amountCop: movement.amountCop,
          description: movement.merchant,
          category: category ?? movement.suggestedCategory,
          date: movement.detectedAt,
          paymentMethod: movement.paymentMethod,
          recurrence: RecurrenceFrequency.none,
          isAutomatic: true,
        );
    await ref
        .read(automaticDetectionRepositoryProvider)
        .removePendingMovement(movement.id);
    final remaining = await ref
        .read(automaticDetectionRepositoryProvider)
        .getPendingMovements();
    state = state.copyWith(pending: remaining);
  }

  Future<void> confirmAll() async {
    final current = List<PendingMovement>.from(state.pending);
    for (final movement in current) {
      await ref
          .read(transactionsControllerProvider.notifier)
          .addExpense(
            amountCop: movement.amountCop,
            description: movement.merchant,
            category: movement.suggestedCategory,
            date: movement.detectedAt,
            paymentMethod: movement.paymentMethod,
            recurrence: RecurrenceFrequency.none,
            isAutomatic: true,
          );
    }
    await ref.read(automaticDetectionRepositoryProvider).clearPending();
    state = state.copyWith(pending: const []);
  }

  Future<void> discardOne(String id) async {
    await ref
        .read(automaticDetectionRepositoryProvider)
        .removePendingMovement(id);
    final remaining = await ref
        .read(automaticDetectionRepositoryProvider)
        .getPendingMovements();
    state = state.copyWith(pending: remaining);
  }

  Future<void> resetDefaults() async {
    final repo = ref.read(automaticDetectionRepositoryProvider);
    await repo.resetToMockDefaults();
    await load();
  }
}

final automaticDetectionControllerProvider =
    NotifierProvider<AutomaticDetectionController, AutomaticDetectionState>(
      AutomaticDetectionController.new,
    );
