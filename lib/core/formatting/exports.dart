import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/analysis/application/analysis_provider.dart';
import '../../features/transactions/domain/transaction_item.dart';
import '../widgets/app_snackbar.dart';
import 'cop_formatter.dart';
import '../security/device_security.dart';

String movementCsv(Iterable<TransactionItem> items) {
  String cell(String s) {
    final safe = RegExp(r'^[=+@\-\t\r]').hasMatch(s) ? "'$s" : s;
    return '"${safe.replaceAll('"', '""')}"';
  }

  return [
    ['Fecha', 'Tipo', 'Monto COP', 'Descripción', 'Categoría', 'Método'],
    ...items.map(
      (m) => [
        m.date.toIso8601String(),
        m.isIncome ? 'Ingreso' : 'Gasto',
        m.amountCop.toString(),
        m.description,
        m.categoryOrOrigin,
        m.paymentMethod,
      ],
    ),
  ].map((row) => row.map(cell).join(',')).join('\r\n');
}

Future<void> exportLedger(BuildContext context, List<TransactionItem> items) =>
    _save(
      context,
      'movimientos.csv',
      'text/csv',
      () async =>
          Uint8List.fromList(utf8.encode('\uFEFF${movementCsv(items)}')),
    );
Future<void> exportReport(
  BuildContext context,
  AnalysisReport r,
  String period,
) => _save(context, 'resumen.pdf', 'application/pdf', () async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      build: (_) => [
        pw.Header(text: 'Mi Bolsillo - Resumen $period'),
        pw.Text('Ingresos: ${CopFormatter.format(r.totalIncomeCop)}'),
        pw.Text('Gastos: ${CopFormatter.format(r.totalExpensesCop)}'),
        pw.Text('Disponible: ${CopFormatter.format(r.savedCop)}'),
        pw.Header(level: 1, text: 'Gastos por categoría'),
        ...r.categories.map(
          (c) => pw.Text('${c.category}: ${CopFormatter.format(c.amountCop)}'),
        ),
      ],
    ),
  );
  return pdf.save();
});
Future<void> _save(
  BuildContext context,
  String name,
  String type,
  Future<Uint8List> Function() bytes,
) async {
  try {
    final session = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(securitySessionProvider.notifier);
    if (!await session.unlock('Exportar reporte financiero') ||
        !context.mounted) {
      return;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar reporte sin cifrar'),
        content: const Text(
          'El reporte contiene información financiera legible. Elige una carpeta privada del dispositivo y compártelo solo con quien corresponda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exportar'),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return;
    final uri = await FilePicker.saveFile(
      fileName: name,
      mimeType: type,
      bytes: await bytes(),
    );
    if (context.mounted && uri != null) {
      AppSnackbar.showSuccess(context, 'Archivo exportado');
    }
  } catch (_) {
    if (context.mounted) {
      AppSnackbar.showError(context, 'No se pudo exportar el archivo');
    }
  }
}
