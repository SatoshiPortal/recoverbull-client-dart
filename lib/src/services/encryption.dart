import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:recoverbull_dart/src/models/encryption_data.dart';

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
  // Use a constant-time algorithm to prevent timing attacks
  static final _algorithm = AesGcm.with256bits();

  // Minimum requirements for security
  static const _minKeyLength = 32; // 256 bits
  static const _minDataLength = 1;
  static const _maxDataLength = 100 * 1024 * 1024; // 100MB limit

  /// Encrypts data using AES-GCM
  ///
  /// Parameters:
  /// - [plaintext]: Data to encrypt
  /// - [key]: 256-bit encryption key
  static Future<EncryptionData> encrypt(
    List<int> plaintext,
    List<int> key,
  ) async {
    try {
      // Validate inputs
      _validateKey(key);
      _validateData(plaintext);

      final secretKey = SecretKey(key);
      // Generate cryptographically secure nonce
      final nonce = _algorithm.newNonce();

      // Use try-finally to ensure sensitive data is cleared
      try {
        final result = await _algorithm.encrypt(
          plaintext,
          secretKey: secretKey,
          nonce: nonce,
        );

        return EncryptionData(
          ciphertext: result.cipherText,
          nonce: nonce,
          tag: result.mac.bytes,
        );
      } finally {
        // Clear sensitive data from memory
        _secureClose(key);
      }
    } catch (e) {
      final error = 'Encryption failed';
      debugPrint('$error: $e');
      throw EncryptionException(error, e);
    }
  }

  /// Decrypts data using AES-GCM
  ///
  /// Parameters:
  /// - [ciphertext]: Encrypted data
  /// - [nonce]: Initialization vector
  /// - [tag]: Authentication tag
  /// - [key]: 256-bit decryption key
  static Future<List<int>> decrypt({
    required List<int> ciphertext,
    required List<int> nonce,
    required List<int> tag,
    required List<int> key,
  }) async {
    try {
      // Validate inputs
      _validateKey(key);
      _validateData(ciphertext);
      _validateNonce(nonce);
      _validateTag(tag);

      final secretKey = SecretKey(key);

      try {
        final secretBox = SecretBox(
          ciphertext,
          nonce: nonce,
          mac: Mac(tag),
        );

        final plaintext = await _algorithm.decrypt(
          secretBox,
          secretKey: secretKey,
        );

        // Validate decrypted data
        _validateData(plaintext);

        return plaintext;
      } finally {
        // Clear sensitive data from memory
        _secureClose(key);
      }
    } catch (e) {
      final error = 'Decryption failed';
      debugPrint('$error: $e');
      throw EncryptionException(error, e);
    }
  }

  /// Validates encryption key
  static void _validateKey(List<int> key) {
    if (key.isEmpty) {
      throw EncryptionException('Encryption key cannot be empty');
    }
    if (key.length != _minKeyLength) {
      throw EncryptionException(
          'Invalid key length. Required: $_minKeyLength bytes');
    }
  }

  /// Validates data size
  static void _validateData(List<int> data) {
    if (data.isEmpty) {
      throw EncryptionException('Data cannot be empty');
    }
    if (data.length < _minDataLength) {
      throw EncryptionException('Data too small');
    }
    if (data.length > _maxDataLength) {
      throw EncryptionException('Data exceeds maximum size limit');
    }
  }

  /// Validates nonce
  static void _validateNonce(List<int> nonce) {
    if (nonce.isEmpty || nonce.length != _algorithm.nonceLength) {
      throw EncryptionException('Invalid nonce length');
    }
  }

  /// Validates authentication tag
  static void _validateTag(List<int> tag) {
    if (tag.isEmpty) {
      throw EncryptionException('Authentication tag cannot be empty');
    }
  }

  /// Securely clears sensitive data from memory
  static void _secureClose(List<int> sensitiveData) {
    // Overwrite with zeros
    for (var i = 0; i < sensitiveData.length; i++) {
      sensitiveData[i] = 0;
    }
    // Optional: additional passes with random data
    final random = Random.secure();
    for (var i = 0; i < sensitiveData.length; i++) {
      sensitiveData[i] = random.nextInt(256);
    }
  }
}
