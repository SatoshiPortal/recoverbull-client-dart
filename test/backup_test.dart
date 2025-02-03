import 'dart:convert';

import 'package:hex/hex.dart';
import 'package:recoverbull/recoverbull.dart';
import 'package:recoverbull/src/services/encryption.dart';
import 'package:test/test.dart';

void main() {
  final key = HEX.decode(
      'fcb4a38e1d732dede321d13a6ffa024a38ecc4f40c88e9dcc3c9fe51fb942a6f');
  final secret = utf8.encode(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about');

  final backupJson = BackupService.createBackup(
    secret: secret,
    backupKey: key,
  );
  final backup = Backup.fromJson(backupJson);
  final encodedCiphertext = base64.decode(backup.ciphertext);
  final encrypted = EncryptionService.decode(encodedCiphertext);
  final ciphertext = encrypted.ciphertext;
  final nonce = encrypted.nonce;
  final hmac = encrypted.hmac;

  group('EncryptionService', () {
    test('create backup', () {
      expect(backupJson, isNotEmpty);
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
        backup: backupJson,
        backupKey: key,
      );

      expect(utf8.encode(restoredSecret), secret);
    });

    // test('restore', () {
    //   final secret = utf8.encode('Super Secret!');
    //   final mnemonic =
    //       'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
    //   final derivationPath = "m/1999'/0'"; // this is an example path

    //   final backupJson = BackupService.createBackupWithBIP85(
    //     secret: secret,
    //     mnemonic: mnemonic,
    //     derivationPath: derivationPath,
    //     language: 'english', // optional
    //     network: 'mainnet', // optional
    //   );

    //   final restoredSecret = BackupService.restoreBackupFromBip85(
    //     backup: backupJson,
    //     mnemonic: mnemonic,
    //     derivationPath: derivationPath,
    //     language: 'english', // optional
    //     network: 'mainnet', // optional
    //   );
    //   assert(utf8.encode(restoredSecret) == secret);
    // });
  });
}
