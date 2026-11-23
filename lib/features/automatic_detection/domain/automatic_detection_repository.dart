import 'package:mi_bolsillo/features/automatic_detection/domain/pending_movement.dart';

/// Abstract repository contract for simulated local automatic detection.
abstract class AutomaticDetectionRepository {
  Future<bool> isEnabled();
  Future<void> setEnabled(bool enabled);
  Future<List<PendingMovement>> getPendingMovements();
  Future<void> removePendingMovement(String id);
  Future<void> clearPending();
  Future<void> resetToMockDefaults();
}
