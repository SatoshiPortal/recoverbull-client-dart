import 'dart:convert';

import 'package:hex/hex.dart';
import 'package:recoverbull/src/models/exceptions.dart';
import 'package:recoverbull/src/services/encryption.dart';
import 'package:test/test.dart';

void main() {
  group('EncryptionService', () {
    final key = HEX.decode(
        'fcb4a38e1d732dede321d13a6ffa024a38ecc4f40c88e9dcc3c9fe51fb942a6f');
    final plaintext = utf8.encode('Hello, Encryption!');

    final encryption = EncryptionService.encrypt(
      key: key,
      plaintext: plaintext,
    );

    test('encrypt and decrypt', () {
      expect(encryption.ciphertext.isNotEmpty, true);
      expect(encryption.nonce.isNotEmpty, true);
      expect(encryption.hmac.isNotEmpty, true);

      final ciphertext = EncryptionService.decrypt(
        key: key,
        ciphertext: encryption.ciphertext,
        nonce: encryption.nonce,
      );

      expect(utf8.decode(ciphertext), equals(utf8.decode(plaintext)));
    });

    test('decrypt with MAC', () {
      final ciphertext = EncryptionService.decrypt(
        key: key,
        ciphertext: encryption.ciphertext,
        nonce: encryption.nonce,
        hmac: encryption.hmac,
      );

      expect(utf8.decode(ciphertext), equals(utf8.decode(plaintext)));
    });

    test('decrypt with INVALID MAC ', () {
      expect(
        () => EncryptionService.decrypt(
          key: key,
          ciphertext: encryption.ciphertext,
          nonce: encryption.nonce,
          hmac: [0],
        ),
        throwsA(isA<EncryptionException>()),
      );
    });
  });
}
