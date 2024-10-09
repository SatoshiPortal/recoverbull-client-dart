import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

Future<File> generateBackup(
  String path,
  String plaintext,
  String secretKey,
) async {
  try {
    final key = Key.fromBase64(secretKey);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    final secretKeyHash = sha256.convert(utf8.encode(key.base64)).toString();

    final backup = Map<String, String>.from({
      'key_id': secretKeyHash,
      'iv': iv.base64,
      'encrypted': encrypted.base64,
    });

    final jsonBackup = jsonEncode(backup);

    final file = File('$path/backup.json');
    await file.writeAsString(jsonBackup);
    return file;
  } catch (e) {
    print('Failed to generate backup: $e');
    rethrow;
  }
}
