import 'package:dio/dio.dart';
import 'package:hex/hex.dart';
import 'package:recoverbull/src/models/exceptions.dart';
import 'package:recoverbull/src/services/argon2.dart';
import 'package:recoverbull/src/services/encryption.dart';

/// The [KeyService] class provides functionalities to store and recover
/// backup keys securely by interacting with a remote key server API. It handles
/// key derivation, encryption, and communication with the server.
class KeyService {
  final Uri keyServer;
  final Dio _client;
  static const _contentTypeJson = {'Content-Type': 'application/json'};

  /// Creates an instance of [KeyService].
  KeyService({required this.keyServer, Dio? client})
      : _client = client ?? Dio();

  /// Stores an encrypted backup key on the remote key-server.
  ///
  /// Parameters:
  /// - `backupId`: Hex-encoded
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
        throw KeyServiceException('Each key should have the same length');
      }
      // authentication key will be consumed by the key server
      final authenticationKey = derivatedKeys.$1;
      // encryption key will cipher the secret before storage on the key server.
      final encryptionKey = derivatedKeys.$2;

      // Encrypt the backupKey using the encryption key
      final backupKeyEncrypted =
          await EncryptionService.encrypt(encryptionKey, backupKey);

      final response = await _client.post(
        '$keyServer/store',
        options: Options(headers: _contentTypeJson),
        data: {
          'backup_id': backupId,
          'authentication_key': HEX.encode(authenticationKey),
          'encrypted_secret': backupKeyEncrypted,
        },
      );

      if (response.statusCode == 201) return;

      if (response.statusCode == 403) {
        throw const KeyServiceException('Key already stored on server');
      }

      throw KeyServiceException(
        'Failed to store key on server (${response.statusCode})',
      );
    } catch (e) {
      if (e is KeyServiceException) rethrow;
      throw KeyServiceException(
        'Failed to store backup key on server: ${e.toString()}',
      );
    }
  }

  /// Recovers an encrypted backup key from the key server.
  ///
  /// Parameters:
  /// - `backupId`: Hex-encoded
  /// - `password`: The password used for key derivation.
  /// - `backupKey`: The bytes of the backup key
  /// - `salt`: The bytes of the salt used in key derivation.
  Future<List<int>> recoverBackupKey({
    required String backupId,
    required String password,
    required List<int> nonce,
    required List<int> salt,
  }) async {
    try {
      final derivatedKeys = Argon2.computeTwoKeysFromPassword(
        password: password,
        salt: salt,
        length: 32,
      );
      if (derivatedKeys.$1.length != 32 || derivatedKeys.$2.length != 32) {
        throw KeyServiceException('Each key should have the same length');
      }
      // authentication key will be consumed by the key server
      final authenticationKey = derivatedKeys.$1;
      // encryption key will cipher the secret before storage on the key server.
      final encryptionKey = derivatedKeys.$2;

      final response = await _client.post(
        '$keyServer/recover',
        options: Options(headers: _contentTypeJson),
        data: {
          'backup_id': backupId,
          'authentication_key': HEX.encode(authenticationKey),
        },
      );

      if (response.statusCode != 200) {
        throw KeyServiceException(
          'Failed to recover key (${response.statusCode}): ${response.data}',
        );
      }

      final encryptedBackupKey = response.data['encrypted_secret'];
      final backupKey = await EncryptionService.decrypt(
        keyBytes: encryptionKey,
        ciphertext: encryptedBackupKey,
        nonce: nonce,
      );
      if (backupKey.isNotEmpty && backupKey.length == 32) return backupKey;

      throw const KeyServiceException(
        'Invalid backup key format received from server',
      );
    } catch (e) {
      if (e is KeyServiceException) rethrow;
      throw KeyServiceException(
        'Failed to recover backup key from server: ${e.toString()}',
      );
    }
  }
}
