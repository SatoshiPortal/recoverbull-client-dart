import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hex/hex.dart';
import 'package:nostr/nostr.dart';
import 'package:recoverbull/recoverbull.dart';
import 'package:recoverbull/src/models/exceptions.dart';
import 'package:recoverbull/src/models/info.dart';
import 'package:recoverbull/src/models/payload.dart';
import 'package:recoverbull/src/services/argon2.dart';
import 'package:recoverbull/src/services/encryption.dart';

/// The [KeyService] class provides functionalities to store and recover
/// backup keys securely by interacting with a remote key server API. It handles
/// key derivation, encryption, and communication with the server.
class KeyService {
  final Uri keyServer;
  final String keyServerPublicKey;
  late Dio _client;
  late Keys _keys;

  // constructor
  KeyService({
    required this.keyServer,
    required this.keyServerPublicKey,
  }) {
    _keys = Keys.generate();
    _client = Dio(BaseOptions(headers: {'Content-Type': 'application/json'}));
  }

  /// serverInfo can be useful to check if the server is running and get infos such as
  /// - cooldown
  /// - canary
  /// - signature
  Future<Info> serverInfo() async {
    final response = await _client.get('$keyServer/info');

    if (response.statusCode == 200) {
      final signedResponse = response.data;
      final signature = signedResponse['signature'] as String;
      final payloadString = signedResponse['response'] as String;
      final payloadBytes = utf8.encode(payloadString);
      final hashedPayload = sha256(payloadBytes);

      checkSignature(
        pubkey: keyServerPublicKey,
        message: HEX.encode(hashedPayload),
        signature: signature,
      );

      final payload = Payload.fromMap(json.decode(payloadString));
      final info = Info.fromMap(json.decode(payload.data));
      checkTimestamp(timestamp: payload.timestamp);

      return info;
    }

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
      if (salt.length != 16) {
        throw KeyServiceException(
          message: '16 random secure bytes are expected for the salt',
        );
      }

      // Derive two keys from the password and salt using Argon2
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

      // Encrypt the whole request body
      final response = await _postEncryptedBody('/store', {
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

  /// Fetch an encryptedBackupKey backup key from the key server.
  ///
  /// Parameters:
  /// - `backupId`: Hex-encoded random bytes
  /// - `password`: The password used for key derivation.
  /// - `salt`: The bytes of the salt used in key derivation.
  Future<List<int>> fetchBackupKey({
    required String backupId,
    required String password,
    required List<int> salt,
  }) async {
    return _fetchKey(
      backupId: backupId,
      password: password,
      salt: salt,
      isTrashingSecret: false,
    );
  }

  /// Delete an encryptedBackupKey backup key from the key server.
  ///
  /// Parameters:
  /// - `backupId`: Hex-encoded random bytes
  /// - `password`: The password used for key derivation.
  /// - `salt`: The bytes of the salt used in key derivation.
  Future<List<int>> trashBackupKey({
    required String backupId,
    required String password,
    required List<int> salt,
  }) async {
    return _fetchKey(
      backupId: backupId,
      password: password,
      salt: salt,
      isTrashingSecret: true,
    );
  }

  Future<Response> _postEncryptedBody(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final encryptedBody = await Nip44.encrypt(
      plaintext: json.encode(body),
      senderSecretKey: _keys.secret,
      recipientPublicKey: keyServerPublicKey,
    );

    return await _client.post('$keyServer$endpoint', data: {
      'public_key': _keys.public,
      'encrypted_body': encryptedBody,
    });
  }

  Future<List<int>> _fetchKey({
    required String backupId,
    required String password,
    required List<int> salt,
    required bool isTrashingSecret,
  }) async {
    try {
      // Derive two keys from the password and salt using Argon2
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

      var endpoint = '/fetch';
      if (isTrashingSecret) endpoint = '/trash';

      // Encrypts the whole request body
      final response = await _postEncryptedBody(endpoint, {
        'identifier': backupId,
        'authentication_key': HEX.encode(authenticationKey),
      });

      // /fetch should returns 200 while /trash should returns 202
      if (response.statusCode != 200 && response.statusCode != 202) {
        throw KeyServiceException.fromResponse(response);
      }

      // Deserialize the SignedResponse
      final signedResponse = response.data;
      final signature = signedResponse['signature'] as String;
      final payloadString = signedResponse['response'] as String;
      final payloadBytes = utf8.encode(payloadString);
      final hashedPayload = sha256(payloadBytes);

      checkSignature(
        pubkey: keyServerPublicKey,
        message: HEX.encode(hashedPayload),
        signature: signature,
      );

      // Decrypts the response
      final decryptedResponse = await Nip44.decrypt(
        payload: payloadString,
        recipientSecretKey: _keys.secret,
        senderPublicKey: keyServerPublicKey,
      );

      final payload = Payload.fromMap(json.decode(decryptedResponse));
      checkTimestamp(timestamp: payload.timestamp);

      final data = json.decode(payload.data);
      final encryptedBackupKey = base64.decode(data['encrypted_secret']);
      final encryption = EncryptionService.splitBytes(encryptedBackupKey);
      final nonce = encryption.nonce;
      final ciphertext = encryption.ciphertext;

      // Decrypts the encrypted backup key using the encryption key derived from user password and salt
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
}
