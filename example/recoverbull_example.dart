import 'dart:convert';

import 'package:hex/hex.dart';
import 'package:recoverbull/recoverbull.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  final backupKey =
      'fcb4a38e1d732dede321d13a6ffa024a38ecc4f40c88e9dcc3c9fe51fb942a6f';

  final secret =
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

  final backupJson = BackupService.createBackup(
    secret: utf8.encode(secret),
    backupKey: HEX.decode(backupKey),
  );
  final backup = Backup.fromJson(backupJson);

  print('backup created: ${backup.id}');

  final secretRestored = BackupService.restoreBackup(
    backup: backupJson,
    backupKey: HEX.decode(backupKey),
  );
  print('secret restored: $secretRestored');
  assert(secret == secretRestored);

  // I use a localhost key-server injected with dotenv
  final env = DotEnv(includePlatformEnvironment: true)..load();
  final envSecretServer = env['SECRET_SERVER'];
  if (env['SECRET_SERVER'] == null) {
    print('please set SECRET_SERVER in a .env');
    return;
  }

  // store the backup key on the key server
  final secretServer = Uri.parse(envSecretServer!);
  final password = "PasswØrd";
  final keyService = KeyService(keyServer: secretServer);

  await keyService.storeBackupKey(
    backupId: backup.id,
    password: password,
    backupKey: HEX.decode(backupKey),
    salt: HEX.decode(backup.salt),
  );
  print('backup key stored encrypted on the server');

  final backupKeyBytes = await keyService.recoverBackupKey(
    backupId: backup.id,
    password: password,
    salt: HEX.decode(backup.salt),
  );
  final backupKeyRecovered = HEX.encode(backupKeyBytes);
  assert(backupKey == backupKeyRecovered);
  print('backup key recovered: $backupKeyRecovered from the server');
}
