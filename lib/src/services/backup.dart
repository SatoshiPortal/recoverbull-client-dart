// backup_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hex/hex.dart';
import 'package:recoverbull_dart/src/models/backup_data.dart';
import 'package:recoverbull_dart/src/services/encryption.dart';
import 'package:bip39/bip39.dart' as bip39;
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
  /// This function performs the following steps:
  /// 1. Generates a random backup ID
  /// 2. Encrypts the plaintext data using AES with the provided key
  /// 3. Creates metadata containing the backup details
  ///
  /// Parameters:
  /// - [plaintext]: The data to be encrypted and backed up
  /// - [backupKey]: The encryption key as a hex string
  ///
  /// Returns:
  /// he backup metadata as a JSON string
  ///
  /// Throws:
  /// - [BackupException] if:
  ///   - The plaintext data is empty
  ///   - The encryption fails
  ///   - Metadata creation fails
  static Future<String> createBackup(String plaintext, String backupKey) async {
    try {
      final backupId = HEX.encode(generateRandomSalt(length: 32));
      debugPrint('Creating backup: $backupId');
      final plainTextBytes = utf8.encode(plaintext);
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

  /// Creates an encrypted backup using BIP85 key derivation
  ///
  /// This function performs the following steps:
  /// 1. Generates a random backup ID
  /// 2. Derives an encryption key using BIP85 from the provided mnemonic and path
  /// 3. Encrypts the plaintext data using AES
  /// 4. Creates metadata containing the backup details
  ///
  /// Parameters:
  /// - [plaintext]: The data to be encrypted and backed up
  /// - [mnemonic]: The BIP39 mnemonic phrase used for key derivation
  /// - [derivationPath]: The BIP85 derivation path (e.g., "m/83696968'/0'/0'")
  /// - [network]: Optional network type ("mainnet" or "testnet", defaults to "mainnet")
  ///
  /// Returns:
  /// A tuple containing:
  /// - First element: The derived backup key as a hex string
  /// - Second element: The backup metadata as a JSON string
  ///
  /// Throws:
  /// - [BackupException] if:
  ///   - The plaintext data is empty
  ///   - Key derivation fails
  ///   - Encryption fails
  ///   - Metadata creation fails
  static Future<(String, String)> createBackupWithBIP85(
      {required String plaintext,
      required String mnemonic,
      required String derivationPath,
      String? network}) async {
    try {
      final backupId = HEX.encode(generateRandomSalt(length: 32));
      debugPrint('Creating backup: $backupId');
      final plainTextBytes = utf8.encode(plaintext);
      if (plainTextBytes.isEmpty) {
        throw BackupException('Backup data cannot be empty');
      }
      final extendedPrivateKey = await ExtendedPrivateKey.fromString(
          mnemonic: mnemonic, networkType: network.networkType);

      final backupKey =
          deriveBip85(xprv: extendedPrivateKey.xprv, path: derivationPath);
      // Encrypt the data
      final encResult = await EncryptionService.aesEncrypt(
          Uint8List.fromList(backupKey), plainTextBytes);

      final metadata = BackupMetadata(
          backupId: backupId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          encryptedData: encResult);
      final metadataJson = jsonEncode(metadata.toJson());
      debugPrint(
          'Successfully created backup: ${jsonDecode(metadataJson)["backupId"]}');

      return (HEX.encode(backupKey), metadataJson);
    } catch (e, stackTrace) {
      final errorMsg = 'Failed to create backup';
      debugPrint(stackTrace.toString());
      throw BackupException(errorMsg, e);
    }
  }

  /// Restores data from an encrypted backup using a provided key
  ///
  /// This function performs the following steps:
  /// 1. Parses the provided metadata JSON
  /// 2. Extracts encryption parameters from the metadata
  /// 3. Decrypts the data using the provided key
  /// 4. Converts the decrypted bytes back to a string
  ///
  /// Parameters:
  /// - [metadata]: A JSON string containing the backup metadata, including:
  ///   - Backup ID
  ///   - Creation timestamp
  ///   - Encrypted data details (ciphertext, nonce, tag)
  /// - [key]: The encryption key as a hex string used for decryption
  ///
  /// Returns:
  /// The decrypted plaintext as a string
  ///
  /// Throws:
  /// - [BackupException] if:
  ///   - The metadata JSON is invalid
  ///   - The decryption key is invalid
  ///   - The decryption process fails
  ///   - The decrypted data cannot be converted to a string
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

  /// Restores data from an encrypted backup using BIP85 key derivation
  ///
  /// This function performs the following steps:
  /// 1. Parses the provided metadata JSON
  /// 2. Derives the decryption key using BIP85 from the provided mnemonic and path
  /// 3. Decrypts the data using the derived key
  /// 4. Converts the decrypted bytes back to a string
  ///
  /// Parameters:
  /// - [metadata]: A JSON string containing the backup metadata, including:
  ///   - Backup ID
  ///   - Creation timestamp
  ///   - Encrypted data details (ciphertext, nonce, tag)
  /// - [mnemonic]: The BIP39 mnemonic phrase used for key derivation
  /// - [derivationPath]: The BIP85 derivation path used during backup creation
  /// - [network]: Optional network type ("mainnet" or "testnet", defaults to "mainnet")
  ///
  /// Returns:
  /// The decrypted plaintext as a string
  ///
  /// Throws:
  /// - [BackupException] if:
  ///   - The metadata JSON is invalid
  ///   - The mnemonic is invalid
  ///   - Key derivation fails
  ///   - The decryption process fails
  ///   - The decrypted data cannot be converted to a string
  static Future<String> restoreBackupFromBip85({
    required String metadata,
    required String mnemonic,
    required String derivationPath,
    String? network,
  }) async {
    try {
      // Parse the backup metadata
      final backupMetaData = BackupMetadata.fromJson(jsonDecode(metadata));
      debugPrint('Restoring backup: ${backupMetaData.backupId}');

      // Derive the backup key using BIP85
      final extendedPrivateKey = await ExtendedPrivateKey.fromString(
        mnemonic: mnemonic,
        networkType: network.networkType,
      );

      final backupKey = deriveBip85(
        xprv: extendedPrivateKey.xprv,
        path: derivationPath,
      );

      // Decrypt the data using the derived key
      final plaintextBytes = await EncryptionService.decrypt(
        ciphertext: Uint8List.fromList(
          HEX.decode(backupMetaData.encryptedData.ciphertext),
        ),
        iv: Uint8List.fromList(
          HEX.decode(backupMetaData.encryptedData.nonce),
        ),
        mac: backupMetaData.encryptedData.tag == null
            ? null
            : Uint8List.fromList(HEX.decode(backupMetaData.encryptedData.tag!)),
        keyBytes: Uint8List.fromList(backupKey),
      );

      debugPrint('Successfully restored backup: ${backupMetaData.backupId}');
      return utf8.decode(plaintextBytes);
    } catch (e, stackTrace) {
      final errorMsg = 'Failed to restore backup using: $derivationPath';
      debugPrint(stackTrace.toString());
      throw BackupException(errorMsg, e);
    }
  }
}

class ExtendedPrivateKey {
  final String xprv;
  final bip32.NetworkType networkType;

  ExtendedPrivateKey({required this.xprv, required this.networkType});

  static Future<ExtendedPrivateKey> fromString({
    required String mnemonic,
    required bip32.NetworkType networkType,
    String password = '',
  }) async {
    if (!bip39.validateMnemonic(mnemonic)) {
      throw BackupException('Invalid mnemonic');
    }

    try {
      final seed = bip39.mnemonicToSeed(mnemonic, passphrase: password);

      final master = bip32.BIP32.fromSeed(seed, networkType);

      return ExtendedPrivateKey(
        xprv: master.toBase58(),
        networkType: networkType,
      );
    } catch (e) {
      throw BackupException('Failed to create extended private key: $e');
    }
  }
}
