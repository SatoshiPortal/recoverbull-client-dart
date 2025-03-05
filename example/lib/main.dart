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
    return MaterialApp(home: TorExample());
  }
}

class TorExample extends StatefulWidget {
  const TorExample({super.key});

  @override
  State<TorExample> createState() => _TorExampleState();
}

final secret =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
final password = "PasswØrd";
final _backupKey =
    '6a04ab98d9e4774ad806e302dddeb63bea16b5cb5f223ee77478e861bb583eb3';

class _TorExampleState extends State<TorExample> {
  String log = "";
  KeyService? _keyService;
  bool _torLoading = false;
  bool _stored = false;
  bool _trashed = false;
  String _backupId = '';
  String _salt = '';
  final _keyServerUrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("RecoverBull with Tor")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _keyServerUrl,
                decoration: InputDecoration(hintText: 'http://something.onion'),
                validator: (value) {
                  if (value == null) return 'Fill with an onion address';
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
                      onPressed:
                          _keyService != null && _keyService!.isTorWorking
                              ? stopTor
                              : null,
                      child: Text('Stop')),
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
    );
  }

  void startTor() async {
    _torLoading = true;
    log += '\nStarting TOR…';
    setState(() {});

    // Configure SOCKS5 Proxy for Tor
    final keyServer = Uri.parse(_keyServerUrl.text);
    final keyServerPublicKey =
        '6a04ab98d9e4774ad806e302dddeb63bea16b5cb5f223ee77478e861bb583eb3';
    _keyService = await KeyService.withTor(
      keyServer: keyServer,
      keyServerPublicKey: keyServerPublicKey,
    );
    _torLoading = false;
    setState(() => log += '\nKeyService initialized');
  }

  void stopTor() {
    _keyService?.killTor();
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
      print(e);
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
      print('missing parameters');
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
      print('missing parameters');
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
}
