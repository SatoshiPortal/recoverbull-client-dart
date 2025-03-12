import 'dart:convert';

import 'package:hex/hex.dart';
import 'package:recoverbull/recoverbull.dart';
import 'package:recoverbull/src/services/encryption.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final key = HEX.decode(
      'fcb4a38e1d732dede321d13a6ffa024a38ecc4f40c88e9dcc3c9fe51fb942a6f');
  final secret = utf8.encode(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about');

  final backup = BackupService.createBackup(
    secret: secret,
    backupKey: key,
  );
  final encodedCiphertext = backup.ciphertext;
  final encrypted = EncryptionService.splitBytes(encodedCiphertext);
  final ciphertext = encrypted.ciphertext;
  final nonce = encrypted.nonce;
  final hmac = encrypted.hmac;

  group('EncryptionService', () {
    test('create backup', () {
      expect(backup.toJson(), isNotEmpty);
    });

    test('test MAC', () {
      final computedMac = EncryptionService.computeHMac(
        ciphertext: ciphertext,
        nonce: nonce,
        key: key,
      );

      expect(hmac, computedMac);
    });

    test('restore', () {
      final restoredSecret = BackupService.restoreBackup(
        backup: backup,
        backupKey: key,
      );

      expect(restoredSecret, secret);
    });
  });
}
