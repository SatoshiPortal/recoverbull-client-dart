import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hex/hex.dart';
import 'package:nostr/nostr.dart';
import 'package:recoverbull/src/models/exceptions.dart';
import 'package:recoverbull/src/services/argon2.dart';
import 'package:recoverbull/src/services/encryption.dart';

/// The [KeyService] class provides functionalities to store and recover
/// backup keys securely by interacting with a remote key server API. It handles
/// key derivation, encryption, and communication with the server.
class KeyService {
  final Uri keyServer;
  final String keyServerPublicKey;
  late Dio _client;
  late String _privateKey;

  // Private constructor
  KeyService({
    required this.keyServer,
    required this.keyServerPublicKey,
  }) {
    _privateKey = Keychain.generate().private;
    _client = Dio(BaseOptions(headers: {'Content-Type': 'application/json'}));
  }

  Future<Map<String, dynamic>> serverInfo() async {
    final response = await _client.get('$keyServer/info');
    if (response.statusCode == 200) return response.data;
    throw KeyServiceException.fromResponse(response);
  }

  /// Stores an encryptedBackupKey backup key on the remote key-server.
  ///
  /// Parameters:
  /// - `backupId`: Hex-encoded random bytes
  /// - `password`: The password used for key derivation.
  /// - `backupKey`: The bytes of the backup key
  /// - `salt`: The bytes of the salt used in key derivation.
  Future<void> storeBackupKey({
    required String backupId,
    required String password,
    required List<int> backupKey,
    required List<int> salt,
  }) async {
    try {
      final derivatedKeys = Argon2.computeTwoKeysFromPassword(
        password: password,
        salt: salt,
        length: 32,
      );
      if (derivatedKeys.$1.length != 32 || derivatedKeys.$2.length != 32) {
        throw KeyServiceException(
            message: 'Each key should have the same length');
      }
      // authentication key will be consumed by the key server
      final authenticationKey = derivatedKeys.$1;
      // encryption key will cipher the secret before storage on the key server.
      final encryptionKey = derivatedKeys.$2;

      // Encrypt the backupKey using the encryption key
      final backupKeyEncryption = EncryptionService.encrypt(
        key: encryptionKey,
        plaintext: backupKey,
      );
      final encryptedBackupKey =
          EncryptionService.mergeBytes(backupKeyEncryption);

      final response = await _postEncryptedBody('store', {
        'identifier': backupId,
        'authentication_key': HEX.encode(authenticationKey),
        'encrypted_secret': base64.encode(encryptedBackupKey),
      });

      if (response.statusCode == 201) return;

      throw KeyServiceException.fromResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Recovers an encryptedBackupKey backup key from the key server.
  ///
  /// Parameters:
  /// - `backupId`: Hex-encoded random bytes
  /// - `password`: The password used for key derivation.
  /// - `backupKey`: The bytes of the backup key
  /// - `salt`: The bytes of the salt used in key derivation.
  Future<List<int>> recoverBackupKey({
    required String backupId,
    required String password,
    required List<int> salt,
  }) async {
    try {
      final derivatedKeys = Argon2.computeTwoKeysFromPassword(
        password: password,
        salt: salt,
        length: 32,
      );
      if (derivatedKeys.$1.length != 32 || derivatedKeys.$2.length != 32) {
        throw KeyServiceException(
          message: 'Each key should have the same length',
        );
      }
      // authentication key will be consumed by the key server
      final authenticationKey = derivatedKeys.$1;
      // encryption key will cipher the secret before storage on the key server.
      final encryptionKey = derivatedKeys.$2;

      final response = await _postEncryptedBody('fetch', {
        'identifier': backupId,
        'authentication_key': HEX.encode(authenticationKey),
      });

      if (response.statusCode != 200) {
        throw KeyServiceException.fromResponse(response);
      }

      final encryptedResponse = response.data['encrypted_response'];
      final jsonBody = await Nip44.decrypt(
        payload: encryptedResponse,
        recipientPrivateKey: _privateKey,
        senderPublicKey: keyServerPublicKey,
      );

      final body = json.decode(jsonBody);

      final encryptedBackupKey = base64.decode(body['encrypted_secret']);
      final encryption = EncryptionService.splitBytes(encryptedBackupKey);
      final nonce = encryption.nonce;
      final ciphertext = encryption.ciphertext;

      final backupKey = EncryptionService.decrypt(
        key: encryptionKey,
        ciphertext: ciphertext,
        nonce: nonce,
      );
      if (backupKey.isNotEmpty && backupKey.length == 32) return backupKey;

      throw KeyServiceException(
          message: 'Invalid backup key format received from server');
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> _postEncryptedBody(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final encryptedBody = await Nip44.encrypt(
      plaintext: json.encode(body),
      senderPrivateKey: _privateKey,
      recipientPublicKey: keyServerPublicKey,
    );

    return await _client.post('$keyServer/$endpoint', data: {
      'public_key': Keychain(_privateKey).public,
      'encrypted_body': encryptedBody,
    });
  }
}
