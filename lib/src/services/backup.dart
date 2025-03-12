import 'dart:convert';
import 'package:hex/hex.dart';
import 'package:recoverbull/recoverbull.dart';
import 'package:recoverbull/src/services/encryption.dart';

/// BackupService helps you to create and restore bull backups
class BackupService {
  /// Creates an encrypted backup of your [secret] content
  /// using a provided [backupKey] for the encryption
  ///
  /// Parameters:
  /// - `secret` - The bytes of your plaintext to encrypt
  /// - `backupKey` - The encryption key
  static BullBackup createBackup({
    required List<int> secret,
    required List<int> backupKey,
    DateTime? createdAt,
  }) {
    createdAt ??= DateTime.now().toUtc();

    try {
      if (secret.isEmpty) {
        throw BackupException('Backup data cannot be empty');
      }

      if (backupKey.length < 32) {
        throw BackupException('32 bytes expected for the backup key');
      }

      final encryption = EncryptionService.encrypt(
        key: backupKey,
        plaintext: secret,
      );

      final encryptionEncoded = EncryptionService.mergeBytes(encryption);

      // Create and encode backup
      final backup = BullBackup(
        id: generateRandomBytes(length: 32),
        createdAt: createdAt.millisecondsSinceEpoch,
        ciphertext: encryptionEncoded,
        salt: generateRandomBytes(length: 16),
      );

      return backup;
    } catch (e) {
      if (e is BackupException) rethrow;
      throw BackupException('Failed to create backup: ${e.toString()}');
    }
  }

  /// Restores data from an encrypted backup using a provided backup key
  ///
  /// Parameters:
  /// - `backup` JSON string encoding the encrypted backup
  /// - `backupkey` encryption key to decrypt the backup
  static List<int> restoreBackup({
    required BullBackup backup,
    required List<int> backupKey,
  }) {
    try {
      Encryption encryption;
      try {
        final ciphertextBytes = backup.ciphertext;
        encryption = EncryptionService.splitBytes(ciphertextBytes);
      } catch (e) {
        throw BackupException('Invalid encrypted data format: ${e.toString()}');
      }

      final plaintextBytes = EncryptionService.decrypt(
        ciphertext: encryption.ciphertext,
        nonce: encryption.nonce,
        key: backupKey,
        hmac: encryption.hmac,
      );

      try {
        return plaintextBytes;
      } catch (e) {
        throw BackupException('Data is not valid UTF-8: ${e.toString()}');
      }
    } catch (e) {
      if (e is BackupException) rethrow;
      throw BackupException('Failed to restore backup: ${e.toString()}');
    }
  }
}
