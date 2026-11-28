import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

/// Versioned binary envelope. Header, salt and nonce are authenticated as AAD.
/// KDF parameters are fixed so hostile files cannot request expensive work.
class BackupCipher {
  static const iterations = 600000;
  static const maxPlaintext = 20 * 1024 * 1024;
  static const headerSize = 40;
  static const maxFileSize = maxPlaintext + headerSize + 16;
  static final _magic = ascii.encode('MBSAFE01');

  static bool isEncrypted(List<int> bytes) =>
      bytes.length >= 8 && listEquals(bytes.sublist(0, 8), _magic);

  static void validatePassword(String password) {
    if (password.runes.length < 12 || utf8.encode(password).length > 256) {
      throw const FormatException('Usa una contraseña de 12 a 256 caracteres.');
    }
  }

  Future<Uint8List> encrypt(Uint8List plaintext, String password) {
    validatePassword(password);
    return compute(_process, (
      bytes: plaintext,
      password: password,
      decrypt: false,
    ));
  }

  Future<Uint8List> decrypt(Uint8List file, String password) =>
      compute(_process, (bytes: file, password: password, decrypt: true));

  static Future<Uint8List> _process(
    ({Uint8List bytes, String password, bool decrypt}) request,
  ) async {
    final input = request.bytes;
    final cipher = AesGcm.with256bits();
    late Uint8List header;
    if (request.decrypt) {
      if (!isEncrypted(input) ||
          input.length <= headerSize + 16 ||
          input.length > maxFileSize ||
          ByteData.sublistView(input, 8, 12).getUint32(0) != iterations ||
          utf8.encode(request.password).length > 256) {
        throw const FormatException(
          'Respaldo cifrado inválido o incompatible.',
        );
      }
      header = Uint8List.fromList(input.sublist(0, headerSize));
    } else {
      if (input.isEmpty || input.length > maxPlaintext) {
        throw const FormatException('La copia supera el límite de 20 MB.');
      }
      header = Uint8List(headerSize)..setRange(0, 8, _magic);
      ByteData.sublistView(header, 8, 12).setUint32(0, iterations);
      final random = Random.secure();
      for (var i = 12; i < headerSize; i++) {
        header[i] = random.nextInt(256);
      }
    }
    final key =
        await Pbkdf2(
          macAlgorithm: Hmac.sha256(),
          iterations: iterations,
          bits: 256,
        ).deriveKey(
          secretKey: SecretKey(utf8.encode(request.password)),
          nonce: header.sublist(12, 28),
        );
    try {
      if (request.decrypt) {
        try {
          return Uint8List.fromList(
            await cipher.decrypt(
              SecretBox(
                input.sublist(headerSize, input.length - 16),
                nonce: header.sublist(28),
                mac: Mac(input.sublist(input.length - 16)),
              ),
              secretKey: key,
              aad: header,
            ),
          );
        } on SecretBoxAuthenticationError {
          throw const FormatException(
            'Contraseña incorrecta o respaldo alterado. No se cambiaron tus datos.',
          );
        }
      }
      final box = await cipher.encrypt(
        input,
        secretKey: key,
        nonce: header.sublist(28),
        aad: header,
      );
      return Uint8List.fromList([
        ...header,
        ...box.cipherText,
        ...box.mac.bytes,
      ]);
    } finally {
      key.destroy();
    }
  }
}
