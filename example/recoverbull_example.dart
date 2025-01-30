import 'dart:convert';

import 'package:hex/hex.dart';
import 'package:recoverbull/recoverbull.dart';

void main() {
  final key =
      'fcb4a38e1d732dede321d13a6ffa024a38ecc4f40c88e9dcc3c9fe51fb942a6f';

  final secret =
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

  final backupJson = BackupService.createBackup(
    secret: utf8.encode(secret),
    backupKey: HEX.decode(key),
  );

  final secretRecovered = BackupService.restoreBackup(
    backup: backupJson,
    backupKey: HEX.decode(key),
  );

  assert(secret == secretRecovered);
}
