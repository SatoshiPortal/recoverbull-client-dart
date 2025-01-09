import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';
import 'package:hex/hex.dart';
import 'package:pointycastle/digests/sha256.dart';

/// Custom exception for key management operations
class KeyManagementException implements Exception {
  final String message;
  final dynamic cause;

  KeyManagementException(this.message, [this.cause]);

  @override
  String toString() =>
      'KeyManagementException: $message${cause != null ? ' ($cause)' : ''}';
}

/// Service responsible for key management operations with remote server
class KeyManagementService {
  final String keychainapi;

  KeyManagementService({required this.keychainapi});

  /// Stores a backup key on the remote server
  Future<void> storeBackupKey(
      String backupId, String backupKey, String secret) async {
    final secretHashBytes =
        SHA256Digest().process(Uint8List.fromList(utf8.encode(secret)));
    final secretHashHex = HEX.encode(secretHashBytes);

    try {
      final response = await Dio().post(
        '$keychainapi/store_key',
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {
          'backup_id': backupId,
          'backup_key': backupKey,
          'secret_hash': secretHashHex,
        },
      );

      if (response.statusCode == 201) {
        debugPrint('Backup key stored successfully on server');
      } else if (response.statusCode == 403) {
        throw KeyManagementException('Key already stored on server');
      } else {
        throw KeyManagementException(
            'Failed to store key on server (${response.statusCode})');
      }
    } catch (e) {
      throw KeyManagementException('Failed to store backup key on server', e);
    }
  }

  /// Recovers a backup key from the remote server
  Future<String> recoverBackupKey(String backupId, String secret) async {
    if (keychainapi.isEmpty) {
      throw KeyManagementException('Keychain API URL not set');
    }

    try {
      final secretHash =
          SHA256Digest().process(Uint8List.fromList(utf8.encode(secret)));

      final response = await Dio().post(
        '$keychainapi/recover_key',
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {
          'backup_id': backupId,
          'secret_hash': HEX.encode(secretHash),
        },
      );

      if (response.statusCode == 200) {
        final backupKey = response.data['backup_key'];
        if (backupKey != null && backupKey is String) {
          return backupKey;
        }
        throw KeyManagementException(
            'Invalid backup key format received from server');
      } else {
        throw KeyManagementException(
            'Failed to recover key (${response.statusCode}): ${response.data}');
      }
    } catch (e) {
      throw KeyManagementException(
          'Failed to recover backup key from server', e);
    }
  }
}
