import 'package:mi_bolsillo/features/automatic_detection/domain/automatic_detection_repository.dart';
import 'package:mi_bolsillo/features/automatic_detection/domain/pending_movement.dart';

/// In-memory mock repository for automatic detection (3 Colombian bank alerts).
class MockAutomaticDetectionRepository implements AutomaticDetectionRepository {
  MockAutomaticDetectionRepository() : _items = _seedDefaults();

  bool _enabled = true;
  List<PendingMovement> _items;

  static List<PendingMovement> _seedDefaults() {
    final now = DateTime.now();
    return [
      PendingMovement(
        id: 'pend-1',
        merchant: 'Éxito Calle 80',
        amountCop: 78500,
        sourceApp: 'Bancolombia',
        paymentMethod: 'Tarjeta Bancaria',
        suggestedCategory: 'Alimentación',
        confidencePercent: 98,
        detectedAt: now.subtract(const Duration(minutes: 18)),
        notificationPreview: 'Bancolombia: Compraste \$78.500 COP en ÉXITO CALLE 80 con tu tarjeta.',
      ),
      PendingMovement(
        id: 'pend-2',
        merchant: 'Didi Food Colombia',
        amountCop: 24900,
        sourceApp: 'Nequi',
        paymentMethod: 'Nequi / Daviplata',
        suggestedCategory: 'Alimentación',
        confidencePercent: 94,
        detectedAt: now.subtract(const Duration(hours: 2)),
        notificationPreview:
            'Nequi: Pagaste \$24.900 COP a DIDI FOOD COLOMBIA.',
      ),
      PendingMovement(
        id: 'pend-3',
        merchant: 'Estación Terpel',
        amountCop: 50000,
        sourceApp: 'Daviplata',
        paymentMethod: 'Nequi / Daviplata',
        suggestedCategory: 'Transporte',
        confidencePercent: 92,
        detectedAt: now.subtract(const Duration(hours: 5)),
        notificationPreview:
            'DaviPlata: Compra aprobada por \$50.000 COP en EDS TERPEL.',
      ),
    ];
  }

  @override
  Future<bool> isEnabled() async => _enabled;

  @override
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
  }

  @override
  Future<List<PendingMovement>> getPendingMovements() async {
    return List<PendingMovement>.from(_items);
  }

  @override
  Future<void> removePendingMovement(String id) async {
    _items = _items.where((e) => e.id != id).toList();
  }

  @override
  Future<void> clearPending() async {
    _items = [];
  }

  @override
  Future<void> resetToMockDefaults() async {
    _enabled = true;
    _items = _seedDefaults();
  }
}
