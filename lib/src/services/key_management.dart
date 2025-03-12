import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:hex/hex.dart';
import 'package:recoverbull/recoverbull.dart';
import 'package:recoverbull/src/models/info.dart';
import 'package:recoverbull/src/services/argon2.dart';
import 'package:recoverbull/src/services/encryption.dart';
import 'package:tor/socks_socket.dart';

/// The [KeyService] class provides functionalities to store and recover
/// backup keys securely by interacting with a remote key server API. It handles
/// key derivation, encryption, and communication with the server.
class KeyService {
  final Uri keyServer;

  late Tor? _tor;
  late int _torPort;
  static const _headers = {'Content-Type': 'application/json'};

  // constructor
  KeyService({
    required this.keyServer,
    Tor? tor,
    int? torPort,
  }) {
    final tld = keyServer.host.split('.').last;
    if ((tor == null && tld == 'onion') || (tor != null && tld != 'onion')) {
      throw KeyServiceException(message: 'use .onion URI with TOR');
    }
    _tor = tor;
    _torPort = torPort ?? 80;
  }

  void dispose() async {
    _tor?.stop();
    _tor = null;
  }

  Future<SOCKSSocket> get _socks async {
    final socks = await SOCKSSocket.create(
      proxyHost: InternetAddress.loopbackIPv4.address,
      proxyPort: Tor.instance.port,
      sslEnabled: keyServer.scheme == 'https' ? true : false,
    );
    return socks;
  }

  /// serverInfo can be useful to check if the server is running and get infos such as
  /// - cooldown
  /// - canary
  /// - signature
  Future<Info> serverInfo() async {
    try {
      final uri = keyServer.replace(path: '/info');

      http.Response response;
      if (_tor == null) {
        response = await http.get(uri, headers: _headers);
      } else {
        response = await _torRequest(
          socks: await _socks,
          request: [
            'GET ${uri.path} HTTP/1.1\r\n',
            'Host: ${uri.host}\r\n',
            '\r\n'
          ].join(),
        );
      }

      if (response.statusCode != 200) {
        throw KeyServiceException.fromResponse(response);
      }

      final responseJson = json.decode(utf8.decode(response.bodyBytes));
      final info = Info.fromMap(responseJson);

      // check warrant canary
      const canary = '🐦';
      if (info.canary != canary) {
        throw KeyServiceException(
            message:
                'Warrant Canary: $canary is missing. This may indicate a compromise or inability to confirm the canary\'s integrity.');
      }

      return info;
    } catch (e) {
      if (e is http.Response) throw KeyServiceException.fromResponse(e);
      throw KeyServiceException(message: e.toString());
    }
  }

  /// Stores an encryptedBackupKey backup key on the remote key-server.
  ///
  /// Parameters:
  /// - `backupId`: Hex-encoded random bytes
  /// - `password`: The password used for key derivation.
  /// - `backupKey`: The bytes of the backup key
  /// - `salt`: The bytes of the salt used in key derivation.
  Future<void> storeBackupKey({
    required List<int> backupId,
    required List<int> password,
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
        password: utf8.decode(password),
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

      final body = json.encode({
        'identifier': HEX.encode(backupId),
        'authentication_key': HEX.encode(authenticationKey),
        'encrypted_secret': base64.encode(encryptedBackupKey),
      });

      const endpoint = '/store';
      http.Response response;
      if (_tor == null) {
        response = await http.post(
          keyServer.replace(path: endpoint),
          headers: _headers,
          body: body,
        );
      } else {
        response = await _torRequest(
          socks: await _socks,
          request: [
            'POST $endpoint HTTP/1.1',
            'Host: ${keyServer.host}',
            'Content-Type: application/json',
            'Content-Length: ${body.length}',
            '',
            body
          ].join('\r\n'),
        );
      }

      if (response.statusCode != 201) {
        throw KeyServiceException.fromResponse(response);
      }
    } catch (e) {
      if (e is http.Response) throw KeyServiceException.fromResponse(e);
      throw KeyServiceException(message: e.toString());
    }
  }

  /// Fetch an encryptedBackupKey backup key from the key server.
  ///
  /// Parameters:
  /// - `backupId`: Hex-encoded random bytes
  /// - `password`: The password used for key derivation.
  /// - `salt`: The bytes of the salt used in key derivation.
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
  /// - `backupId`: Hex-encoded random bytes
  /// - `password`: The password used for key derivation.
  /// - `salt`: The bytes of the salt used in key derivation.
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
        throw KeyServiceException(
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

      http.Response response;
      if (_tor == null) {
        response = await http.post(
          keyServer.replace(path: endpoint),
          headers: _headers,
          body: body,
        );
      } else {
        response = await _torRequest(
          socks: await _socks,
          request: [
            'POST $endpoint HTTP/1.1',
            'Host: ${keyServer.host}',
            'Content-Type: application/json',
            'Content-Length: ${body.length}',
            '',
            body
          ].join('\r\n'),
        );
      }

      // /fetch should returns 200 while /trash should returns 202
      if (response.statusCode != 200 && response.statusCode != 202) {
        throw KeyServiceException.fromResponse(response);
      }

      final data = json.decode(utf8.decode(response.bodyBytes));
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
      rethrow;
    }
  }

  Future<http.Response> _torRequest({
    required SOCKSSocket socks,
    required String request,
  }) async {
    try {
      await socks.connect(); // Establish SOCKS connection
      // Connect to target server
      await socks.connectTo(keyServer.host, _torPort);

      socks.write(request); // Send the request

      final response = <int>[];

      await for (var bytes in socks.inputStream) {
        response.addAll(bytes);
        break;
      }

      return parseHttpResponse(response); // deserialize bytes
    } catch (e) {
      rethrow;
    } finally {
      await socks.close();
    }
  }
}
