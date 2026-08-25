import 'dart:convert';
import 'dart:collection';

import 'package:hex/hex.dart';
import 'package:recoverbull/recoverbull.dart';
import 'package:recoverbull/src/services/encryption.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final key = HEX.decode(
      'fcb4a38e1d732dede321d13a6ffa024a38ecc4f40c88e9dcc3c9fe51fb942a6f');
  final secret = utf8.encode(
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about');

  final backup = RecoverBull.createBackup(
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
      final restoredSecret = RecoverBull.restoreBackup(
        backup: backup,
        backupKey: key,
      );

      expect(restoredSecret, secret);
    });
  });

  group('BullBackup validation', () {
    String validJson({Map<String, dynamic> overrides = const {}}) {
      final map = <String, dynamic>{
        'version': 1,
        'created_at': 1,
        'id': HEX.encode(List<int>.filled(32, 1)),
        'ciphertext': base64.encode(List<int>.filled(64, 1)),
        'salt': HEX.encode(List<int>.filled(16, 2)),
        'path': null,
      };
      map.addAll(overrides);
      return jsonEncode(map);
    }

    test('writes and accepts format version 1', () {
      expect(jsonDecode(backup.toJson())['version'], 1);
      expect(BullBackup.isValid(backup.toJson()), isTrue);
    });

    test('accepts absent version as legacy v1', () {
      final map = jsonDecode(validJson()) as Map<String, dynamic>;
      map.remove('version');
      expect(BullBackup.isValid(jsonEncode(map)), isTrue);
    });

    test('rejects unknown versions and invalid sizes', () {
      expect(BullBackup.isValid(validJson(overrides: {'version': 2})), isFalse);
      expect(BullBackup.isValid(validJson(overrides: {'id': '00'})), isFalse);
      expect(BullBackup.isValid(validJson(overrides: {'salt': '00'})), isFalse);
      expect(
        BullBackup.isValid(validJson(overrides: {
          'ciphertext': base64.encode(List<int>.filled(63, 1)),
        })),
        isFalse,
      );
      expect(BullBackup.isValid(validJson(overrides: {'path': 1})), isFalse);
    });

    test('rejects JSON larger than the documented limit', () {
      expect(
        BullBackup.isValid(validJson(overrides: {
          'path': 'x' * BullBackup.maxJsonBytes,
        })),
        isFalse,
      );
    });

    test('rejects plaintext above the encrypted container limit before encryption', () {
      expect(
        () => RecoverBull.createBackup(
          secret: _SizedList(BullBackup.maxPlaintextBytes + 1),
          backupKey: key,
        ),
        throwsA(isA<RecoverBullException>()),
      );
    });

    test('round-trips plaintext exactly at the maximum size', () {
      final payload = List<int>.generate(
        BullBackup.maxPlaintextBytes,
        (index) => index % 251,
      );

      final created = RecoverBull.createBackup(
        secret: payload,
        backupKey: key,
      );
      final parsed = BullBackup.fromJson(created.toJson());
      final restored = RecoverBull.restoreBackup(
        backup: parsed,
        backupKey: key,
      );

      expect(restored.length, BullBackup.maxPlaintextBytes);
      expect(restored, payload);
    });
  });
}

class _SizedList extends ListBase<int> {
  _SizedList(this._length);

  final int _length;

  @override
  int get length => _length;

  @override
  set length(int value) => throw UnsupportedError('length is fixed');

  @override
  int operator [](int index) =>
      throw StateError('plaintext was accessed instead of rejected by length');

  @override
  void operator []=(int index, int value) =>
      throw StateError('plaintext was accessed instead of rejected by length');
}
