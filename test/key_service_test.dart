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
  final keyService = KeyService(
    keyServer: secretServer,
    keyServerPublicKey:
        '6a04ab98d9e4774ad806e302dddeb63bea16b5cb5f223ee77478e861bb583eb3',
  );

  group('KeyService', () {
    test('info', () async {
      final info = await keyService.serverInfo();

      expect(info.cooldown, isNotNull);
      expect(info.cooldown, isPositive);
      expect(info.canary, '🐦');
      expect(info.secretMaxLength, isNotNull);
      expect(info.secretMaxLength, isPositive);
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
      final backupIdForFetchTest = HEX.encode(generateRandomBytes(length: 32));

      await keyService.storeBackupKey(
        backupId: backupIdForFetchTest,
        password: password,
        backupKey: backupKey,
        salt: HEX.decode(backup.salt),
      );

      final backupKeyRecovered = await keyService.fetchBackupKey(
        backupId: backupIdForFetchTest,
        password: password,
        salt: HEX.decode(backup.salt),
      );
      expect(backupKey, backupKeyRecovered);
    });

    test('trash', () async {
      final backupIdForTrashTest = HEX.encode(generateRandomBytes(length: 32));

      await keyService.storeBackupKey(
        backupId: backupIdForTrashTest,
        password: password,
        backupKey: backupKey,
        salt: HEX.decode(backup.salt),
      );

      final trashedBackupKey = await keyService.trashBackupKey(
        backupId: backupIdForTrashTest,
        password: password,
        salt: HEX.decode(backup.salt),
      );
      expect(backupKey, trashedBackupKey);

      expect(
        () async => await keyService.fetchBackupKey(
          backupId: backupIdForTrashTest,
          password: password,
          salt: HEX.decode(backup.salt),
        ),
        throwsException,
      );
    });
  });
}
