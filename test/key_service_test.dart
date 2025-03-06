import 'dart:convert';

import 'package:dotenv/dotenv.dart';
import 'package:hex/hex.dart';
import 'package:recoverbull/recoverbull.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  final backupKey = HEX.decode(
      'fcb4a38e1d732dede321d13a6ffa024a38ecc4f40c88e9dcc3c9fe51fb942a6f');
  final secret = utf8.encode(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about');
  final keyServerPublicKey =
      '6a04ab98d9e4774ad806e302dddeb63bea16b5cb5f223ee77478e861bb583eb3';
  final password = "PasswØrd";

  final backup = BackupService.createBackup(
    secret: secret,
    backupKey: backupKey,
  );

  final env = DotEnv(includePlatformEnvironment: true)..load();
  final envSecretServer = env['SECRET_SERVER'];
  if (env['SECRET_SERVER'] == null) {
    throw Exception('please set SECRET_SERVER in a .env');
  }

  final keyServerUri = Uri.parse(envSecretServer!);
  // final tld = keyServerUri.host.split('.').last;
  // Tor? tor;
  // if (tld == 'onion') {
  //   await Tor.init();
  //   await Tor.instance.start(); // start the proxy
  //   tor = Tor.instance;
  // }

  final keyService = KeyService(
    keyServer: keyServerUri,
    keyServerPublicKey: keyServerPublicKey,
    // tor: tor,
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

  test('store fail', () async {
    try {
      await keyService.fetchBackupKey(backupId: 'a', password: 'a', salt: []);
    } on KeyServiceException catch (e) {
      expect(e.message,
          'identifier or authentication_key are not 256 bits HEX hashes');
      return;
    }
    throw Exception("Expected failure");
  });

  test('fetch rate-limit', () async {
    try {
      await keyService.fetchBackupKey(
        backupId: backup.id,
        password: 'invalid',
        salt: [],
      );
    } on KeyServiceException catch (e) {
      expect(e.cooldownInMinutes, isNotNull);
      expect(e.requestedAt, isNotNull);
      expect(e.message, isNotEmpty);
      return;
    }
    throw Exception("Expected failure");
  });
}
