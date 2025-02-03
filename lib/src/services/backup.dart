import 'dart:convert';
import 'package:hex/hex.dart';
import 'package:recoverbull/recoverbull.dart';
import 'package:recoverbull/src/models/exceptions.dart';
import 'package:recoverbull/src/services/encryption.dart';

/// BackupService helps you to create and restore bull backups
class BackupService {
  /// Creates an encrypted backup of your [secret] content
  /// using a provided [backupKey] for the encryption
  ///
  /// Parameters:
  /// - `secret` - The bytes of your plaintext to encrypt
  /// - `backupKey` - The encryption key
  static String createBackup({
    required List<int> secret,
    required List<int> backupKey,
  }) {
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

      final encryptionEncoded = EncryptionService.encode(encryption);

      // Create and encode backup
      final backup = Backup(
        id: HEX.encode(generateRandomBytes(length: 32)),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        ciphertext: base64.encode(encryptionEncoded),
        // may be used with Argon2
        salt: HEX.encode(generateRandomBytes(length: 16)),
      );

      return backup.toJson();
    } catch (e) {
      if (e is BackupException) rethrow;
      throw BackupException('Failed to create backup: ${e.toString()}');
    }
  }

  /// Creates an encrypted backup using mnemonic phrase and
  /// BIP85 derivation path to generate the backup key
  ///
  /// Parameters:
  /// - `secret` - The data to be encrypted and backed up
  /// - `mnemonic` - The BIP39 mnemonic phrase used for key derivation
  /// - `derivationPath` - The BIP85 derivation path
  /// - `language` - The BIP39 language of the mnemonic
  /// - `network` - Optional network type ("mainnet" or "testnet", defaults to "mainnet")
  static String createBackupWithBIP85({
    required List<int> secret,
    required String mnemonic,
    required String derivationPath,
    String language = 'english',
    String? network,
  }) {
    try {
      if (secret.isEmpty) {
        throw BackupException('Backup data cannot be empty');
      }

      final extendedPrivateKey = getRootXprv(
        language: language.bip39Language,
        mnemonic: mnemonic,
        networkType: network.networkType,
      );

      final List<int> backupKey = deriveBip85(
        xprv: extendedPrivateKey,
        path: derivationPath,
      );

      final backup = BackupService.createBackup(
        secret: secret,
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
  static String restoreBackup({
    required String backup,
    required List<int> backupKey,
  }) {
    try {
      final theBackup = Backup.fromJson(backup);

      Encryption encryption;
      try {
        final ciphertextBytes = base64.decode(theBackup.ciphertext);
        encryption = EncryptionService.decode(ciphertextBytes);
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
  static String restoreBackupFromBip85({
    required String backup,
    required String mnemonic,
    required String derivationPath,
    String? network,
    String language = 'english',
  }) {
    try {
      final extendedPrivateKey = getRootXprv(
        mnemonic: mnemonic,
        language: language.bip39Language,
        networkType: network.networkType,
      );

      final backupKey = deriveBip85(
        xprv: extendedPrivateKey,
        path: derivationPath,
      );

      final plaintext = restoreBackup(backup: backup, backupKey: backupKey);
      return plaintext;
    } catch (e) {
      if (e is BackupException) rethrow;
      throw BackupException(
        'Failed to restore backup using path $derivationPath: ${e.toString()}',
      );
    }
  }
}
