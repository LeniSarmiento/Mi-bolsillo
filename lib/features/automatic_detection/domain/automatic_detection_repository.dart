import 'package:mi_bolsillo/features/automatic_detection/domain/pending_movement.dart';

/// Abstract repository contract for local automatic detection.
abstract class AutomaticDetectionRepository {
  Future<bool> isEnabled();
  Future<void> setEnabled(bool enabled);
  Future<List<PendingMovement>> getPendingMovements();
  Future<void> removePendingMovement(String id);
  Future<void> clearPending();
  Future<void> resetToMockDefaults();
}

/// Optional capability for persistent pending records with atomic transitions.
abstract interface class PendingReviewRepository {
  Future<void> editPending(PendingMovement movement);
  Future<void> confirm(PendingMovement movement, {String? category});
}
