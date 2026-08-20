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
      expect(status.windowStartedAt, DateTime.parse('2026-08-05T12:17:41Z'));
      expect(status.previousAttemptAt, DateTime.parse('2026-08-05T14:37:22Z'));
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
      expect(
          snapshot.collectionStartedAt, DateTime.parse('2026-08-05T09:00:00Z'));
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
    test('every 429 is rate limited regardless of body', () {
      for (final body in [
        json.encode({'error': 'Too many attempts'}),
        json.encode({'error': 'Unexpected wording', 'details': 42}),
        'plain text response',
      ]) {
        expect(KeyServerException.fromResponse(429, body),
            isA<KeyServerRateLimitedException>());
      }
    });

    test('every 503 is unavailable regardless of body', () {
      for (final body in [
        json.encode({'error': 'Database busy'}),
        json.encode({'error': 'Unexpected wording', 'details': 42}),
        'plain text response',
      ]) {
        expect(KeyServerException.fromResponse(503, body),
            isA<KeyServerUnavailableException>());
      }
    });

    test('other statuses remain generic', () {
      for (final status in [400, 401, 500, 413]) {
        final exception = KeyServerException.fromResponse(
          status,
          json.encode({'error': 'Server message'}),
        );
        expect(exception.runtimeType, KeyServerException);
        expect(exception.code, status);
      }
    });

    test('human message and telemetry fields are preserved', () {
      final exception = KeyServerException.fromResponse(
        429,
        json.encode({
          'error': 'Too many attempts',
          'requested_at': '2026-08-05T14:37:22Z',
          'rate_limit_cooldown': 1440,
          'attempts': 3,
        }),
      );

      expect(exception.message, 'Too many attempts');
      expect(exception.attempts, 3);
      expect(exception.cooldownInMinutes, 1440);
    });

    test('a non-JSON body does not crash the mapping', () {
      final exception = KeyServerException.fromResponse(
        413,
        'Failed to buffer the request body: length limit exceeded',
      );
      expect(exception.code, 413);
      expect(exception.message, contains('length limit exceeded'));
    });

    group('retryAfter parsing', () {
      test('preserves valid delay-seconds on 429', () {
        final exception = KeyServerException.fromResponse(
          429,
          json.encode({'error': 'Too many attempts'}),
          retryAfterHeader: '90',
        );
        expect(exception, isA<KeyServerRateLimitedException>());
        expect(exception.retryAfter, const Duration(seconds: 90));
      });

      test('preserves valid delay-seconds on 503', () {
        final exception = KeyServerException.fromResponse(
          503,
          json.encode({'error': 'Unavailable'}),
          retryAfterHeader: '3',
        );
        expect(exception, isA<KeyServerUnavailableException>());
        expect(exception.retryAfter, const Duration(seconds: 3));
      });

      test('an absent header yields null', () {
        final exception = KeyServerException.fromResponse(
            429, json.encode({'error': 'Too many attempts'}));
        expect(exception.retryAfter, isNull);
      });

      test('zero is distinct from an absent header', () {
        final exception = KeyServerException.fromResponse(
          429,
          json.encode({'error': 'Too many attempts'}),
          retryAfterHeader: '0',
        );
        expect(exception.retryAfter, Duration.zero);
      });

      for (final invalidHeader in [
        '',
        'not-a-number',
        '-5',
        'Wed, 19 Aug 2026 12:00:00 GMT'
      ]) {
        test('invalid Retry-After "$invalidHeader" yields null', () {
          final exception = KeyServerException.fromResponse(
            429,
            json.encode({'error': 'Too many attempts'}),
            retryAfterHeader: invalidHeader,
          );
          expect(exception.retryAfter, isNull);
        });
      }
    });
  });
}
