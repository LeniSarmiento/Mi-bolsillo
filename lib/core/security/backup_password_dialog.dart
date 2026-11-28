import 'package:material_ui/material_ui.dart';

import 'backup_cipher.dart';

Future<String?> requestBackupPassword(
  BuildContext context, {
  required bool creating,
}) => showDialog<String>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _PasswordDialog(creating: creating),
);

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.creating});
  final bool creating;
  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _password.clear();
    _confirmation.clear();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    try {
      if (widget.creating) BackupCipher.validatePassword(_password.text);
      if (_password.text.isEmpty ||
          (widget.creating && _password.text != _confirmation.text)) {
        throw const FormatException('Las contraseñas deben coincidir.');
      }
      Navigator.pop(context, _password.text);
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.creating ? 'Proteger copia de seguridad' : 'Abrir copia cifrada',
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.creating
                ? 'Usa al menos 12 caracteres. Conserva la contraseña en un lugar seguro: no podemos recuperarla. El archivo se cifrará antes de elegir dónde guardarlo.'
                : 'Introduce la contraseña que usaste al crear esta copia.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            maxLength: 256,
            keyboardType: TextInputType.visiblePassword,
            decoration: const InputDecoration(
              labelText: 'Contraseña del respaldo',
            ),
          ),
          if (widget.creating)
            TextField(
              controller: _confirmation,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              maxLength: 256,
              keyboardType: TextInputType.visiblePassword,
              decoration: const InputDecoration(
                labelText: 'Repetir contraseña',
              ),
            ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _submit,
        child: Text(widget.creating ? 'Cifrar copia' : 'Desbloquear copia'),
      ),
    ],
  );
}
