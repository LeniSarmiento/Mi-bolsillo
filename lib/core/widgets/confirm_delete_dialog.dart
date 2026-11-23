import 'package:material_ui/material_ui.dart';
import 'package:mi_bolsillo/core/theme/app_colors.dart';

/// Shared delete confirmation dialog to prevent accidental deletions.
class ConfirmDeleteDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String description,
    String confirmLabel = 'Eliminar',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final semantic = dialogContext.semanticColors;
        return AlertDialog(
          icon: Icon(
            Icons.delete_outline_rounded,
            color: semantic.expense,
            size: 32,
          ),
          title: Text(title),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: semantic.expense,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
