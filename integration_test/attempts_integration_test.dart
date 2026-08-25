import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:hex/hex.dart';
import 'package:recoverbull/recoverbull.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration tests against a real key server (KEY_SERVER in .env).
/// The server must run with a short RATE_LIMIT_COOLDOWN (1 minute).
void main() async {
  final env = DotEnv(includePlatformEnvironment: true)..load();
  final envSecretServer = env['KEY_SERVER'];
  if (envSecretServer == null) {
    throw Exception('please set KEY_SERVER in a .env');
  }

  final keyService = KeyServer(
    address: Uri.parse(envSecretServer),
    client: HttpClient(),
  );

  final backupKey = HEX.decode(
      'fcb4a38e1d732dede321d13a6ffa024a38ecc4f40c88e9dcc3c9fe51fb942a6f');
  final password = utf8.encode('PasswØrd');
  final salt = generateRandomBytes(length: 16);

  group('telemetry integration', () {
    test('infos exposes the telemetry metadata', () async {
      final info = await keyService.infos();

      expect(info.attemptsCollectionStartedAt, isNotNull);
      expect(info.maxAttemptIdentifiers, isNotNull);
      expect(info.maxAttemptIdentifiers, isPositive);
    });

    test('infos honors a consumer-provided expected canary', () async {
      // the real canary passes
      await keyService.infos(expectedCanary: '🐦');

      // any other expectation raises the alarm
      expect(
        () => keyService.infos(expectedCanary: '🐦‍⬛'),
        throwsA(isA<KeyServerException>()),
      );
    });

    test('fetchBackupKeyWithStatus returns exact attempt counters', () async {
      final backupId = generateRandomBytes(length: 32);

      await keyService.storeBackupKey(
        backupId: backupId,
        password: password,
        backupKey: backupKey,
        salt: salt,
      );

      final result = await keyService.fetchBackupKeyWithStatus(
        backupId: backupId,
        password: password,
        salt: salt,
      );

      expect(result.backupKey, backupKey);
      final status = result.attemptStatus;
      expect(status, isNotNull);
      expect(status!.totalAttempts, greaterThanOrEqualTo(1));
      expect(status.failedAttempts, 0);
      expect(status.resetsAt.isAfter(status.windowStartedAt), isTrue);
    });

    test('attempts publishes failed lookups for a known identifier', () async {
      final backupId = generateRandomBytes(length: 32);

      // one failed lookup (no row exists for this key)
      try {
        await keyService.fetchBackupKey(
          backupId: backupId,
          password: utf8.encode('wrong-password'),
          salt: salt,
        );
        fail('expected a KeyServerException');
      } on KeyServerException {
        // expected: 401
      }

      // The snapshot is rebuilt at most once per TTL (1s on the test
      // server): poll until the fresh build includes the new entry.
      AttemptsModified? modified;
      for (var i = 0; i < 20; i++) {
        final result = await keyService.attempts(backupIds: [backupId]);
        if (result is AttemptsModified && result.matchingEntries.isNotEmpty) {
          modified = result;
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }

      expect(modified, isNotNull, reason: 'entry never appeared in /attempts');
      expect(modified!.etag, isNotNull);
      expect(modified.matchingEntries, hasLength(1));
      expect(modified.matchingEntries.single.totalAttempts, 1);
      expect(modified.matchingEntries.single.failedAttempts, 1);
      expect(
        modified.matchingEntries.single.idHash,
        attemptsIdHash(backupId),
      );
    });

    test('attempts revalidates with the ETag (304)', () async {
      final backupId = generateRandomBytes(length: 32);

      try {
        await keyService.fetchBackupKey(
          backupId: backupId,
          password: utf8.encode('wrong-password'),
          salt: salt,
        );
      } on KeyServerException {
        // expected: 401
      }

      final first = await keyService.attempts(backupIds: [backupId]);
      expect(first, isA<AttemptsModified>());
      final etag = (first as AttemptsModified).etag;
      expect(etag, isNotNull);

      // immediately after, the snapshot is unchanged: the server must answer
      // 304 without a body
      final second = await keyService.attempts(etag: etag, backupIds: [backupId]);
      expect(second, isA<AttemptsNotModified>());
    });

    test('exhausting the budget throws KeyServerRateLimitedException',
        () async {
      final backupId = generateRandomBytes(length: 32);

      // RATE_LIMIT_MAX_FAILED_ATTEMPTS is 3 on the test server
      for (var i = 0; i < 3; i++) {
        try {
          await keyService.fetchBackupKey(
            backupId: backupId,
            password: utf8.encode('wrong-password'),
            salt: salt,
          );
          fail('expected a KeyServerException');
        } on KeyServerException catch (e) {
          expect(e, isNot(isA<KeyServerRateLimitedException>()));
        }
      }

      // the fourth lookup is rejected by the targeted per-identifier lockout
      try {
        await keyService.fetchBackupKey(
          backupId: backupId,
          password: utf8.encode('wrong-password'),
          salt: salt,
        );
        fail('expected a KeyServerRateLimitedException');
      } on KeyServerRateLimitedException catch (e) {
        expect(e.attempts, 3);
        expect(e.cooldownInMinutes, isNotNull);
      }
    });

    test('trashBackupKeyWithStatus deletes and reports counters', () async {
      final backupId = generateRandomBytes(length: 32);

      await keyService.storeBackupKey(
        backupId: backupId,
        password: password,
        backupKey: backupKey,
        salt: salt,
      );

      final result = await keyService.trashBackupKeyWithStatus(
        backupId: backupId,
        password: password,
        salt: salt,
      );

      expect(result.backupKey, backupKey);
      expect(result.attemptStatus, isNotNull);

      // the row is gone: a new fetch fails
      expect(
        () => keyService.fetchBackupKey(
          backupId: backupId,
          password: password,
          salt: salt,
        ),
        throwsA(isA<KeyServerException>()),
      );
    });
  });
}
