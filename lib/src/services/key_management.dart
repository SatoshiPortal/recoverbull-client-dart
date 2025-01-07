import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/key_info.dart';

/// Custom exception for key management operations
class KeyManagementException implements Exception {
  final String message;
  final dynamic cause;

  KeyManagementException(this.message, [this.cause]);

  @override
  String toString() =>
      'KeyManagementException: $message${cause != null ? ' ($cause)' : ''}';
}

/// Service responsible for secure key management operations
class KeyManagementService {
  static const _secureStorageKey = 'bullbitcoinBackupKeys';
  static const _keyStatusActive = 'active';
  static const _keyStatusExpired = 'expired';

  bool _pinVerified = false;

  final FlutterSecureStorage _storage;

  KeyManagementService()
      : _storage = FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
            sharedPreferencesName: _secureStorageKey,
          ),
          iOptions: IOSOptions(
            accountName: _secureStorageKey,
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  /// Returns whether the PIN has been verified
  bool get pinVerified => _pinVerified;

  /// Unlocks the service with a verified PIN
  void unlockWithPin() {
    _pinVerified = true;
    debugPrint('Key management service unlocked');
  }

  /// Generates and stores a new key
  ///
  /// Parameters:
  /// - [keyId]: Unique identifier for the key
  /// - [derivedKey]: The cryptographic key to store
  /// - [label]: Optional label for the key
  Future<void> writeNewKey(
    String keyId,
    List<int> derivedKey, {
    String? label,
  }) async {
    try {
      _assertPinVerified();
      _validateKeyData(keyId, derivedKey);

      // Expire current active key if exists
      await _expireCurrentActiveKey();

      // Create and store new active key
      final newKey = KeyInfo(
        keyId: keyId,
        key: derivedKey,
        status: _keyStatusActive,
        label: label,
      );

      await _secureWrite(keyId, newKey);
      debugPrint(
          'New key stored successfully: $keyId${label != null ? " ($label)" : ""}');
    } catch (e) {
      final error = 'Failed to write new key';
      debugPrint('$error: $e');
      throw KeyManagementException(error, e);
    }
  }

  /// Validates key data before storage
  void _validateKeyData(String keyId, List<int> key) {
    if (keyId.isEmpty) {
      throw KeyManagementException('Key ID cannot be empty');
    }
    if (key.isEmpty) {
      throw KeyManagementException('Key data cannot be empty');
    }
    if (key.length < 32) {
      // Minimum key length for security
      throw KeyManagementException(
          'Key length insufficient (minimum 32 bytes required)');
    }
  }

  /// Expires the current active key
  Future<void> _expireCurrentActiveKey() async {
    try {
      final currentActiveKey = await getActiveKey();
      if (currentActiveKey != null) {
        final updated = currentActiveKey.copyWith(
          status: _keyStatusExpired,
          expiredAt: DateTime.now().toIso8601String(),
        );
        await _secureWrite(currentActiveKey.keyId, updated);
        debugPrint('Expired key: ${currentActiveKey.keyId}');
      }
    } catch (e) {
      throw KeyManagementException('Failed to expire current active key', e);
    }
  }

  /// Securely writes key info to storage
  Future<void> _secureWrite(String keyId, KeyInfo keyInfo) async {
    try {
      final jsonData = jsonEncode(keyInfo.toJson());
      await _storage.write(key: keyId, value: jsonData);
    } catch (e) {
      throw KeyManagementException('Failed to write to secure storage', e);
    }
  }

  /// Retrieves the currently active key
  Future<KeyInfo?> getActiveKey() async {
    try {
      _assertPinVerified();

      final allKeys = await readAllKeys();
      if (allKeys.isEmpty) {
        debugPrint('No keys found in storage');
        return null;
      }

      final activeKeys =
          allKeys.values.where((key) => key.status == _keyStatusActive);
      if (activeKeys.isEmpty) {
        debugPrint('No active key found');
        return null;
      }

      if (activeKeys.length > 1) {
        debugPrint('Warning: Multiple active keys found');
      }

      return activeKeys.first;
    } catch (e) {
      throw KeyManagementException('Failed to get active key', e);
    }
  }

  /// Reads all stored keys
  Future<Map<String, KeyInfo>> readAllKeys() async {
    try {
      _assertPinVerified();

      final keyInfos = await _storage.readAll();
      if (keyInfos.isEmpty) {
        return {};
      }

      return Map.fromEntries(
        keyInfos.entries.map((entry) {
          try {
            return MapEntry(
              entry.key,
              KeyInfo.fromJson(jsonDecode(entry.value)),
            );
          } catch (e) {
            debugPrint('Error parsing key ${entry.key}: $e');
            return null;
          }
        }).whereType<MapEntry<String, KeyInfo>>(),
      );
    } catch (e) {
      throw KeyManagementException('Failed to read keys', e);
    }
  }

  /// Retrieves a specific key by ID
  Future<KeyInfo?> readKey(String keyId) async {
    try {
      _assertPinVerified();

      if (keyId.isEmpty) {
        throw KeyManagementException('Key ID cannot be empty');
      }

      final keyData = await _storage.read(key: keyId);
      if (keyData == null) {
        debugPrint('Key not found: $keyId');
        return null;
      }

      return KeyInfo.fromJson(jsonDecode(keyData));
    } catch (e) {
      throw KeyManagementException('Failed to read key: $keyId', e);
    }
  }

  /// Updates a key's label
  Future<void> updateKeyLabel(String keyId, String newLabel) async {
    try {
      _assertPinVerified();

      final key = await readKey(keyId);
      if (key == null) {
        throw KeyManagementException('Key not found: $keyId');
      }

      final updatedKey = key.copyWith(label: newLabel);
      await _secureWrite(keyId, updatedKey);
      debugPrint('Updated label for key: $keyId');
    } catch (e) {
      throw KeyManagementException('Failed to update key label', e);
    }
  }

  /// Deletes an expired key
  Future<void> deleteKey(String keyId) async {
    try {
      _assertPinVerified();

      final key = await readKey(keyId);
      if (key == null) {
        throw KeyManagementException('Key not found: $keyId');
      }
      if (key.status == _keyStatusActive) {
        throw KeyManagementException('Cannot delete active key');
      }

      await _storage.delete(key: keyId);
      debugPrint('Deleted key: $keyId');
    } catch (e) {
      throw KeyManagementException('Failed to delete key: $keyId', e);
    }
  }

  /// Validates PIN verification status
  void _assertPinVerified() {
    if (!_pinVerified) {
      throw KeyManagementException(
          'PIN not verified. Please verify PIN before accessing keys.');
    }
  }
}
