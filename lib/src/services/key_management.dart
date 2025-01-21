import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';
import 'package:recoverbull/src/utils.dart';

/// Custom exception for key management operations
class KeyManagementException implements Exception {
  final String message;
  final dynamic cause;

  const KeyManagementException(this.message, [this.cause]);

  @override
  String toString() =>
      'KeyManagementException: $message${cause != null ? ' ($cause)' : ''}';
}

/// Service responsible for key management operations with remote server
class KeyManagementService {
  final String keychainapi;
  final Dio _client;
  static const _contentTypeJson = {'Content-Type': 'application/json'};

  KeyManagementService({
    required this.keychainapi,
    Dio? client,
  }) : _client = client ?? Dio();

  /// Stores a backup key on the remote server
  Future<void> storeBackupKey(
    String backupId,
    String backupKey,
    String secret,
  ) async {
    try {
      _validateApiUrl();

      final response = await _client.post(
        '$keychainapi/store_key',
        options: Options(headers: _contentTypeJson),
        data: {
          'backup_id': backupId,
          'backup_key': backupKey,
          'secret_hash': secret.toSHA256Hash(),
        },
      );

      _handleStoreResponse(response);
      debugPrint('Backup key stored successfully on server');
    } catch (e, stackTrace) {
      debugPrint(stackTrace.toString());
      if (e is KeyManagementException) rethrow;
      throw KeyManagementException(
        'Failed to store backup key on server: ${e.toString()}',
      );
    }
  }

  /// Recovers a backup key from the remote server
  Future<String> recoverBackupKey(
    String backupId,
    String secret,
  ) async {
    try {
      _validateApiUrl();

      final response = await _client.post(
        '$keychainapi/recover_key',
        options: Options(headers: _contentTypeJson),
        data: {
          'backup_id': backupId,
          'secret_hash': secret.toSHA256Hash(),
        },
      );

      return _extractBackupKey(response);
    } catch (e, stackTrace) {
      debugPrint(stackTrace.toString());
      if (e is KeyManagementException) rethrow;
      throw KeyManagementException(
        'Failed to recover backup key from server: ${e.toString()}',
      );
    }
  }

  // Private helper methods
  void _validateApiUrl() {
    if (keychainapi.isEmpty) {
      throw const KeyManagementException('Keychain API URL not set');
    }
  }

  void _handleStoreResponse(Response response) {
    try {
      if (response.statusCode == 201) return;

      if (response.statusCode == 403) {
        throw const KeyManagementException('Key already stored on server');
      }

      throw KeyManagementException(
        'Failed to store key on server (${response.statusCode})',
      );
    } catch (e, stackTrace) {
      debugPrint(stackTrace.toString());
      if (e is KeyManagementException) rethrow;
      throw KeyManagementException(
        'Failed to handle store response: ${e.toString()}',
      );
    }
  }

  String _extractBackupKey(Response response) {
    try {
      if (response.statusCode != 200) {
        throw KeyManagementException(
          'Failed to recover key (${response.statusCode}): ${response.data}',
        );
      }

      final backupKey = response.data['backup_key'];
      if (backupKey != null && backupKey is String) {
        return backupKey;
      }

      throw const KeyManagementException(
        'Invalid backup key format received from server',
      );
    } catch (e, stackTrace) {
      debugPrint(stackTrace.toString());
      if (e is KeyManagementException) rethrow;
      throw KeyManagementException(
        'Failed to extract backup key: ${e.toString()}',
      );
    }
  }
}
