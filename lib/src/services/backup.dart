// backup_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hex/hex.dart';
import 'package:recoverbull_dart/src/models/backup_data.dart';
import 'package:recoverbull_dart/src/services/encryption.dart';
import 'package:bip39_mnemonic/bip39_mnemonic.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:recoverbull_dart/src/utils.dart';

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
  /// Creates an encrypted backup using a provided backup key
  ///
  /// Encrypts plaintext data using AES encryption with the provided key and
  /// generates metadata for backup recovery.
  ///
  /// Parameters:
  /// - [plaintext] - The data to be encrypted and backed up
  /// - [backupKey] - The hex-encoded encryption key
  ///
  /// Returns the backup metadata as a JSON string containing:
  /// - Backup ID
  /// - Creation timestamp
  /// - Encrypted data
  ///
  /// Throws [BackupException] if:
  /// - The plaintext data is empty
  /// - The backup key is invalid hex
  /// - The encryption process fails
  /// - The metadata creation or encoding fails
  static Future<String> createBackup(
    String plaintext,
    String backupKey,
  ) async {
    try {
      // Validate inputs
      final plainTextBytes = utf8.encode(plaintext);
      if (plainTextBytes.isEmpty) {
        throw BackupException('Backup data cannot be empty');
      }

      // Validate and decode backup key
      Uint8List keyBytes;
      try {
        keyBytes = Uint8List.fromList(HEX.decode(backupKey));
      } catch (e) {
        throw BackupException('Invalid backup key format: must be valid hex');
      }

      // Generate backup ID and encrypt data
      final backupId = HEX.encode(generateRandomSalt(length: 32));
      debugPrint('Creating backup: $backupId');

      final encResult = await EncryptionService.aesEncrypt(
        keyBytes,
        plainTextBytes,
      );

      // Create and encode metadata
      final metadata = BackupMetadata(
        backupId: backupId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        encryptedData: encResult,
      );

      final metadataJson = jsonEncode(metadata.toJson());
      debugPrint('Successfully created backup: ${metadata.backupId}');

      return metadataJson;
    } catch (e, stackTrace) {
      debugPrint(stackTrace.toString());
      if (e is BackupException) rethrow;
      throw BackupException('Failed to create backup: ${e.toString()}');
    }
  }

  /// Creates an encrypted backup using mnemonic phrase and BIP85 derivation path.
  /// The backup includes encrypted data and metadata for recovery.
  ///
  /// Parameters:
  /// - [plaintext] - The data to be encrypted and backed up
  /// - [mnemonic] - The BIP39 mnemonic phrase used for key derivation
  /// - [derivationPath] - The BIP85 derivation path (e.g., "m/83696968'/0'/0'")
  /// - [language] - The BIP39 language of the mnemonic (defaults to 'english')
  /// - [network] - Optional network type ("mainnet" or "testnet", defaults to "mainnet")
  ///
  /// Returns a tuple containing:
  /// - The derived backup key as a hex string
  /// - The backup metadata as a JSON string
  ///
  /// Throws [BackupException] if:
  /// - The plaintext data is empty
  /// - The mnemonic contains invalid words for the specified language
  /// - Key derivation fails
  /// - Encryption fails
  /// - Metadata creation fails
  static Future<(String, String)> createBackupWithBIP85({
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

      final extendedPrivateKey = await ExtendedPrivateKey.fromString(
          language: language.bip39Language,
          mnemonic: mnemonic,
          networkType: network.networkType);

      // Generate backup ID
      final backupId = HEX.encode(generateRandomSalt(length: 32));
      debugPrint('Creating backup: $backupId');

      // Derive backup key and encrypt data
      final Uint8List backupKey = Uint8List.fromList(deriveBip85(
        xprv: extendedPrivateKey.xprv,
        path: derivationPath,
      ));
      // Encrypt the data
      final encResult =
          await EncryptionService.aesEncrypt(backupKey, plainTextBytes);

      final metadata = BackupMetadata(
          backupId: backupId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          encryptedData: encResult);
      final metadataJson = jsonEncode(metadata.toJson());
      debugPrint(
          'Successfully created backup: ${jsonDecode(metadataJson)["backupId"]}');

      return (HEX.encode(backupKey), metadataJson);
    } catch (e, stackTrace) {
      debugPrint(stackTrace.toString());
      if (e is BackupException) rethrow;
      throw BackupException('Failed to create backup: ${e.toString()}');
    }
  }

  /// Restores data from an encrypted backup using a provided key
  ///
  /// Parameters:
  /// - [metadata] - JSON string containing the backup metadata with:
  ///   • Backup ID
  ///   • Creation timestamp
  ///   • Encrypted data (ciphertext, nonce, tag)
  /// - [key] - Hex-encoded decryption key
  ///
  /// Returns the decrypted data as a UTF-8 string
  ///
  /// Throws [BackupException] if:
  /// - The metadata JSON is invalid or malformed
  /// - The decryption key is invalid hex
  /// - The encrypted data components are invalid hex
  /// - The decryption process fails
  /// - The decrypted data is not valid UTF-8
  static Future<String> restoreBackup(
    String metadata,
    String key,
  ) async {
    try {
      // Parse and validate metadata
      final BackupMetadata backupMetadata = metadata.parseMetadata();

      debugPrint('Restoring backup: ${backupMetadata.backupId}');

      // Validate and decode key
      Uint8List keyBytes;
      try {
        keyBytes = Uint8List.fromList(HEX.decode(key));
      } catch (e) {
        throw BackupException(
            'Invalid decryption key format: must be valid hex');
      }

      // Decode encrypted components
      Uint8List ciphertext;
      Uint8List iv;
      Uint8List? mac;
      try {
        ciphertext = Uint8List.fromList(
          HEX.decode(backupMetadata.encryptedData.ciphertext),
        );
        iv = Uint8List.fromList(
          HEX.decode(backupMetadata.encryptedData.nonce),
        );
        if (backupMetadata.encryptedData.tag != null) {
          mac = Uint8List.fromList(
            HEX.decode(backupMetadata.encryptedData.tag!),
          );
        }
      } catch (e) {
        throw BackupException('Invalid encrypted data format: ${e.toString()}');
      }

      // Decrypt data
      final plaintextBytes = await EncryptionService.decrypt(
        ciphertext: ciphertext,
        iv: iv,
        mac: mac,
        keyBytes: keyBytes,
      );

      // Convert to string
      try {
        final plaintext = utf8.decode(plaintextBytes);
        debugPrint('Successfully restored backup: ${backupMetadata.backupId}');
        return plaintext;
      } catch (e) {
        throw BackupException(
            'Decrypted data is not valid UTF-8: ${e.toString()}');
      }
    } catch (e, stackTrace) {
      debugPrint(stackTrace.toString());
      if (e is BackupException) rethrow;
      throw BackupException('Failed to restore backup: ${e.toString()}');
    }
  }

  /// Restores data from mnemonic, passphrase and path,
  ///
  /// Parameters:
  /// - [metadata] - JSON string containing the backup metadata with:
  ///   • Backup ID
  ///   • Creation timestamp
  ///   • Encrypted data (ciphertext, nonce, tag)
  /// - [mnemonic] - BIP39 mnemonic phrase for key derivation
  /// - [derivationPath] - BIP85 derivation path (e.g., "m/83696968'/0'/0'")
  /// - [network] - Optional network type ("mainnet" or "testnet", defaults to "mainnet")
  /// - [language] - BIP39 language of the mnemonic (defaults to 'english')
  ///
  /// Returns the decrypted data as a UTF-8 string
  ///
  /// Throws [BackupException] if:
  /// - The metadata JSON is invalid or malformed
  /// - The mnemonic contains invalid words for the specified language
  /// - The derivation path is invalid
  /// - The encrypted data components are invalid hex
  /// - The decryption process fails
  /// - The decrypted data is not valid UTF-8
  static Future<String> restoreBackupFromBip85({
    required String metadata,
    required String mnemonic,
    required String derivationPath,
    String? network,
    String language = 'english',
  }) async {
    try {
      // Parse and validate metadata
      final BackupMetadata backupMetadata = metadata.parseMetadata();

      debugPrint('Restoring backup: ${backupMetadata.backupId}');

      // Validate mnemonic and derive key
      final extendedPrivateKey = await ExtendedPrivateKey.fromString(
        mnemonic: mnemonic,
        language: language.bip39Language,
        networkType: network.networkType,
      );

      // Derive backup key
      final Uint8List backupKey = Uint8List.fromList(deriveBip85(
        xprv: extendedPrivateKey.xprv,
        path: derivationPath,
      ));

      // Decode encrypted components
      Uint8List ciphertext;
      Uint8List iv;
      Uint8List? mac;
      try {
        ciphertext = Uint8List.fromList(
          HEX.decode(backupMetadata.encryptedData.ciphertext),
        );
        iv = Uint8List.fromList(
          HEX.decode(backupMetadata.encryptedData.nonce),
        );
        if (backupMetadata.encryptedData.tag != null) {
          mac = Uint8List.fromList(
            HEX.decode(backupMetadata.encryptedData.tag!),
          );
        }
      } catch (e) {
        throw BackupException('Invalid encrypted data format: ${e.toString()}');
      }

      // Decrypt data
      final plaintextBytes = await EncryptionService.decrypt(
        ciphertext: ciphertext,
        iv: iv,
        mac: mac,
        keyBytes: backupKey,
      ).onError((error, _) {
        throw BackupException('Decryption failed: ${error.toString()}');
      });

      // Convert to string
      try {
        final plaintext = utf8.decode(plaintextBytes);
        debugPrint('Successfully restored backup: ${backupMetadata.backupId}');
        return plaintext;
      } catch (e) {
        throw BackupException(
            'Decrypted data is not valid UTF-8: ${e.toString()}');
      }
    } catch (e, stackTrace) {
      debugPrint(stackTrace.toString());
      if (e is BackupException) rethrow;
      throw BackupException(
        'Failed to restore backup using path $derivationPath: ${e.toString()}',
      );
    }
  }
}

class ExtendedPrivateKey {
  final String xprv;
  final bip32.NetworkType networkType;

  ExtendedPrivateKey({required this.xprv, required this.networkType});

  static Future<ExtendedPrivateKey> fromString(
      {required String mnemonic,
      required bip32.NetworkType networkType,
      String password = '',
      required bip39.Language language}) async {
    try {
      final invalidWords =
          mnemonic.split(' ').where((word) => !language.isValid(word)).toList();

      if (invalidWords.isNotEmpty) {
        throw BackupException(
          'Invalid words found for ${language.name} language: '
          '${invalidWords.join(", ")}',
        );
      }
      final bip39Mnemonic =
          bip39.Mnemonic.fromSentence(mnemonic, language, passphrase: password);

      final master = bip32.BIP32
          .fromSeed(Uint8List.fromList(bip39Mnemonic.seed), networkType);

      return ExtendedPrivateKey(
        xprv: master.toBase58(),
        networkType: networkType,
      );
    } catch (e) {
      throw BackupException('Failed to create extended private key: $e');
    }
  }
}
