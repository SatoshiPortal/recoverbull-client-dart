import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:recoverbull/src/models/exceptions.dart';
part 'backup.freezed.dart';
part 'backup.g.dart';

// Represents data associated with an encrypted backup.
///
/// This class stores essential information about a backup, including version,
/// identifiers, timestamps, and encryption-related data.
@freezed
class Backup with _$Backup {
  /// Creates a new [Backup] instance.
  const factory Backup({
    /// Unix timestamp (in seconds) when the backup was created
    required int createdAt,

    /// Unique identifier for the backup
    required String backupId,

    /// Hex encoded nonce used for backup file encryption
    required String nonce,

    /// Encryption data used to secure the backup
    required String ciphertext,

    /// Hex encoded salt may be used for password key derivation (Argon2)
    required String salt,

    /// - [mac]: Optional authentication mac for the encrypted data
    required String mac,
  }) = _Backup;

  /// Creates a [Backup] instance from a JSON map.
  ///
  /// The JSON map must contain all required fields with appropriate types.
  factory Backup.fromJson(Map<String, dynamic> json) => _$BackupFromJson(json);

  factory Backup.fromString(String data) {
    try {
      return Backup.fromJson(json.decode(data));
    } catch (e) {
      throw BackupException('Invalid backup data format: ${e.toString()}');
    }
  }
}
