// ignore_for_file: constant_identifier_names

import 'dart:typed_data';

import 'package:recoverbull/recoverbull.dart';
import 'package:pointycastle/export.dart';
import 'package:recoverbull/src/models/exceptions.dart';

/// Service handling encryption and decryption operations
class EncryptionService {
  static const _16bytes = 16;
  static const _32bytes = 32;

  /// Encrypts data
  static ({List<int> ciphertext, List<int> nonce, List<int> mac}) encrypt({
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

    final mac = _mac(ciphertext: ciphertext, key: key, nonce: nonce);

    return (ciphertext: ciphertext, nonce: nonce, mac: mac);
  }

  /// Decrypts data
  static List<int> decrypt({
    required List<int> key,
    required List<int> ciphertext,
    required List<int> nonce,
    List<int>? mac,
  }) {
    final computedMac = _mac(nonce: nonce, key: key, ciphertext: ciphertext);

    if (mac != null && constantTimeComparison(computedMac, mac) == false) {
      throw EncryptionException('Invalid MAC');
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

  static List<int> _mac({
    required List<int> nonce,
    required List<int> key,
    required List<int> ciphertext,
  }) {
    final u8nonce = Uint8List.fromList(nonce);
    final u8key = Uint8List.fromList(key);
    final u8ciphertext = Uint8List.fromList(ciphertext);

    final hmac = HMac(SHA256Digest(), 64);
    hmac.init(KeyParameter(u8key));
    hmac.update(u8nonce, 0, u8nonce.length);
    hmac.update(u8ciphertext, 0, u8ciphertext.length);
    final mac = Uint8List(_32bytes);
    hmac.doFinal(mac, 0);
    return mac;
  }

  static void _validateNonce(List<int> nonce) {
    if (nonce.length != _16bytes) {
      throw EncryptionException(
        'Invalid IV length',
        'Expected $_16bytes bytes, got ${nonce.length}',
      );
    }
  }

  static void _validateKey(List<int> key) {
    if (key.length != _32bytes) {
      throw EncryptionException(
        'Invalid IV length',
        'Expected $_32bytes bytes, got ${key.length}',
      );
    }
  }
}
