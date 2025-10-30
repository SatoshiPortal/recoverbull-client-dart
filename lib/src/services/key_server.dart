import 'dart:convert';
import 'dart:io';

import 'package:hex/hex.dart';
import 'package:recoverbull/recoverbull.dart';
import 'package:recoverbull/src/models/info.dart';
import 'package:recoverbull/src/services/argon2.dart';
import 'package:recoverbull/src/services/encryption.dart';

/// The [KeyServer] class provides functionalities to store and recover
/// backup keys securely by interacting with a remote key server API. It handles
/// key derivation, encryption, and communication with the server.
class KeyServer {
  /// [address] to connect through the SOCKS socket.
  ///
  /// https://something.com or http://something.onion if using Tor.
  ///
  /// If you decide to use Tor you must provide a SOCKSSocket
  final Uri address;

  final HttpClient client;

  // constructor
  KeyServer({required this.address, required this.client});

  /// serverInfo can be useful to check if the server is running and get infos such as
  /// - cooldown
  /// - canary
  /// - signature
  Future<Info> infos() async {
    try {
      final endpoint = '/info';
      HttpClientResponse response = await _request(
        url: address.replace(path: endpoint),
        body: null,
      );

      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw KeyServerException.fromResponse(
          response.statusCode,
          responseBody,
        );
      }

      final responseJson = json.decode(responseBody);
      final info = Info.fromMap(responseJson);

      // check warrant canary
      const canary = '🐦';
      if (info.canary != canary) {
        throw KeyServerException(
            message:
                'Warrant Canary: $canary is missing. This may indicate a compromise or inability to confirm the canary\'s integrity.');
      }

      return info;
    } catch (e) {
      if (e is HttpClientResponse) {
        final responseBody = await e.transform(utf8.decoder).join();
        throw KeyServerException.fromResponse(
          e.statusCode,
          responseBody,
        );
      }
      throw KeyServerException(message: e.toString());
    }
  }

  /// Stores an encryptedBackupKey backup key on the remote key-server.
  ///
  /// Parameters:
  /// - `backupId`: The backup identifier bytes
  /// - `password`: The password bytes (UTF8)
  /// - `backupKey`: The bytes of the backup key
  /// - `salt`: The bytes of the salt used in key derivation
  Future<void> storeBackupKey({
    required List<int> backupId,
    required List<int> password,
    required List<int> backupKey,
    required List<int> salt,
  }) async {
    try {
      if (salt.length != 16) {
        throw KeyServerException(
          message: '16 random secure bytes are expected for the salt',
        );
      }

      // Derive two keys from the password and salt using Argon2
      final derivatedKeys = Argon2.computeTwoKeysFromPassword(
        password: utf8.decode(password),
        salt: salt,
        length: 32,
      );
      if (derivatedKeys.$1.length != 32 || derivatedKeys.$2.length != 32) {
        throw KeyServerException(
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

      final body = json.encode({
        'identifier': HEX.encode(backupId),
        'authentication_key': HEX.encode(authenticationKey),
        'encrypted_secret': base64.encode(encryptedBackupKey),
      });

      const endpoint = '/store';
      HttpClientResponse response = await _request(
        url: address.replace(path: endpoint),
        body: body,
      );

      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 201) {
        throw KeyServerException.fromResponse(
          response.statusCode,
          responseBody,
        );
      }
    } catch (e) {
      if (e is HttpClientResponse) {
        final responseBody = await e.transform(utf8.decoder).join();
        throw KeyServerException.fromResponse(
          e.statusCode,
          responseBody,
        );
      }
      throw KeyServerException(message: e.toString());
    }
  }

  /// Fetch an encryptedBackupKey backup key from the key server.
  ///
  /// Parameters:
  /// - `backupId`: The backup identifier bytes
  /// - `password`: The password bytes (UTF8)
  /// - `salt`: The bytes of the salt used in key derivation
  Future<List<int>> fetchBackupKey({
    required List<int> backupId,
    required List<int> password,
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
  /// - `backupId`: The backup identifier bytes
  /// - `password`: The password bytes (UTF8)
  /// - `salt`: The bytes of the salt used in key derivation
  Future<List<int>> trashBackupKey({
    required List<int> backupId,
    required List<int> password,
    required List<int> salt,
  }) async {
    return _fetchKey(
      backupId: backupId,
      password: password,
      salt: salt,
      isTrashingSecret: true,
    );
  }

  Future<List<int>> _fetchKey({
    required List<int> backupId,
    required List<int> password,
    required List<int> salt,
    required bool isTrashingSecret,
  }) async {
    try {
      // Derive two keys from the password and salt using Argon2
      final derivatedKeys = Argon2.computeTwoKeysFromPassword(
        password: utf8.decode(password),
        salt: salt,
        length: 32,
      );
      if (derivatedKeys.$1.length != 32 || derivatedKeys.$2.length != 32) {
        throw KeyServerException(
          message: 'Each key should have the same length',
        );
      }
      // authentication key will be consumed by the key server
      final authenticationKey = derivatedKeys.$1;
      // encryption key will cipher the secret before storage on the key server.
      final encryptionKey = derivatedKeys.$2;

      final body = json.encode({
        'identifier': HEX.encode(backupId),
        'authentication_key': HEX.encode(authenticationKey),
      });

      var endpoint = '/fetch';
      if (isTrashingSecret) endpoint = '/trash';

      HttpClientResponse response = await _request(
        url: address.replace(path: endpoint),
        body: body,
      );

      final responseBody = await response.transform(utf8.decoder).join();

      // /fetch should returns 200 while /trash should returns 202
      if (response.statusCode != 200 && response.statusCode != 202) {
        throw KeyServerException.fromResponse(
          response.statusCode,
          responseBody,
        );
      }

      final data = json.decode(responseBody);

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

      return backupKey;
    } catch (e) {
      if (e is HttpClientResponse) {
        final responseBody = await e.transform(utf8.decoder).join();
        throw KeyServerException.fromResponse(
          e.statusCode,
          responseBody,
        );
      }
      rethrow;
    }
  }

  Future<HttpClientResponse> _request({
    required Uri url,
    required String? body,
  }) async {
    try {
      HttpClientRequest request;
      if (body != null) {
        request = await client.postUrl(url);
      } else {
        request = await client.getUrl(url);
      }
      request.headers.contentType = ContentType.json;
      request.headers.add('Host', address.host);

      if (body != null) request.write(body);

      final response = await request.close();
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
