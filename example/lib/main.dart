import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hex/hex.dart';
import 'package:recoverbull/recoverbull.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Example());
  }
}

class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

final secret =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
final password = "PasswØrd";
final _backupKey =
    'fcb4a38e1d732dede321d13a6ffa024a38ecc4f40c88e9dcc3c9fe51fb942a6f';
final _keyServerPublicKey =
    '6a04ab98d9e4774ad806e302dddeb63bea16b5cb5f223ee77478e861bb583eb3';

class _ExampleState extends State<Example> {
  String log = "";
  KeyService? _keyService;
  Tor? _tor;
  bool _torLoading = false;
  bool _stored = false;
  bool _trashed = false;
  String _backupId = '';
  String _salt = '';
  final _keyServerUrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("RecoverBull")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _keyServerUrl,
                  decoration:
                      InputDecoration(hintText: 'http://something.onion'),
                  validator: (value) {
                    if (value == null) return 'Fill the key server address';
                    if (value.isEmpty) return 'Fill the key server address';

                    try {
                      Uri.parse(value);
                      return null;
                    } catch (e) {
                      return 'is not an URI';
                    }
                  },
                ),
                ListTile(leading: Text('secret'), title: Text(secret)),
                ListTile(leading: Text('password'), title: Text(password)),
                ListTile(leading: Text('backupKey'), title: Text(_backupKey)),
                ListTile(leading: Text('salt'), title: Text(_salt)),
                Wrap(
                  children: [
                    ElevatedButton(
                        onPressed: _keyService == null ? startTor : null,
                        child: _torLoading
                            ? CircularProgressIndicator()
                            : Text('Start')),
                    ElevatedButton(
                        onPressed: _keyService != null ? stopTor : null,
                        child: Text('Reset')),
                    ElevatedButton(
                        onPressed: _keyService != null ? getInfo : null,
                        child: Text('Server Info')),
                    ElevatedButton(
                        onPressed: _keyService != null ? storeBackup : null,
                        child: Text('Store Key')),
                    ElevatedButton(
                        onPressed: _keyService != null && _stored && !_trashed
                            ? fetchBackupKey
                            : null,
                        child: Text('Fetch Key')),
                    ElevatedButton(
                        onPressed: _keyService != null && _stored && !_trashed
                            ? trashBackupKey
                            : null,
                        child: Text('Trash Key')),
                    ElevatedButton(
                        onPressed: _keyService != null ? recoverbull : null,
                        child: Text('RecoverBull')),
                  ],
                ),
                Card(
                  color: Colors.black,
                  child: SizedBox(
                    width: double.infinity,
                    child: SelectableText(
                      log,
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void startTor() async {
    if (!_formKey.currentState!.validate()) return;

    final keyServerUri = Uri.parse(_keyServerUrl.text);

    final tld = keyServerUri.host.split('.').last;
    if (tld == 'onion') {
      _torLoading = true;
      log += '\nStarting TOR…';
      setState(() {});

      await Tor.init();
      await Tor.instance.start(); // start the proxy
      _tor = Tor.instance;
    }

    _keyService = KeyService(
      keyServer: keyServerUri,
      keyServerPublicKey: _keyServerPublicKey,
      tor: _tor, // null if not onion link
    );

    _torLoading = false;
    setState(() => log += '\nKeyService initialized');
  }

  void stopTor() {
    _keyService?.dispose();
    log = '';
    _keyService = null;
    setState(() {});
  }

  void getInfo() async {
    if (_keyService == null) return;

    try {
      final info = await _keyService!.serverInfo();
      setState(() => log += '\ninfo: ${info.canary}');
    } catch (e) {
      setState(() => log += '\nError: $e');
    }
  }

  void storeBackup() async {
    try {
      final backup = BackupService.createBackup(
        secret: utf8.encode(secret),
        backupKey: HEX.decode(_backupKey),
      );

      setState(() => log += '\ncreate backup: ${backup.id} ');

      await _keyService?.storeBackupKey(
        backupId: backup.id,
        password: password,
        backupKey: HEX.decode(_backupKey),
        salt: HEX.decode(backup.salt),
      );

      _backupId = backup.id;
      _salt = backup.salt;
      _stored = true;
      _trashed = false;
      setState(() => log += '\nstore key: $_backupKey ');
    } catch (e) {
      setState(() => log += "\nError: $e");
    }
  }

  fetchBackupKey() async {
    if (_backupId.isEmpty ||
        password.isEmpty ||
        _salt.isEmpty ||
        _keyService == null) {
      setState(() => log += '\nmissing params');
      return;
    }

    final backupKey = await _keyService!.fetchBackupKey(
      backupId: _backupId,
      password: password,
      salt: HEX.decode(_salt),
    );

    setState(() => log += '\nfetch key: ${HEX.encode(backupKey)} ');
  }

  trashBackupKey() async {
    if (_backupId.isEmpty ||
        password.isEmpty ||
        _salt.isEmpty ||
        _keyService == null) {
      setState(() => log += '\nmissing params');
      return;
    }

    final backupKey = await _keyService!.trashBackupKey(
      backupId: _backupId,
      password: password,
      salt: HEX.decode(_salt),
    );

    _trashed = true;
    setState(() => log += '\ntrash key: ${HEX.encode(backupKey)} ');
  }

  recoverbull() async {
    if (_keyService == null) return;

    setState(() => log = '');

    final backup = BackupService.createBackup(
      secret: utf8.encode(secret),
      backupKey: HEX.decode(_backupKey),
    );
    setState(() => log += '\nbackup created: ${backup.id}');

    final secretRestored = BackupService.restoreBackup(
      backup: backup,
      backupKey: HEX.decode(_backupKey),
    );
    setState(() => log += '\nsecret restored: $secretRestored');

    final info = await _keyService!.serverInfo();
    setState(() => log += '\ninfo.cooldown: ${info.cooldown}');
    setState(() => log += '\ninfo.canary: ${info.canary}');
    setState(() => log += '\ninfo.secretMaxLength: ${info.secretMaxLength}');

    await _keyService!.storeBackupKey(
      backupId: backup.id,
      password: password,
      backupKey: HEX.decode(_backupKey),
      salt: HEX.decode(backup.salt),
    );
    setState(() => log += '\nbackup key stored encrypted on the server');

    final backupKeyBytes = await _keyService!.fetchBackupKey(
      backupId: backup.id,
      password: password,
      salt: HEX.decode(backup.salt),
    );
    final backupKeyRecovered = HEX.encode(backupKeyBytes);
    setState(() =>
        log += '\nbackup key recovered: $backupKeyRecovered from the server');
  }
}
