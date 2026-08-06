import 'dart:convert';

import 'package:hex/hex.dart';
import 'package:recoverbull/recoverbull.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('attemptsIdHash', () {
    // Shared test vector with the server implementation: SHA-256 over the
    // raw identifier bytes (not the hex string). Must match byte-for-byte.
    test('matches the server algorithm on the shared vector', () {
      const identifier =
          'bcb15f821479b4d5772bd0ca866c00ad5f926e3580720659cc80d39c9d09802a';
      const expectedIdHash =
          'f5bb872a08ef929e6744d117a69d4073ee7b5df4f5d7a4ecdd606f30a58f76db';

      expect(attemptsIdHash(HEX.decode(identifier)), expectedIdHash);
      expect(attemptsIdHashFromHex(identifier), expectedIdHash);
    });
  });

  group('AttemptStatus', () {
    test('parses the exact server response shape', () {
      final status = AttemptStatus.fromMap({
        'total_attempts': 3,
        'failed_attempts': 1,
        'remaining_attempts': 0,
        'window_started_at': '2026-08-05T12:17:41Z',
        'previous_attempt_at': '2026-08-05T14:37:22Z',
        'resets_at': '2026-08-06T15:04:13Z',
      });

      expect(status.totalAttempts, 3);
      expect(status.failedAttempts, 1);
      expect(status.remainingAttempts, 0);
      expect(status.windowStartedAt,
          DateTime.parse('2026-08-05T12:17:41Z'));
      expect(status.previousAttemptAt,
          DateTime.parse('2026-08-05T14:37:22Z'));
      expect(status.resetsAt, DateTime.parse('2026-08-06T15:04:13Z'));
    });

    test('tolerates a null previous_attempt_at (first attempt of a window)',
        () {
      final status = AttemptStatus.fromMap({
        'total_attempts': 1,
        'failed_attempts': 0,
        'remaining_attempts': 2,
        'window_started_at': '2026-08-05T12:17:41Z',
        'previous_attempt_at': null,
        'resets_at': '2026-08-06T12:17:41Z',
      });

      expect(status.previousAttemptAt, isNull);
    });
  });

  group('AttemptsSnapshot', () {
    final body = json.encode({
      'version': 1,
      'collection_started_at': '2026-08-05T09:00:00Z',
      'entries': [
        {
          'id_hash':
              'f5bb872a08ef929e6744d117a69d4073ee7b5df4f5d7a4ecdd606f30a58f76db',
          'total_attempts': 3,
          'failed_attempts': 1,
          'window_started_at': '2026-08-05T12:00:00Z',
          'last_attempt_at': '2026-08-05T14:00:00Z',
        },
        {
          'id_hash':
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          'total_attempts': 1,
          'failed_attempts': 1,
          'window_started_at': '2026-08-05T13:00:00Z',
          'last_attempt_at': '2026-08-05T13:00:00Z',
        },
      ],
    });

    test('parses the server snapshot shape', () {
      final snapshot = AttemptsSnapshot.parse(body);

      expect(snapshot.version, 1);
      expect(snapshot.collectionStartedAt,
          DateTime.parse('2026-08-05T09:00:00Z'));
      expect(snapshot.entries, hasLength(2));
      expect(snapshot.entries.first.totalAttempts, 3);
    });

    test('entriesMatching returns only locally known identifiers', () {
      final snapshot = AttemptsSnapshot.parse(body);
      const knownIdentifier =
          'bcb15f821479b4d5772bd0ca866c00ad5f926e3580720659cc80d39c9d09802a';

      final matching = snapshot.entriesMatching([HEX.decode(knownIdentifier)]);

      expect(matching, hasLength(1));
      expect(
        matching.single.idHash,
        'f5bb872a08ef929e6744d117a69d4073ee7b5df4f5d7a4ecdd606f30a58f76db',
      );
    });

    test('entriesMatching with no known identifiers returns nothing', () {
      final snapshot = AttemptsSnapshot.parse(body);
      expect(snapshot.entriesMatching(const []), isEmpty);
    });
  });

  group('Info telemetry fields', () {
    test('parses the new fields when present', () {
      final info = Info.fromMap({
        'canary': '🐦',
        'secret_max_length': 128,
        'rate_limit_cooldown': 1440,
        'rate_limit_max_failed_attempts': 3,
        'attempts_collection_started_at': '2026-08-05T09:00:00Z',
        'max_attempt_identifiers': 100000,
      });

      expect(info.attemptsCollectionStartedAt,
          DateTime.parse('2026-08-05T09:00:00Z'));
      expect(info.maxAttemptIdentifiers, 100000);
    });

    test('tolerates their absence against older servers', () {
      final info = Info.fromMap({
        'canary': '🐦',
        'secret_max_length': 128,
        'rate_limit_cooldown': 1440,
        'rate_limit_max_failed_attempts': 3,
      });

      expect(info.attemptsCollectionStartedAt, isNull);
      expect(info.maxAttemptIdentifiers, isNull);
    });
  });

  group('KeyServerException mapping', () {
    test('targeted per-identifier 429 maps to KeyServerRateLimitedException',
        () {
      final e = KeyServerException.fromResponse(
        429,
        json.encode({
          'error': 'Too many attempts',
          'requested_at': '2026-08-05T14:37:22Z',
          'rate_limit_cooldown': 1440,
          'attempts': 3,
        }),
      );

      expect(e, isA<KeyServerRateLimitedException>());
      expect(e.attempts, 3);
      expect(e.cooldownInMinutes, 1440);
    });

    test('global lookup 429 maps to KeyServerOverloadedException', () {
      final e = KeyServerException.fromResponse(
        429,
        json.encode({
          'error': 'Too many lookup requests, please try again later',
        }),
      );

      expect(e, isA<KeyServerOverloadedException>());
      expect(e, isNot(isA<KeyServerRateLimitedException>()));
    });

    test('the /attempts route 429 maps to KeyServerOverloadedException', () {
      final e = KeyServerException.fromResponse(
        429,
        json.encode({
          'error': 'Too many attempts requests, please try again later',
        }),
      );

      expect(e, isA<KeyServerOverloadedException>());
    });

    test('capacity 503 maps to KeyServerCapacityException', () {
      final e = KeyServerException.fromResponse(
        503,
        json.encode({
          'error': 'Rate-limit capacity exhausted, please try again later',
        }),
      );

      expect(e, isA<KeyServerCapacityException>());
    });

    test('busy-database 503 maps to KeyServerUnavailableException', () {
      final e = KeyServerException.fromResponse(
        503,
        json.encode({
          'error': 'Database busy, please try again later',
        }),
      );

      expect(e, isA<KeyServerUnavailableException>());
      expect(e, isNot(isA<KeyServerCapacityException>()));
    });

    test('a non-JSON body does not crash the mapping', () {
      final e = KeyServerException.fromResponse(
        413,
        'Failed to buffer the request body: length limit exceeded',
      );

      expect(e.code, 413);
      expect(e.message, contains('length limit exceeded'));
    });
  });
}
