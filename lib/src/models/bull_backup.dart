import 'dart:convert';

import 'package:hex/hex.dart';
import 'package:recoverbull/src/models/exceptions.dart';

// Represents data associated with an encrypted backup.
class BullBackup {
  /// Maximum UTF-8 encoded JSON accepted for a backup.
  static const maxJsonBytes = 2 * 1024 * 1024;

  /// Maximum encoded nonce + ciphertext + HMAC container size.
  static const maxCiphertextBytes = 1024 * 1024;

  /// Maximum plaintext that fits in [maxCiphertextBytes]. AES-CBC/PKCS7 adds
  /// one 16-byte padding block even when the plaintext is block-aligned.
  static const maxPlaintextBytes = maxCiphertextBytes - 16 - 32 - 16;

  /// Unix timestamp (in seconds) when the backup was created
  final int createdAt;

  /// Hex encoded Unique id for the backup
  final List<int> id;

  /// Base64 encoded nonce + ciphertext + HMac
  final List<int> ciphertext;

  /// Hex encoded salt may be used for password key derivation (Argon2)
  final List<int> salt;

  /// Can be used to store the BIP85 derivation path of the backup key
  final String? path;

  /// Creates a new [BullBackup] instance.
  const BullBackup({
    required this.createdAt,
    required this.id,
    required this.ciphertext,
    required this.salt,
    this.path,
  });

  factory BullBackup.fromMap(Map<String, dynamic> map) {
    final version = map['version'];
    if (version != null && version != 1) {
      throw RecoverBullException('Unsupported backup format version');
    }

    final createdAt = map['created_at'];
    if (createdAt is! num) {
      throw RecoverBullException('Invalid created_at type');
    }

    final idValue = map['id'];
    if (idValue is! String) {
      throw RecoverBullException('Invalid backup id type');
    }
    final id = HEX.decode(idValue);
    if (id.length != 32) {
      throw RecoverBullException('Backup id must be 32 bytes');
    }

    final saltValue = map['salt'];
    if (saltValue is! String) {
      throw RecoverBullException('Invalid backup salt type');
    }
    final salt = HEX.decode(saltValue);
    if (salt.length != 16) {
      throw RecoverBullException('Backup salt must be 16 bytes');
    }

    final ciphertextValue = map['ciphertext'];
    if (ciphertextValue is! String) {
      throw RecoverBullException('Invalid ciphertext type');
    }
    final ciphertext = base64.decode(ciphertextValue);
    if (ciphertext.length < 16 + 16 + 32 ||
        ciphertext.length > maxCiphertextBytes ||
        (ciphertext.length - 16 - 32) % 16 != 0) {
      throw RecoverBullException('Invalid encrypted data size');
    }

    final pathValue = map['path'];
    if (pathValue != null && pathValue is! String) {
      throw RecoverBullException('Invalid backup path type');
    }

    return BullBackup(
      createdAt: createdAt.toInt(),
      id: id,
      ciphertext: ciphertext,
      salt: salt,
      path: pathValue as String?,
    );
  }

  factory BullBackup.fromJson(String json) {
    try {
      if (utf8.encode(json).length > maxJsonBytes) {
        throw RecoverBullException('Backup JSON exceeds $maxJsonBytes bytes');
      }
      final map = jsonDecode(json);
      if (map is! Map<String, dynamic>) {
        throw RecoverBullException('Backup JSON must be an object');
      }
      return BullBackup.fromMap(map);
    } catch (e) {
      throw RecoverBullException('Invalid backup data format: ${e.toString()}');
    }
  }

  /// Converts this [BullBackup] instance to a map.
  Map<String, dynamic> toMap() {
    return {
      'version': 1,
      'created_at': createdAt,
      'id': HEX.encode(id),
      'ciphertext': base64.encode(ciphertext),
      'salt': HEX.encode(salt),
      'path': path,
    };
  }

  /// Converts this [BullBackup] instance to a JSON string.
  String toJson() => jsonEncode(toMap());

  static bool isValid(String input) {
    try {
      BullBackup.fromJson(input);
      return true;
    } catch (_) {
      return false;
    }
  }
}
