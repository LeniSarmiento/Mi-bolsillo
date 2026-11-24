import '../domain/automatic_detection_repository.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_bolsillo/app/providers.dart';
import 'package:mi_bolsillo/features/automatic_detection/domain/pending_movement.dart';
import 'package:mi_bolsillo/features/transactions/application/transactions_controller.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';
import 'package:mi_bolsillo/core/errors/finance_failure.dart';

class AutomaticDetectionState {
  const AutomaticDetectionState({
    this.isEnabled = false,
    this.pending = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final bool isEnabled;
  final List<PendingMovement> pending;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  int get totalPendingCop =>
      pending.fold(0, (sum, item) => sum + item.amountCop);

  AutomaticDetectionState copyWith({
    bool? isEnabled,
    List<PendingMovement>? pending,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AutomaticDetectionState(
      isEnabled: isEnabled ?? this.isEnabled,
      pending: pending ?? this.pending,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
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
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final enabled = await repo.isEnabled();
      final items = await repo.getPendingMovements();
      state = AutomaticDetectionState(
        isEnabled: enabled,
        pending: items,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: FinanceFailure.from(error).message,
      );
    }
  }

  Future<void> setEnabled(bool enabled) async {
    await _save(() async {
      await ref.read(automaticDetectionRepositoryProvider).setEnabled(enabled);
      await load();
    });
  }

  Future<void> confirmOne(PendingMovement movement, {String? category}) async {
    await _save(() => _confirmOne(movement, category: category));
  }

  Future<void> _confirmOne(PendingMovement movement, {String? category}) async {
    final repo = ref.read(automaticDetectionRepositoryProvider);
    if (repo is PendingReviewRepository) {
      await (repo as PendingReviewRepository).confirm(
        movement,
        category: category,
      );
      await ref
          .read(transactionsControllerProvider.notifier)
          .loadTransactions();
      await load();
      return;
    }
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

  Future<void> editPending(PendingMovement movement) async {
    await _save(() async {
      final repo = ref.read(
        automaticDetectionRepositoryProvider,
      ) as PendingReviewRepository;
      await repo.editPending(movement);
      await load();
    });
  }

  Future<void> confirmAll() async {
    await _save(() async {
      final current = List<PendingMovement>.from(state.pending);
      for (final movement in current) {
        await _confirmOne(movement);
      }
    });
  }

  Future<void> discardOne(String id) async {
    await _save(() async {
      await ref
          .read(automaticDetectionRepositoryProvider)
          .removePendingMovement(id);
      final remaining = await ref
          .read(automaticDetectionRepositoryProvider)
          .getPendingMovements();
      state = state.copyWith(pending: remaining);
    });
  }

  Future<void> resetDefaults() async {
    await _save(() async {
      final repo = ref.read(automaticDetectionRepositoryProvider);
      await repo.resetToMockDefaults();
      await load();
    });
  }

  Future<void> _save(Future<void> Function() operation) async {
    if (state.isSaving) return;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await operation();
      state = state.copyWith(isSaving: false);
    } catch (error, stackTrace) {
      final failure = FinanceFailure.from(error);
      state = state.copyWith(isSaving: false, errorMessage: failure.message);
      Error.throwWithStackTrace(failure, stackTrace);
    }
  }
}

final automaticDetectionControllerProvider =
    NotifierProvider<AutomaticDetectionController, AutomaticDetectionState>(
      AutomaticDetectionController.new,
    );
