import 'package:freezed_annotation/freezed_annotation.dart';
part 'backup_data.freezed.dart';
part 'backup_data.g.dart';

// Represents metadata associated with an encrypted backup.
///
/// This class stores essential information about a backup, including version,
/// identifiers, timestamps, and encryption-related data.
@freezed
class BackupMetadata with _$BackupMetadata {
  /// Creates a new [BackupMetadata] instance.
  ///
  /// Parameters:
  /// - [version]: The schema version of the backup metadata (defaults to 1)
  /// - [backupId]: Unique identifier for this backup
  /// - [keyId]: Identifier for the encryption key used
  /// - [createdAt]: Unix timestamp (in seconds) when the backup was created
  /// - [nonce]: Cryptographic nonce used for encryption
  /// - [ciphertext]: The encrypted backup data
  /// - [tag]: Optional authentication tag for the encrypted data
  factory BackupMetadata({
    @Default(1) int version,
    required String backupId,
    required String keyId,
    required int createdAt,
    required String nonce,
    required String ciphertext,
    String? tag,
  }) = _BackupMetadata;
  BackupMetadata._();

  /// Creates a [BackupMetadata] instance from a JSON map.
  ///
  /// The JSON map must contain all required fields with appropriate types.
  factory BackupMetadata.fromJson(Map<String, dynamic> json) =>
      _$BackupMetadataFromJson(json);
}
