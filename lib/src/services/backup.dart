import 'dart:convert';
import 'package:hex/hex.dart';
import 'package:recoverbull/recoverbull.dart';
import 'package:recoverbull/src/models/exceptions.dart';
import 'package:recoverbull/src/services/encryption.dart';

/// BackupService helps you to create and restore bull backups
class BackupService {
  /// Creates an encrypted backup of your [plaintext] content
  /// using a provided [backupKey] for the encryption
  ///
  /// Parameters:
  /// - `plaintext` - The data to be encrypted and backed up
  /// - `backupKey` - The encryption key
  static Future<String> createBackup({
    required String plaintext,
    required List<int> backupKey,
  }) async {
    try {
      final plainTextBytes = utf8.encode(plaintext);
      if (plainTextBytes.isEmpty) {
        throw BackupException('Backup data cannot be empty');
      }

      if (backupKey.length < 32) {
        throw BackupException('32 bytes expected for the backup key');
      }

      final encryptionResult =
          await EncryptionService.encrypt(backupKey, plainTextBytes);

      // Create and encode backup
      final backup = Backup(
        backupId: HEX.encode(generateRandomBytes(length: 32)),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        nonce: encryptionResult.nonce,
        ciphertext: encryptionResult.ciphertext,
        mac: encryptionResult.mac,
        // may be used with Argon2
        salt: HEX.encode(generateRandomBytes(length: 16)),
      );

      return json.encode(backup.toJson());
    } catch (e) {
      if (e is BackupException) rethrow;
      throw BackupException('Failed to create backup: ${e.toString()}');
    }
  }

  /// Creates an encrypted backup using mnemonic phrase and
  /// BIP85 derivation path to generate the backup key
  ///
  /// Parameters:
  /// - `plaintext` - The data to be encrypted and backed up
  /// - `mnemonic` - The BIP39 mnemonic phrase used for key derivation
  /// - `derivationPath` - The BIP85 derivation path
  /// - `language` - The BIP39 language of the mnemonic
  /// - `network` - Optional network type ("mainnet" or "testnet", defaults to "mainnet")
  static Future<String> createBackupWithBIP85({
    required String plaintext,
    required String mnemonic,
    required String derivationPath,
    String language = 'english',
    String? network,
  }) async {
    try {
      final plainTextBytes = utf8.encode(plaintext);
      if (plainTextBytes.isEmpty) {
        throw BackupException('Backup data cannot be empty');
      }

      final extendedPrivateKey = await getRootXprv(
        language: language.bip39Language,
        mnemonic: mnemonic,
        networkType: network.networkType,
      );

      final List<int> backupKey = deriveBip85(
        xprv: extendedPrivateKey,
        path: derivationPath,
      );

      final backup = await BackupService.createBackup(
        plaintext: plaintext,
        backupKey: backupKey,
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
  static Future<String> restoreBackup(
    String backup,
    List<int> backupKey,
  ) async {
    try {
      final backupMetadata = Backup.fromString(backup);

      List<int> ciphertext, nonce, mac;
      try {
        ciphertext = HEX.decode(backupMetadata.ciphertext);
        nonce = HEX.decode(backupMetadata.nonce);
        mac = HEX.decode(backupMetadata.mac);
      } catch (e) {
        throw BackupException('Invalid encrypted data format: ${e.toString()}');
      }

      final plaintextBytes = await EncryptionService.decrypt(
        ciphertext: ciphertext,
        nonce: nonce,
        mac: mac,
        keyBytes: backupKey,
      );

      try {
        final plaintext = utf8.decode(plaintextBytes);
        return plaintext;
      } catch (e) {
        throw BackupException('Data is not valid UTF-8: ${e.toString()}');
      }
    } catch (e) {
      if (e is BackupException) rethrow;
      throw BackupException('Failed to restore backup: ${e.toString()}');
    }
  }

  /// Restores data from an encrypted backup using a provided backup key
  ///
  /// Parameters:
  /// - `backup` JSON string encoding the encrypted backup
  /// - `mnemonic` - BIP39 mnemonic phrase for key derivation
  /// - `derivationPath` - BIP85 derivation path
  /// - `network` - Optional network type ("mainnet" or "testnet", defaults to "mainnet")
  /// - `language` - BIP39 language of the mnemonic
  static Future<String> restoreBackupFromBip85({
    required String backup,
    required String mnemonic,
    required String derivationPath,
    String? network,
    String language = 'english',
  }) async {
    try {
      final extendedPrivateKey = await getRootXprv(
        mnemonic: mnemonic,
        language: language.bip39Language,
        networkType: network.networkType,
      );

      final backupKey = deriveBip85(
        xprv: extendedPrivateKey,
        path: derivationPath,
      );

      final plaintext = restoreBackup(backup, backupKey);
      return plaintext;
    } catch (e) {
      if (e is BackupException) rethrow;
      throw BackupException(
        'Failed to restore backup using path $derivationPath: ${e.toString()}',
      );
    }
  }
}
