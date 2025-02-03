import 'dart:convert';

import 'package:recoverbull/src/models/exceptions.dart';

// Represents data associated with an encrypted backup.

class Backup {
  /// Unix timestamp (in seconds) when the backup was created
  final int createdAt;

  /// Hex encoded Unique identifier for the backup
  final String id;

  /// Base64 encoded nonce + ciphertext + HMac
  final String ciphertext;

  /// Hex encoded salt may be used for password key derivation (Argon2)
  final String salt;

  /// Creates a new [Backup] instance.
  const Backup({
    required this.createdAt,
    required this.id,
    required this.ciphertext,
    required this.salt,
  });

  factory Backup.fromMap(Map<String, dynamic> map) {
    return Backup(
      createdAt: (map['createdAt'] as num).toInt(),
      id: map['id'] as String,
      ciphertext: map['ciphertext'] as String,
      salt: map['salt'] as String,
    );
  }

  factory Backup.fromJson(String json) {
    try {
      final map = jsonDecode(json);
      return Backup.fromMap(map);
    } catch (e) {
      throw BackupException('Invalid backup data format: ${e.toString()}');
    }
  }

  /// Converts this [Backup] instance to a map.
  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt,
      'id': id,
      'ciphertext': ciphertext,
      'salt': salt,
    };
  }

  /// Converts this [Backup] instance to a JSON string.
  String toJson() => jsonEncode(toMap());
}
