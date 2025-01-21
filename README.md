# Recoverbull Dart

`recoverbull` is a project designed to facilitate secure backup and recovery of data using encryption and key management techniques. It supports creating encrypted backups, restoring data from backups, and managing keys with a remote server.

## Features

- Create encrypted backups using a provided backup key or BIP85 derived key
- Restore data from encrypted backups using a provided key or BIP85 derived key
- Store and recover backup keys on a remote server
- Supports BIP39 mnemonic phrases for key derivation
- Utilizes AES encryption with PKCS7 padding for secure data encryption
- Comprehensive error handling with custom exceptions

## Installation

Add `recoverbull` to your `pubspec.yaml` file:
```yaml
dependencies:
  recoverbull:
    git:
      url: https://github.com/SatoshiPortal/recoverbull-client-dart.git
      ref: main
```


## Usage Examples

### Creating a Backup

You can create backups either using a direct encryption key or BIP85 key derivation.

#### Using Direct Key

```dart
// Create a backup using a direct encryption key
void example() async {
  final plaintext = 'My secret data';
  final backupKey = '9f1b70ca6eaec7fd3478e88369b90fcffee46448252dd6f879da5bdf65fb9031';
 
  try {
    final backupJson = await BackupService.createBackup(
      plaintext,
      backupKey,
    );
    print('Backup created successfully: $backupJson');
  } catch (e) {
    print('Failed to create backup: $e');
  }
}
```

#### Using BIP85 Derivation

```dart
// Create a backup using BIP85 key derivation
void example() async {
  final plaintext = 'My secret data';
  final mnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
  final derivationPath = "m/1608'/0'";
 
  try {
    final (backupKey, backupJson) = await BackupService.createBackupWithBIP85(
      plaintext: plaintext,
      mnemonic: mnemonic,
      derivationPath: derivationPath,
      language: 'english', // optional
      network: 'mainnet', // optional
    );
   
    print('Backup created with key: $backupKey');
  } catch (e) {
    print('Failed to create backup: $e');
  }
}
```

### Key Management

The library provides a service for storing and recovering backup keys from a remote server.

```dart
// Initialize the key management service
final keyManagement = KeyManagementService(
  keychainapi: 'https://api.example.com/keychain',
);
// Store a backup key
await keyManagement.storeBackupKey(
  'backup-123',
  'your-backup-key',
  'secret-password'
);
// Recover a backup key
final recoveredKey = await keyManagement.recoverBackupKey(
  'backup-123',
  'secret-password'
);
```


### Complete Backup Workflow

Here's a complete example showing how to create a backup, store the key, and later recover the data:

```dart
void completeWorkflow() async {
  // Initialize services
  final keyManagement = KeyManagementService(
    keychainapi: 'https://api.example.com/keychain',
  );
 
  final sensitiveData = 'My very important data';
  final secret = 'my-secret-password';
 
  try {
    // 1. Create backup using BIP85
    final mnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
    final derivationPath = "m/1608'/0'";
   
    final (backupKey, backupJson) = await BackupService.createBackupWithBIP85(
      plaintext: sensitiveData,
      mnemonic: mnemonic,
      derivationPath: derivationPath,
    );
   
    // 2. Store the backup key
    final backupMetadata = BackupMetadata.fromJson(jsonDecode(backupJson));
    await keyManagement.storeBackupKey(
      backupMetadata.backupId,
      backupKey,
      secret,
    );
   
    // Later... recovering the data
   
    // 3. Recover the backup key
    final recoveredKey = await keyManagement.recoverBackupKey(
      backupMetadata.backupId,
      secret,
    );
   
    // 4. Restore the backup
    final restoredData = await BackupService.restoreBackup(
      backupJson,
      recoveredKey,
    );
   
    assert(restoredData == sensitiveData);
  } catch (e) {
    print('Workflow failed: $e');
  }
}
```
