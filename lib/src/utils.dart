import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39_mnemonic/bip39_mnemonic.dart' as bip39;
import 'package:bip85/bip85.dart';
import 'package:hex/hex.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:recoverbull/recoverbull.dart';

Uint8List generateRandomSalt({int length = 32}) {
  final secureRandom = Random.secure();
  final saltBytes = Uint8List(length);
  for (int i = 0; i < length; i++) {
    saltBytes[i] = secureRandom.nextInt(256);
  }
  return saltBytes;
}

List<int> deriveBip85({required String xprv, required String path}) {
  //TODO: Implement actual derivation logic
  // This is a dummy implementation for demonstration purposes.
  //
  //TODO; Finalize the derivation key length
  try {
    final derived = derive(xprv: xprv, path: path).sublist(0, 32);
    return derived;
  } catch (e) {
    throw BackupException('Failed to derive backup key: ${e.toString()}');
  }
}

//TODO; verify if both netowrktype values are correct
extension Bip32NetworkTypeParser on String? {
  bip32.NetworkType get networkType {
    return (this == "mainnet" || this == null)
        ? bip32.NetworkType(
            wif: 0x80,
            bip32: bip32.Bip32Type(
              public: 0x0488b21e,
              private: 0x0488ade4,
            ),
          )
        : bip32.NetworkType(
            wif: 0xef,
            bip32: bip32.Bip32Type(
              public: 0x043587cf,
              private: 0x04358394,
            ),
          );
  }
}

/// Converts a string language identifier to a BIP39 language
///
/// Supported languages:
/// - english
/// - japanese
/// - korean
/// - spanish
/// - chinese_simplified
/// - chinese_traditional
/// - french
/// - italian
/// - czech
/// - portuguese
///
/// Returns bip39.Language.english; if language is not supported
extension StringToBip39Language on String {
  /// Converts string to BIP39 Language
  /// Returns the corresponding Language or English as default
  bip39.Language get bip39Language {
    switch (toLowerCase()) {
      case 'english':
        return bip39.Language.english;
      case 'japanese':
        return bip39.Language.japanese;
      case 'korean':
        return bip39.Language.korean;
      case 'spanish':
        return bip39.Language.spanish;
      case 'simplifiedchinese':
        return bip39.Language.simplifiedChinese;
      case 'traditionalchinese':
        return bip39.Language.traditionalChinese;
      case 'french':
        return bip39.Language.french;
      case 'italian':
        return bip39.Language.italian;
      case 'czech':
        return bip39.Language.czech;
      case 'portuguese':
        return bip39.Language.portuguese;
      default:
        return bip39.Language.english;
    }
  }

  /// Checks if the string represents a valid BIP39 language identifier
  bool isValidBip39Language() {
    return bip39.Language.values
        .map((e) => e.toString().toLowerCase())
        .contains(toLowerCase());
  }
}

extension BackupMetadataParser on String {
  BackupMetadata parseMetadata() {
    try {
      return BackupMetadata.fromJson(jsonDecode(this));
    } catch (e) {
      throw BackupException('Invalid backup metadata format: ${e.toString()}');
    }
  }
}

/// Extension for secret hashing operations
extension SecretHasher on String {
  String toSHA256Hash() {
    final bytes = utf8.encode(this);
    final digest = SHA256Digest().process(Uint8List.fromList(bytes));
    return HEX.encode(digest);
  }
}
