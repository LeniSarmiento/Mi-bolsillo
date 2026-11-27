import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../data/local_backup.dart';
import '../../../data/local_detection.dart';
import '../../../data/finance_database.dart';
import '../../automatic_detection/application/automatic_detection_controller.dart';
import '../../budgets/application/budgets_controller.dart';
import '../../income/application/income_controller.dart';
import '../../transactions/application/transactions_controller.dart';
import '../application/settings_controller.dart';

class BackupControls extends ConsumerStatefulWidget {
  const BackupControls({super.key});
  @override
  ConsumerState<BackupControls> createState() => _BackupControlsState();
}

class _BackupControlsState extends ConsumerState<BackupControls> {
  bool _busy = false;
  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) return;
    final activity = ref.read(backupActivityProvider.notifier);
    if (ref.read(backupActivityProvider)) return;
    setState(() => _busy = true);
    activity.setBusy(true);
    final navigator = Navigator.of(context, rootNavigator: true);
    final progress = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('Procesando copia local…')),
            ],
          ),
        ),
      ),
    );
    navigator.push(progress);
    try {
      await ref.read(settingsControllerProvider.notifier).whenIdle();
      await operation();
    } on FormatException catch (error) {
      if (mounted) AppSnackbar.showError(context, error.message);
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          'No se pudo completar la copia local. Tus datos no se reemplazan si la restauración falla.',
        );
      }
    } finally {
      activity.setBusy(false);
      if (progress.isActive) navigator.removeRoute(progress);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() => _run(() async {
    final db = ref.read(databaseProvider);
    await LocalDetection(
      ref.read(ledgerProvider),
      ref.read(bridgeProvider),
    ).importQueue();
    final bytes = await LocalBackup(db).export();
    final saved = await FilePicker.saveFile(
      fileName: 'mi-bolsillo-${DateTime.now().millisecondsSinceEpoch}.json',
      mimeType: 'application/json',
      bytes: bytes,
    );
    if (mounted && saved != null) {
      AppSnackbar.showSuccess(context, 'Copia local guardada');
    }
  });

  Future<void> _import() => _run(() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (files.isEmpty) return;
    final buffer = BytesBuilder(copy: false);
    await for (final chunk in files.single.readAsByteStream()) {
      if (buffer.length + chunk.length > LocalBackup.maxBytes) {
        throw const FormatException('La copia supera el límite de 20 MB');
      }
      buffer.add(chunk);
    }
    final bytes = buffer.takeBytes();
    final db = ref.read(databaseProvider);
    final backup = LocalBackup(db);
    final archive = backup.prepare(bytes);
    if (!mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Restaurar copia local?'),
        content: Text(
          'Reemplazará los datos actuales por ${archive.movements.length} movimientos y ${archive.budgets.length} presupuestos. Exporta primero si deseas conservar tus cambios actuales. La detección y los recordatorios quedarán pausados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    final bridge = ref.read(bridgeProvider);
    final wasEnabled = await bridge.enabled();
    await bridge.setEnabled(false);
    try {
      final pending = await bridge.peek();
      await db.transaction(() async {
        await backup.restore(archive);
        // Tombstones prevent pre-restore queued notices from reappearing even
        // if Android fails to clear its separate storage after SQL commits.
        for (final row in pending) {
          await db
              .into(db.detectionReceipts)
              .insertOnConflictUpdate(
                DetectionReceipt(
                  fingerprint: row['id'] as String,
                  sourceApp: row['app'] as String,
                ),
              );
        }
      });
    } catch (_) {
      if (wasEnabled) await bridge.setEnabled(true);
      rethrow;
    }
    var nativeCleanupFailed = false;
    try {
      await bridge.erase();
      await ref.read(appNotificationsProvider).syncDailyReminder(false);
    } catch (_) {
      nativeCleanupFailed = true;
    }
    ref.invalidate(settingsControllerProvider);
    ref.invalidate(transactionsControllerProvider);
    ref.invalidate(incomeControllerProvider);
    ref.invalidate(budgetsControllerProvider);
    ref.invalidate(automaticDetectionControllerProvider);
    if (mounted) {
      AppSnackbar.showSuccess(
        context,
        nativeCleanupFailed
            ? 'Copia restaurada. Revisa los recordatorios en Ajustes de Android.'
            : 'Copia restaurada. Automatización pausada hasta que la actives.',
      );
    }
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Copia de seguridad local'),
      const Text(
        'El archivo contiene tus datos financieros sin cifrar. Elige una carpeta privada en el dispositivo. CSV y PDF son reportes, no copias restaurables.',
      ),
      OutlinedButton.icon(
        onPressed: _busy ? null : _export,
        icon: const Icon(Icons.save_alt),
        label: const Text('Exportar copia local'),
      ),
      OutlinedButton.icon(
        onPressed: _busy ? null : _import,
        icon: const Icon(Icons.restore),
        label: const Text('Restaurar copia local'),
      ),
      if (_busy) const LinearProgressIndicator(),
    ],
  );
}
