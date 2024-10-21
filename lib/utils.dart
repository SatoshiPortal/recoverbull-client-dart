import 'dart:convert';
import 'package:fast_rsa/fast_rsa.dart' as fast;
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/services.dart';

Future<String> generateEncryptedBackup(
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
    return jsonBackup;
  } catch (e) {
    print('Failed to generate backup: $e');
    rethrow;
  }
}

String decryptBackup(String json, String secretKey) {
  try {
    var backup = jsonDecode(json);
    if (backup['iv'] == null ||
        backup['encrypted'] == null ||
        backup['key_id'] == null) {
      throw Exception('Invalid backup');
    }

    final key = Key.fromBase64(secretKey);
    final secretKeyHash = sha256.convert(utf8.encode(key.base64)).toString();
    if (backup['key_id'] != secretKeyHash) {
      throw Exception('Invalid key');
    }

    final iv = IV.fromBase64(backup['iv']);
    final encrypted = Encrypted.fromBase64(backup['encrypted']);
    final encrypter = Encrypter(AES(key));

    final decrypted = encrypter.decrypt(encrypted, iv: iv);
    return decrypted;
  } catch (e) {
    print('Failed to decrypt backup: $e');
    rethrow;
  }
}

Future<String> encryptMessage(String message, String publicKey) async {
  final bytes = utf8.encode(message);
  final base64 = base64Encode(bytes);
  return await fast.RSA.encryptOAEP(base64, '', fast.Hash.SHA256, publicKey);
}

Future<String> decryptMessage(String message, String privateKey) async {
  final base64 =
      await fast.RSA.decryptOAEP(message, '', fast.Hash.SHA256, privateKey);
  final bytes = base64Decode(base64);
  return utf8.decode(bytes);
}

Future<(String, String)> getBranchAndCommit() async {
  final head = await rootBundle.loadString('.git/HEAD');
  final commitId = await rootBundle.loadString('.git/ORIG_HEAD');
  final branch = head.split('/').last;
  return (branch.trim(), commitId.trim());
}
