import 'dart:convert';

import 'package:hex/hex.dart';
import 'package:recoverbull/src/models/exceptions.dart';

// Represents data associated with an encrypted backup.

class BullBackup {
  /// Unix timestamp (in seconds) when the backup was created
  final int createdAt;

  /// Hex encoded Unique identifier for the backup
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
    return BullBackup(
      createdAt: (map['created_at'] as num).toInt(),
      id: HEX.decode(map['id'] as String),
      ciphertext: base64.decode(map['ciphertext'] as String),
      salt: HEX.decode(map['salt'] as String),
      path: map['path'] as String?,
    );
  }

  factory BullBackup.fromJson(String json) {
    try {
      final map = jsonDecode(json);
      return BullBackup.fromMap(map);
    } catch (e) {
      throw BackupException('Invalid backup data format: ${e.toString()}');
    }
  }

  /// Converts this [BullBackup] instance to a map.
  Map<String, dynamic> toMap() {
    return {
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
