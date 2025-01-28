import 'dart:typed_data';

import 'package:hex/hex.dart';
import 'package:recoverbull/recoverbull.dart';
import 'package:recoverbull/src/models/encryption_result.dart';
import 'package:pointycastle/export.dart';
import 'package:recoverbull/src/models/exceptions.dart';

/// Service handling encryption and decryption operations
class EncryptionService {
  static const _ivLength = 16;
  static const _macLength = 32;

  /// Encrypts data using AES-CBC with PKCS7 padding
  static Future<EncryptionResult> encrypt(
    List<int> keyBytes,
    List<int> plaintext,
  ) async {
    try {
      final nonce = Uint8List.fromList(generateRandomBytes(length: _ivLength));

      final params = PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(Uint8List.fromList(keyBytes)), nonce),
        null,
      );

      final paddedBlockCipher = PaddedBlockCipher('AES/CBC/PKCS7')
        ..init(true, params);

      final ciphertext =
          paddedBlockCipher.process(Uint8List.fromList(plaintext));

      final hmac = HMac(SHA256Digest(), 64);
      hmac.init(KeyParameter(Uint8List.fromList(keyBytes)));
      hmac.update(nonce, 0, nonce.length);
      hmac.update(ciphertext, 0, ciphertext.length);
      final mac = Uint8List(_macLength);
      hmac.doFinal(mac, 0);

      return EncryptionResult(
        ciphertext: HEX.encode(ciphertext),
        nonce: HEX.encode(nonce),
        mac: HEX.encode(mac),
      );
    } catch (e) {
      final error = 'AES/CBC/PKCS7 decryption failed';
      throw EncryptionException(error, e);
    } finally {
      _secureClose(keyBytes);
    }
  }

  /// Decrypts data using AES-CBC with PKCS7 padding
  static Future<List<int>> decrypt({
    required List<int> keyBytes,
    required List<int> ciphertext,
    required List<int> nonce,
    List<int>? mac,
  }) async {
    _validateIV(nonce);
    if (mac != null) _validateMAC(mac);

    try {
      if (mac != null) {
        final hmac = HMac(SHA256Digest(), 64);
        hmac.init(KeyParameter(Uint8List.fromList(keyBytes)));
        hmac.update(Uint8List.fromList(nonce), 0, nonce.length);
        hmac.update(Uint8List.fromList(ciphertext), 0, ciphertext.length);

        final calculatedMac = Uint8List(_macLength);
        hmac.doFinal(calculatedMac, 0);

        if (!constantTimeComparison(mac, calculatedMac)) {
          throw EncryptionException('MAC verification failed', null);
        }
      }

      final params = PaddedBlockCipherParameters(
        ParametersWithIV(
          KeyParameter(Uint8List.fromList(keyBytes)),
          Uint8List.fromList(nonce),
        ),
        null,
      );

      final paddedBlockCipher = PaddedBlockCipher('AES/CBC/PKCS7')
        ..init(false, params);

      final decrypted =
          paddedBlockCipher.process(Uint8List.fromList(ciphertext));

      return decrypted;
    } catch (e) {
      final error = 'AES/CBC/PKCS7 decryption failed';
      throw EncryptionException(error, e);
    } finally {
      _secureClose(keyBytes);
    }
  }

  static void _validateIV(List<int> nonce) {
    if (nonce.length != _ivLength) {
      throw EncryptionException(
        'Invalid IV length',
        'Expected $_ivLength bytes, got ${nonce.length}',
      );
    }
  }

  static void _validateMAC(List<int> mac) {
    if (mac.length != _macLength) {
      throw EncryptionException(
        'Invalid MAC length',
        'Expected $_macLength bytes, got ${mac.length}',
      );
    }
  }

  static void _secureClose(List<int> data) {
    for (var i = 0; i < data.length; i++) {
      data[i] = 0;
    }
  }
}
