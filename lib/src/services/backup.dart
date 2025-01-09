// backup_service.dart
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hex/hex.dart';
import 'package:recoverbull_dart/src/models/backup_data.dart';
import 'package:recoverbull_dart/src/services/encryption.dart';

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
  /// Creates an encrypted backup with metadata
  ///
  /// Parameters:
  /// - [backupId]: Unique identifier for the backup in Hex format
  /// - [plaintext]: Data to be encrypted and backed in Hex format
  /// - [backupKey]: Key used to encrypt the data in Hex format
  /// Throws [BackupException] if the operation fails
  static Future<String> createBackup(
      String backupId, String plaintext, String backupKey) async {
    try {
      debugPrint('Creating backup: $backupId');
      final plainTextBytes = utf8.encode(plaintext);
      // Input validation
      if (backupId.isEmpty) {
        throw BackupException('Backup ID cannot be empty');
      }
      if (plainTextBytes.isEmpty) {
        throw BackupException('Backup data cannot be empty');
      }

      // Encrypt the data
      final encResult = await EncryptionService.aesEncrypt(
          Uint8List.fromList(HEX.decode(backupKey)), plainTextBytes);

      final metadata = BackupMetadata(
          backupId: backupId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          encryptedData: encResult);
      final metadataJson = jsonEncode(metadata.toJson());
      debugPrint('Successfully created backup: $backupId');
      return metadataJson;
    } catch (e, stackTrace) {
      final errorMsg = 'Failed to create backup';
      debugPrint(stackTrace.toString());
      throw BackupException(errorMsg, e);
    }
  }

  /// Restores a backup from metadata
  ///
  /// Parameters:
  /// - [metadata]: Backup metadata containing encryption details
  ///
  /// Throws [BackupException] if the restoration fails
  static Future<String> restoreBackup(String metadata, String key) async {
    try {
      final backupMetaData = BackupMetadata.fromJson(jsonDecode(metadata));
      debugPrint('Successfully created backup: ${backupMetaData.backupId}');

      final plaintextBytes = await EncryptionService.decrypt(
        ciphertext: Uint8List.fromList(
            HEX.decode(backupMetaData.encryptedData.ciphertext)),
        iv: Uint8List.fromList(HEX.decode(backupMetaData.encryptedData.nonce)),
        mac: backupMetaData.encryptedData.tag == null
            ? null
            : Uint8List.fromList(HEX.decode(backupMetaData.encryptedData.tag!)),
        keyBytes: Uint8List.fromList(HEX.decode(key)),
      );

      debugPrint('Successfully restored backup: ${backupMetaData.backupId}');
      return utf8.decode(plaintextBytes);
    } catch (e, stackTrace) {
      final errorMsg = 'Failed to restore backup';
      debugPrint(stackTrace.toString());
      throw BackupException(errorMsg, e);
    }
  }
}
