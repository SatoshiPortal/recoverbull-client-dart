import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:recoverbull_dart/src/models/encrypted_data.dart';
import 'package:pointycastle/export.dart';

/// Custom exception for encryption operations
class EncryptionException implements Exception {
  final String message;
  final dynamic cause;

  EncryptionException(this.message, [this.cause]);

  @override
  String toString() =>
      'EncryptionException: $message${cause != null ? ' ($cause)' : ''}';
}

/// Service handling encryption and decryption operations
class EncryptionService {
  // Security constants
  static const _minDataLength = 1;
  static const _maxDataLength = 100 * 1024 * 1024; // 100MB limit
  static const _ivLength = 16;
  static const _macLength = 32;

  static void _validateData(List<int> data) {
    if (data.length < _minDataLength || data.length > _maxDataLength) {
      throw EncryptionException(
        'Invalid data length',
        'Must be between $_minDataLength and $_maxDataLength bytes',
      );
    }
  }

  static void _validateIV(List<int> iv) {
    if (iv.length != _ivLength) {
      throw EncryptionException(
        'Invalid IV length',
        'Expected $_ivLength bytes, got ${iv.length}',
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

  /// Encrypts data using AES-CBC with PKCS7 padding
  static Future<EncryptedData> aesEncrypt(
    Uint8List keyBytes,
    Uint8List plaintext,
  ) async {
    // try {
    // Validate inputs

    _validateData(plaintext);

    // Generate random IV
    final iv = generateSecureRandomBytes(_ivLength);

    final params = PaddedBlockCipherParameters(
      ParametersWithIV(KeyParameter(keyBytes), iv),
      null,
    );
    final paddedBlockCipher = PaddedBlockCipher('AES/CBC/PKCS7')
      ..init(true, params);
    // Encrypt the data
    final inputData = Uint8List.fromList(plaintext);
    final ciphertext = paddedBlockCipher.process(inputData);

    // Generate MAC
    final hmac = HMac(SHA256Digest(), 64);
    hmac.init(KeyParameter(keyBytes));
    hmac.update(iv, 0, iv.length);
    hmac.update(ciphertext, 0, ciphertext.length);
    final mac = Uint8List(_macLength);
    hmac.doFinal(mac, 0);
    return EncryptedData(
      ciphertext: HEX.encode(ciphertext),
      nonce: HEX.encode(iv),
      tag: HEX.encode(mac),
    );
  }

  /// Decrypts data using AES-CBC with PKCS7 padding
  static Future<List<int>> decrypt({
    required Uint8List keyBytes,
    required Uint8List ciphertext,
    required Uint8List iv,
    Uint8List? mac,
  }) async {
    // Excerpt from: class EncryptionService
    _validateData(ciphertext);
    _validateIV(iv);
    // Only validate MAC if it's not null
    if (mac != null) {
      _validateMAC(mac);
    }

    try {
      // Verify MAC if present
      if (mac != null) {
        final hmac = HMac(SHA256Digest(), 64);
        hmac.init(KeyParameter(keyBytes));
        hmac.update(iv, 0, iv.length);
        hmac.update(ciphertext, 0, ciphertext.length);

        final calculatedMac = Uint8List(_macLength);
        hmac.doFinal(calculatedMac, 0);

        // // Constant-time comparison
        // if (!_constantTimeEquals(mac, calculatedMac)) {
        //   throw EncryptionException('MAC verification failed', null);
        // }
      }
      final params = PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(keyBytes), iv),
        null,
      );
      final paddedBlockCipher = PaddedBlockCipher('AES/CBC/PKCS7')
        ..init(false, params);

      // Decrypt the data
      final decrypted =
          paddedBlockCipher.process(Uint8List.fromList(ciphertext));

      // Validate decrypted data
      _validateData(decrypted);

      return decrypted;
    } catch (e) {
      final error = 'AES/CBC/PKCS7 decryption failed';
      throw EncryptionException(error, e);
    } finally {
      _secureClose(keyBytes);
    }
  }

  // Constant-time comparison to prevent timing attacks
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}

Uint8List generateSecureRandomBytes(int length) {
  final secureRandom = Random.secure();
  final randomIV = Uint8List(length);
  for (int i = 0; i < length; i++) {
    randomIV[i] = secureRandom.nextInt(256);
  }
  return randomIV;
}

List<int> sha256(List<int> input) {
  return SHA256Digest().process(Uint8List.fromList(input));
}
