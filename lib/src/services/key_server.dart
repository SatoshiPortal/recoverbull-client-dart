import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:hex/hex.dart';
import 'package:recoverbull/recoverbull.dart';
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

  /// Hard cap on the accepted `/attempts` body size, in bytes. The server's
  /// worst case is ~22.1 MB of JSON for 100,000 entries; anything larger is
  /// rejected before parsing. The read aborts mid-stream, so a gzip bomb
  /// cannot expand past this cap in memory.
  static const defaultMaxSnapshotBytes = 32 * 1024 * 1024;

  // constructor
  KeyServer({required this.address, required this.client}) {
    _validateAddress(address);
  }

  static void _validateAddress(Uri value) {
    final scheme = value.scheme.toLowerCase();
    final host = value.host.toLowerCase();
    final localHost = host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '::1';
    final onionHost = host.endsWith('.onion');

    if ((scheme != 'https' && scheme != 'http') ||
        host.isEmpty ||
        value.userInfo.isNotEmpty ||
        value.hasQuery ||
        value.hasFragment ||
        (scheme == 'http' && !localHost && !onionHost)) {
      throw ArgumentError.value(
        value,
        'address',
        'must be HTTPS, or HTTP to localhost, loopback, or a .onion host '
            'without credentials, query, or fragment',
      );
    }
  }

  /// serverInfo can be useful to check if the server is running and get infos such as
  /// - cooldown
  /// - canary
  /// - signature
  ///
  /// [expectedCanary] is the warrant canary the consumer expects from this
  /// server. It defaults to the historical `'🐦'` for backward
  /// compatibility; consumers serving another key server MUST pass their own
  /// expected value. An **empty** canary means the operator deliberately
  /// removed it — the compromise signal — and always raises the alarm.
  Future<Info> infos({String? expectedCanary}) async {
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
          retryAfterHeader: response.headers.value('retry-after'),
        );
      }

      final responseJson = json.decode(responseBody);
      final info = Info.fromMap(responseJson);

      // check warrant canary
      final canary = expectedCanary ?? '🐦';
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
          retryAfterHeader: e.headers.value('retry-after'),
        );
      }
      if (e is KeyServerException) rethrow;
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
          retryAfterHeader: response.headers.value('retry-after'),
        );
      }
    } catch (e) {
      if (e is HttpClientResponse) {
        final responseBody = await e.transform(utf8.decoder).join();
        throw KeyServerException.fromResponse(
          e.statusCode,
          responseBody,
          retryAfterHeader: e.headers.value('retry-after'),
        );
      }
      if (e is KeyServerException) rethrow;
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
    final result = await fetchBackupKeyWithStatus(
      backupId: backupId,
      password: password,
      salt: salt,
    );
    return result.backupKey;
  }

  /// Fetch an encryptedBackupKey backup key from the key server, with the
  /// exact attempt counters of the identifier's current rate-limit window.
  ///
  /// Prefer this method over [fetchBackupKey] when the consumer tracks
  /// brute-force telemetry: the returned [AttemptStatus] is the freshest
  /// signal and stays available even when `/attempts` is overloaded.
  Future<FetchBackupKeyResult> fetchBackupKeyWithStatus({
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
    final result = await trashBackupKeyWithStatus(
      backupId: backupId,
      password: password,
      salt: salt,
    );
    return result.backupKey;
  }

  /// Delete an encryptedBackupKey backup key from the key server, with the
  /// exact attempt counters of the identifier's current rate-limit window.
  Future<FetchBackupKeyResult> trashBackupKeyWithStatus({
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

  /// Conditional `GET /attempts`: the public brute-force telemetry snapshot.
  ///
  /// - [etag]: the ETag persisted from a previous [AttemptsModified]. Sent
  ///   back as `If-None-Match`; a `304` yields [AttemptsNotModified] without
  ///   parsing a body.
  /// - [backupIds]: locally known backup identifiers. Only the entries
  ///   matching them are returned; the full snapshot (up to 100,000 entries)
  ///   is parsed in a worker isolate and never retained by the caller.
  /// - [backupIdHashes]: pre-computed identifier hashes (`attemptsIdHash`),
  ///   for consumers that store hashes instead of raw identifiers. Matched
  ///   entries are the union of both parameters.
  /// - [maxSnapshotBytes]: hard cap on the accepted body size. The read
  ///   aborts mid-stream past the cap, so a gzip bomb cannot expand in
  ///   memory.
  ///
  /// Advisory telemetry: the server cannot distinguish an attacker from the
  /// user or another of the user's devices, and a compromised server can
  /// fabricate or suppress counters. Consumers must warn, never act
  /// automatically.
  Future<AttemptsResult> attempts({
    String? etag,
    List<List<int>> backupIds = const [],
    List<String> backupIdHashes = const [],
    int maxSnapshotBytes = defaultMaxSnapshotBytes,
  }) async {
    try {
      HttpClientResponse response = await _request(
        url: address.replace(path: '/attempts'),
        body: null,
        headers: {
          if (etag != null) 'If-None-Match': etag,
        },
      );

      if (response.statusCode == 304) {
        await response.drain();
        return const AttemptsNotModified();
      }

      if (response.statusCode != 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        throw KeyServerException.fromResponse(
          response.statusCode,
          responseBody,
          retryAfterHeader: response.headers.value('retry-after'),
        );
      }

      // Size-capped read: aborts mid-stream past the cap. HttpClient
      // auto-uncompresses gzip, so this bounds the decompressed size.
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
        if (bytes.length > maxSnapshotBytes) {
          throw KeyServerException(
            message:
                'attempts snapshot exceeds the $maxSnapshotBytes bytes limit',
          );
        }
      }
      final body = utf8.decode(bytes);

      final responseEtag = response.headers.value('etag');
      final maxAgeSeconds =
          _parseMaxAge(response.headers.value('cache-control'));

      // Parse and filter in a worker isolate: the snapshot can hold 100,000
      // entries (~22.1 MB of JSON) and must never reach the caller's isolate.
      final parsed = await Isolate.run(() {
        final snapshot = AttemptsSnapshot.parse(body);
        final hashes = {
          ...backupIds.map(attemptsIdHash),
          ...backupIdHashes,
        };
        return (
          version: snapshot.version,
          collectionStartedAt: snapshot.collectionStartedAt,
          totalEntries: snapshot.entries.length,
          matchingEntries: snapshot.entriesMatchingHashes(hashes),
        );
      });

      return AttemptsModified(
        etag: responseEtag,
        maxAgeSeconds: maxAgeSeconds,
        version: parsed.version,
        collectionStartedAt: parsed.collectionStartedAt,
        totalEntries: parsed.totalEntries,
        matchingEntries: parsed.matchingEntries,
      );
    } catch (e) {
      if (e is KeyServerException) rethrow;
      throw KeyServerException(message: e.toString());
    }
  }

  Future<FetchBackupKeyResult> _fetchKey({
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
          retryAfterHeader: response.headers.value('retry-after'),
        );
      }

      final data = json.decode(responseBody);

      final encryptedBackupKey = base64.decode(data['encrypted_secret']);
      final encryption = EncryptionService.splitBytes(encryptedBackupKey);
      final nonce = encryption.nonce;
      final ciphertext = encryption.ciphertext;

      // Decrypts the encrypted backup key using the encryption key derived from user password and salt.
      // The HMAC MUST be verified: a malicious or compromised key server (or a row planted
      // through the public /store endpoint) could otherwise return a tampered ciphertext
      // that decrypts silently into a forged backup key.
      final backupKey = EncryptionService.decrypt(
        key: encryptionKey,
        ciphertext: ciphertext,
        nonce: nonce,
        hmac: encryption.hmac,
      );

      // attempt_status is additive on the server side; older servers do not
      // send it. Null means "no telemetry": consumers must skip baseline
      // reconciliation rather than treat a fabricated value as authoritative.
      final attemptStatus = data['attempt_status'] != null
          ? AttemptStatus.fromMap(
              data['attempt_status'] as Map<String, dynamic>)
          : null;

      return FetchBackupKeyResult(
        backupKey: backupKey,
        attemptStatus: attemptStatus,
      );
    } catch (e) {
      if (e is HttpClientResponse) {
        final responseBody = await e.transform(utf8.decoder).join();
        throw KeyServerException.fromResponse(
          e.statusCode,
          responseBody,
          retryAfterHeader: e.headers.value('retry-after'),
        );
      }
      rethrow;
    }
  }

  Future<HttpClientResponse> _request({
    required Uri url,
    required String? body,
    Map<String, String>? headers,
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
      headers?.forEach((name, value) => request.headers.add(name, value));

      if (body != null) request.write(body);

      final response = await request.close();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  static int? _parseMaxAge(String? cacheControl) {
    if (cacheControl == null) return null;
    final match = RegExp(r'max-age=(\d+)').firstMatch(cacheControl);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }
}
