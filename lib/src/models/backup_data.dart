import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:recoverbull_dart/src/models/encrypted_data.dart';
part 'backup_data.freezed.dart';
part 'backup_data.g.dart';

// Represents metadata associated with an encrypted backup.
///
/// This class stores essential information about a backup, including version,
/// identifiers, timestamps, and encryption-related data.
@freezed
class BackupMetadata with _$BackupMetadata {
  /// Creates a new [BackupMetadata] instance.
  const factory BackupMetadata({
    /// Unique identifier for the backup
    required String backupId,

    /// Encryption data used to secure the backup
    required EncryptedData encryptedData,

    /// Unix timestamp (in seconds) when the backup was created
    required int createdAt,
  }) = _BackupMetadata;

  /// Creates a [BackupMetadata] instance from a JSON map.
  ///
  /// The JSON map must contain all required fields with appropriate types.
  factory BackupMetadata.fromJson(Map<String, dynamic> json) =>
      _$BackupMetadataFromJson(json);
}
