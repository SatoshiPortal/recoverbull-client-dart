import 'dart:convert';

import 'package:dotenv/dotenv.dart';
import 'package:hex/hex.dart';
import 'package:recoverbull/recoverbull.dart';
import 'package:test/test.dart';

void main() {
  final backupKey = HEX.decode(
      'fcb4a38e1d732dede321d13a6ffa024a38ecc4f40c88e9dcc3c9fe51fb942a6f');
  final secret = utf8.encode(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about');

  final backupJson = BackupService.createBackup(
    secret: secret,
    backupKey: backupKey,
  );
  final backup = Backup.fromJson(backupJson);

  final env = DotEnv(includePlatformEnvironment: true)..load();
  final envSecretServer = env['SECRET_SERVER'];
  if (env['SECRET_SERVER'] == null) {
    throw Exception('please set SECRET_SERVER in a .env');
  }

  final secretServer = Uri.parse(envSecretServer!);
  final password = "PasswØrd";
  final keyService = KeyService(keyServer: secretServer);

  group('EncryptionService', () {
    test('info', () async {
      final response = await keyService.serverInfo();

      expect(response['cooldown'], isNotNull);
      expect(response['cooldown'], isPositive);
      expect(response['message'], isNotNull);
      expect(response['message'], isNotEmpty);
      expect(response['secret_max_length'], isNotNull);
      expect(response['secret_max_length'], isPositive);
      expect(response['timestamp'], isNotNull);
      expect(response['timestamp'], isPositive);
    });
    test('store', () async {
      expect(
          () async => await keyService.storeBackupKey(
                backupId: backup.id,
                password: password,
                backupKey: backupKey,
                salt: HEX.decode(backup.salt),
              ),
          returnsNormally);
    });

    test('fetch', () async {
      final backupIdForFetchTest = HEX.encode(generateRandomBytes());
      await keyService.storeBackupKey(
        backupId: backupIdForFetchTest,
        password: password,
        backupKey: backupKey,
        salt: HEX.decode(backup.salt),
      );

      final backupKeyRecovered = await keyService.recoverBackupKey(
        backupId: backupIdForFetchTest,
        password: password,
        salt: HEX.decode(backup.salt),
      );
      expect(backupKey, backupKeyRecovered);
    });
  });
}
