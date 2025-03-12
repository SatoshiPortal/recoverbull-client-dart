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
  final password = utf8.encode("PasswØrd");

  final backup = RecoverBull.createBackup(
    secret: secret,
    backupKey: backupKey,
  );

  final env = DotEnv(includePlatformEnvironment: true)..load();
  final envSecretServer = env['KEY_SERVER'];
  if (env['KEY_SERVER'] == null) {
    throw Exception('please set KEY_SERVER in a .env');
  }

  final keyServerUri = Uri.parse(envSecretServer!);
  // final tld = keyServerUri.host.split('.').last;
  // Tor? tor;
  // if (tld == 'onion') {
  //   await Tor.init();
  //   await Tor.instance.start(); // start the proxy
  //   tor = Tor.instance;
  // }

  final keyService = KeyServer(address: keyServerUri); // tor: tor,

  group('KeyServer', () {
    test('info', () async {
      final info = await keyService.infos();

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
                salt: backup.salt,
              ),
          returnsNormally);
    });

    test('fetch', () async {
      final backupIdForFetchTest = generateRandomBytes(length: 32);

      await keyService.storeBackupKey(
        backupId: backupIdForFetchTest,
        password: password,
        backupKey: backupKey,
        salt: backup.salt,
      );

      final backupKeyRecovered = await keyService.fetchBackupKey(
        backupId: backupIdForFetchTest,
        password: password,
        salt: backup.salt,
      );
      expect(backupKey, backupKeyRecovered);
    });

    test('trash', () async {
      final backupIdForTrashTest = generateRandomBytes(length: 32);

      await keyService.storeBackupKey(
        backupId: backupIdForTrashTest,
        password: password,
        backupKey: backupKey,
        salt: backup.salt,
      );

      final trashedBackupKey = await keyService.trashBackupKey(
        backupId: backupIdForTrashTest,
        password: password,
        salt: backup.salt,
      );
      expect(backupKey, trashedBackupKey);

      expect(
        () async => await keyService.fetchBackupKey(
          backupId: backupIdForTrashTest,
          password: password,
          salt: backup.salt,
        ),
        throwsException,
      );
    });
  });

  test('store fail', () async {
    try {
      await keyService.fetchBackupKey(
        backupId: HEX.decode('a'),
        password: utf8.encode('a'),
        salt: [],
      );
    } on KeyServerException catch (e) {
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
        password: utf8.encode('invalid'),
        salt: [],
      );
    } on KeyServerException catch (e) {
      expect(e.cooldownInMinutes, isNotNull);
      expect(e.requestedAt, isNotNull);
      expect(e.message, isNotEmpty);
      return;
    }
    throw Exception("Expected failure");
  });
}
