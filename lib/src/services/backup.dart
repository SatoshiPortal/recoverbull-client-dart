// backup_service.dart
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:recoverbull_dart/src/models/backup_data.dart';
import 'package:recoverbull_dart/src/models/encryption_data.dart';
import 'package:recoverbull_dart/src/models/key_info.dart';
import 'package:recoverbull_dart/src/services/encryption.dart';
import 'package:recoverbull_dart/src/services/key_management.dart';

/// Exception specific to backup operations
class BackupException implements Exception {
  final String message;
  final dynamic cause;

  BackupException(this.message, [this.cause]);

  @override
  String toString() =>
      'BackupException: $message${cause != null ? ' ($cause)' : ''}';
}

class BackupService {
  final KeyManagementService _keyService;
  static const int currentVersion = 1;

  BackupService(this._keyService) {
    _validateKeyService();
  }

  /// Validates the key service initialization
  void _validateKeyService() {
    if (_keyService.pinVerified != true) {
      throw BackupException(
          'Key service not properly initialized: PIN not verified');
    }
  }

  /// Creates an encrypted backup with metadata
  ///
  /// Parameters:
  /// - [backupId]: Unique identifier for the backup
  /// - [plaintext]: Data to be encrypted and backed up
  ///
  /// Throws [BackupException] if the operation fails
  Future<List<int>> createBackup(String backupId, List<int> plaintext) async {
    try {
      debugPrint('Creating backup: $backupId');

      // Input validation
      if (backupId.isEmpty) {
        throw BackupException('Backup ID cannot be empty');
      }
      if (plaintext.isEmpty) {
        throw BackupException('Backup data cannot be empty');
      }

      // Get active encryption key
      final activeKeyInfo = await _keyService.getActiveKey();
      if (activeKeyInfo == null) {
        throw BackupException('No active encryption key available');
      }

      // Encrypt the data
      final encResult = await _encryptBackupData(plaintext, activeKeyInfo.key);

      // Create metadata
      final metadata = await _createBackupMetadata(
        backupId: backupId,
        keyId: activeKeyInfo.keyId,
        encryptionResult: encResult,
      );

      // Serialize metadata
      final metadataBytes = _serializeMetadata(metadata);

      debugPrint('Successfully created backup: $backupId');
      return metadataBytes;
    } catch (e, stackTrace) {
      final errorMsg = 'Failed to create backup';
      debugPrint(stackTrace.toString());
      throw BackupException(errorMsg, e);
    }
  }

  /// Encrypts the backup data
  Future<EncryptionData> _encryptBackupData(
    List<int> plaintext,
    List<int> key,
  ) async {
    try {
      return await EncryptionService.encrypt(plaintext, key);
    } catch (e) {
      throw BackupException('Encryption failed', e);
    }
  }

  /// Creates backup metadata with encryption details
  Future<BackupMetadata> _createBackupMetadata({
    required String backupId,
    required String keyId,
    required EncryptionData encryptionResult,
  }) async {
    try {
      return BackupMetadata(
        version: currentVersion,
        backupId: backupId,
        keyId: keyId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        nonce: base64.encode(encryptionResult.nonce),
        ciphertext: base64.encode(encryptionResult.ciphertext),
        tag: base64.encode(encryptionResult.tag),
      );
    } catch (e) {
      throw BackupException('Failed to create backup metadata', e);
    }
  }

  /// Serializes backup metadata to bytes
  List<int> _serializeMetadata(BackupMetadata metadata) {
    try {
      final metadataJson = jsonEncode(metadata.toJson());
      return utf8.encode(metadataJson);
    } catch (e) {
      throw BackupException('Failed to serialize backup metadata', e);
    }
  }

  /// Restores a backup from metadata
  ///
  /// Parameters:
  /// - [metadata]: Backup metadata containing encryption details
  ///
  /// Throws [BackupException] if the restoration fails
  Future<List<int>> restoreBackup(BackupMetadata metadata) async {
    try {
      debugPrint('Restoring backup: ${metadata.backupId}');

      // Validate metadata
      _validateBackupMetadata(metadata);

      // Get the decryption key
      final keyInfo = await _getDecryptionKey(metadata.keyId);

      // Decode and decrypt the data
      final plaintext = await _decryptBackupData(metadata, keyInfo.key);

      debugPrint('Successfully restored backup: ${metadata.backupId}');
      return plaintext;
    } catch (e, stackTrace) {
      final errorMsg = 'Failed to restore backup';
      debugPrint(stackTrace.toString());
      throw BackupException(errorMsg, e);
    }
  }

  /// Validates backup metadata
  void _validateBackupMetadata(BackupMetadata metadata) {
    if (metadata.version > currentVersion) {
      throw BackupException('Unsupported backup version: ${metadata.version}');
    }
    if (metadata.tag == null) {
      throw BackupException('Missing authentication tag in backup metadata');
    }
  }

  /// Retrieves the decryption key
  Future<KeyInfo> _getDecryptionKey(String keyId) async {
    final keyInfo = await _keyService.readKey(keyId);
    if (keyInfo == null) {
      throw BackupException('Decryption key not found: $keyId');
    }
    return keyInfo;
  }

  /// Decrypts the backup data
  Future<List<int>> _decryptBackupData(
    BackupMetadata metadata,
    List<int> key,
  ) async {
    try {
      return EncryptionService.decrypt(
        ciphertext: base64.decode(metadata.ciphertext),
        nonce: base64.decode(metadata.nonce),
        tag: base64.decode(metadata.tag!),
        key: key,
      );
    } catch (e) {
      throw BackupException('Decryption failed', e);
    }
  }
}
