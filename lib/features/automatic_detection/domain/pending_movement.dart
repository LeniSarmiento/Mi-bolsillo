import 'package:material_ui/material_ui.dart';

/// Simulated notification-detected pending expense before user confirmation.
@immutable
class PendingMovement {
  const PendingMovement({
    required this.id,
    required this.merchant,
    required this.amountCop,
    required this.sourceApp,
    required this.paymentMethod,
    required this.suggestedCategory,
    required this.confidencePercent,
    required this.detectedAt,
    required this.notificationPreview,
  });

  final String id;
  final String merchant;
  final int amountCop;
  final String sourceApp;
  final String paymentMethod;
  final String suggestedCategory;
  final int confidencePercent;
  final DateTime detectedAt;
  final String notificationPreview;

  PendingMovement copyWith({
    String? id,
    String? merchant,
    int? amountCop,
    String? sourceApp,
    String? paymentMethod,
    String? suggestedCategory,
    int? confidencePercent,
    DateTime? detectedAt,
    String? notificationPreview,
  }) {
    return PendingMovement(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      amountCop: amountCop ?? this.amountCop,
      sourceApp: sourceApp ?? this.sourceApp,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      confidencePercent: confidencePercent ?? this.confidencePercent,
      detectedAt: detectedAt ?? this.detectedAt,
      notificationPreview: notificationPreview ?? this.notificationPreview,
    );
  }
}
