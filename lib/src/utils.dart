import 'dart:math';
import 'dart:typed_data';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39_mnemonic/bip39_mnemonic.dart' as bip39;
import 'package:bip85/bip85.dart';
import 'package:hex/hex.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:recoverbull/src/models/exceptions.dart';

Uint8List generateRandomBytes({int length = 32}) {
  final secureRandom = Random.secure();
  final bytes = Uint8List(length);
  for (int i = 0; i < length; i++) {
    bytes[i] = secureRandom.nextInt(256);
  }
  return bytes;
}

List<int> deriveBip85({required String xprv, required String path}) {
  try {
    final derived = derive(xprv: xprv, path: path).sublist(0, 32);
    return derived;
  } catch (e) {
    throw BackupException('Failed to derive backup key: ${e.toString()}');
  }
}

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

String sha256Hex(List<int> bytes) {
  final digest = SHA256Digest().process(Uint8List.fromList(bytes));
  return HEX.encode(digest);
}

// Constant-time comparison to prevent timing attacks
bool constantTimeComparison(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var result = 0;
  for (var i = 0; i < a.length; i++) {
    result |= a[i] ^ b[i];
  }
  return result == 0;
}

Future<String> getRootXprv({
  required String mnemonic,
  required bip32.NetworkType networkType,
  String password = '',
  required bip39.Language language,
}) async {
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

    return master.toBase58();
  } catch (e) {
    throw BackupException('Failed to create extended private key: $e');
  }
}
