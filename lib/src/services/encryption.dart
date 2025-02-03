// ignore_for_file: constant_identifier_names

import 'dart:typed_data';

import 'package:recoverbull/recoverbull.dart';
import 'package:pointycastle/export.dart';
import 'package:recoverbull/src/models/exceptions.dart';

typedef Encryption = ({
  List<int> nonce,
  List<int> ciphertext,
  List<int> hmac,
});

/// Service handling encryption and decryption operations
class EncryptionService {
  static const _16bytes = 16;
  static const _32bytes = 32;

  /// Encrypts data
  static Encryption encrypt({
    required List<int> key,
    required List<int> plaintext,
  }) {
    final nonce = generateRandomBytes(length: _16bytes);

    final ciphertext = _encryption(
      payload: plaintext,
      key: key,
      nonce: nonce,
      isEncrypt: true,
    );

    final hmac = computeHMac(ciphertext: ciphertext, key: key, nonce: nonce);

    return (nonce: nonce, ciphertext: ciphertext, hmac: hmac);
  }

  /// Decrypts data
  static List<int> decrypt({
    required List<int> key,
    required List<int> ciphertext,
    required List<int> nonce,
    List<int>? hmac,
  }) {
    final computedHMac =
        computeHMac(nonce: nonce, key: key, ciphertext: ciphertext);

    if (hmac != null && constantTimeComparison(computedHMac, hmac) == false) {
      throw EncryptionException('Invalid HMac');
    }

    final plaintext = _encryption(
      payload: ciphertext,
      key: key,
      nonce: nonce,
      isEncrypt: false,
    );
    return plaintext;
  }

  static List<int> _encryption({
    required List<int> key,
    required List<int> nonce,
    required List<int> payload,
    required bool isEncrypt,
  }) {
    _validateNonce(nonce);
    _validateKey(key);

    try {
      final params = ParametersWithIV(
        KeyParameter(Uint8List.fromList(key)),
        Uint8List.fromList(nonce),
      );
      final paddingParams = PaddedBlockCipherParameters(params, null);
      final cipher = CBCBlockCipher(AESEngine());
      final paddingCipher = PaddedBlockCipherImpl(PKCS7Padding(), cipher)
        ..init(isEncrypt, paddingParams);
      final input = Uint8List.fromList(payload);

      return paddingCipher.process(input);
    } catch (e) {
      final error = 'AES/CBC/PKCS7 encryption failed';
      throw EncryptionException(error, e);
    }
  }

  static List<int> computeHMac({
    required List<int> nonce,
    required List<int> key,
    required List<int> ciphertext,
  }) {
    final u8nonce = Uint8List.fromList(nonce);
    final u8key = Uint8List.fromList(key);
    final u8ciphertext = Uint8List.fromList(ciphertext);

    final hmacSha256 = HMac(SHA256Digest(), 64);
    hmacSha256.init(KeyParameter(u8key));
    hmacSha256.update(u8nonce, 0, u8nonce.length);
    hmacSha256.update(u8ciphertext, 0, u8ciphertext.length);
    final hmac = Uint8List(_32bytes);
    hmacSha256.doFinal(hmac, 0);
    return hmac;
  }

  static void _validateNonce(List<int> nonce) {
    if (nonce.length != _16bytes) {
      throw EncryptionException(
        'Invalid nonce length',
        'Expected $_16bytes bytes, got ${nonce.length}',
      );
    }
  }

  static void _validateHMac(List<int> hmac) {
    if (hmac.length != _32bytes) {
      throw EncryptionException(
        'Invalid HMac length',
        'Expected $_16bytes bytes, got ${hmac.length}',
      );
    }
  }

  static void _validateKey(List<int> key) {
    if (key.length != _32bytes) {
      throw EncryptionException(
        'Invalid Key length',
        'Expected $_32bytes bytes, got ${key.length}',
      );
    }
  }

  static List<int> mergeBytes(Encryption encryption) {
    _validateNonce(encryption.nonce);
    _validateHMac(encryption.hmac);

    return [
      ...encryption.nonce, // first 16 bytes
      ...encryption.ciphertext,
      ...encryption.hmac // last 32 bytes
    ];
  }

  static Encryption splitBytes(List<int> bytes) {
    // Extract the nonce (first 16 bytes)
    final List<int> nonce = bytes.sublist(0, 16);

    // Extract the HMAC (last 32 bytes)
    final List<int> hmac = bytes.sublist(bytes.length - 32);

    // Extract the ciphertext (bytes between the nonce and MAC)
    final List<int> ciphertext = bytes.sublist(16, bytes.length - 32);

    _validateNonce(nonce);
    _validateHMac(hmac);

    return (nonce: nonce, ciphertext: ciphertext, hmac: hmac);
  }
}
