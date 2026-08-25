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

## Tests

```sh
flutter test
```

`flutter test` runs the hermetic unit and local integration tests. Tests that use a real key server are kept under `integration_test/` and must be run explicitly with `KEY_SERVER`, for example `KEY_SERVER=https://keyserver.example flutter test integration_test`.

## Backup and key-server input constraints

Backups use format version `1`; backups without a version field remain accepted as legacy version 1. Backup JSON is limited to 2 MiB, plaintext is limited to the size that fits in that container after AES-CBC/PKCS7 padding, identifiers are 32 bytes, salts are 16 bytes, and encrypted containers are limited to 1 MiB with a 16-byte nonce, block-aligned AES ciphertext, and a 32-byte HMAC.

Key-server addresses must use HTTPS, or HTTP for a `.onion` host or loopback (`localhost`, `127.0.0.1`, or `::1`) when appropriate for Tor or local testing. URL credentials, queries, and fragments are rejected.


## Examples

Please look the [example folder](https://github.com/SatoshiPortal/recoverbull-client-dart/tree/main/example) 
