# Recoverbull Dart

`recoverbull` is a project designed to facilitate secure backup and recovery of data using encryption and key management techniques. It supports creating encrypted backups, restoring data from backups, and managing keys with a remote server.

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

```dart
// Create a backup using a direct encryption key
void example()  {
    final backupKey = HEX.decode(
        'fcb4a38e1d732dede321d13a6ffa024a38ecc4f40c88e9dcc3c9fe51fb942a6f');
    final secret = utf8.encode('Super Secret!');

    final backupJson = BackupService.createBackup(
      secret: secret,
      backupKey: backupKey,
    );

    final restoredSecret = BackupService.restoreBackup(
      backup: backupJson,
      backupKey: backupKey,
    );

    assert(utf8.encode(restoredSecret) == secret);
}
```
