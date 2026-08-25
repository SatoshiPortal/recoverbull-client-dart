import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recoverbull/recoverbull.dart';
import 'package:recoverbull/src/services/argon2.dart';
import 'package:recoverbull/src/services/encryption.dart';

void main() {
  test('fetchBackupKey rejects HMAC, ciphertext, and nonce tampering', () async {
    final password = utf8.encode('integration-password');
    final salt = List<int>.filled(16, 0x42);
    final backupId = List<int>.filled(32, 0x24);
    final expectedKey = List<int>.generate(32, (index) => index);
    final derived = Argon2.computeTwoKeysFromPassword(
      password: utf8.decode(password),
      salt: salt,
      length: 32,
    );
    final encrypted = EncryptionService.encrypt(
      key: derived.$2,
      plaintext: expectedKey,
    );

    var tampering = 'none';
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final response = List<int>.from(EncryptionService.mergeBytes(encrypted));
      switch (tampering) {
        case 'hmac':
          response[response.length - 1] ^= 1;
        case 'ciphertext':
          response[16] ^= 1;
        case 'nonce':
          response[0] ^= 1;
      }
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'encrypted_secret': base64.encode(response)}));
      await request.response.close();
    });

    final client = HttpClient();
    final keyServer = KeyServer(
      address: Uri.parse('http://127.0.0.1:${server.port}'),
      client: client,
    );
    try {
      expect(
        await keyServer.fetchBackupKey(
          backupId: backupId,
          password: password,
          salt: salt,
        ),
        expectedKey,
      );

      for (final kind in ['hmac', 'ciphertext', 'nonce']) {
        tampering = kind;
        await expectLater(
          keyServer.fetchBackupKey(
            backupId: backupId,
            password: password,
            salt: salt,
          ),
          throwsA(isA<EncryptionException>()),
        );
      }
    } finally {
      client.close(force: true);
      await server.close(force: true);
    }
  });
}
