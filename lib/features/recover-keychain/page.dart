import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wallet/global.dart';
import 'package:wallet/utils.dart';
import 'package:http/http.dart' as http;

class KeychainRecoveryPage extends StatefulWidget {
  const KeychainRecoveryPage({super.key});

  @override
  State<KeychainRecoveryPage> createState() => _RecoverPageState();
}

class _RecoverPageState extends State<KeychainRecoveryPage> {
  var filename = '';
  var file = '';
  var keyID = '';
  var backupKey = '';
  final pin = TextEditingController();

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.bytes != null) {
      filename = result.files.single.name;
      file = utf8.decode(result.files.single.bytes!);
      final json = jsonDecode(file);

      if (json['key_id'] == null ||
          json['iv'] == null ||
          json['encrypted'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$filename is not a valid backup")),
        );

        filename = '';
        file = '';
        return;
      } else {
        keyID = json['key_id'];
      }
      setState(() {});
    }
  }

  void _recoverBackupKey() async {
    if (keyID.isEmpty || pin.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing key ID or PIN')),
      );
      return;
    }

    final pinHash = sha256.convert(utf8.encode(pin.text)).toString();

    final response = await http.post(
      Uri.parse('${Global.keychainUrl}/recover'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': keyID,
        'secret_hash': pinHash,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      backupKey = body['private'];

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup key recovered')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to recover backup key')),
      );
    }

    setState(() {});
  }

  void _decryptBackup() async {
    if (keyID.isEmpty || pin.text.length != 6 || backupKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing key ID / PIN / backup key')),
      );
      return;
    }

    if (!mounted) return;
    try {
      final backup = decryptBackup(file, backupKey);

      await FileSaver.instance.saveFile(
        name: 'decrypted-backup.txt',
        bytes: Uint8List.fromList(utf8.encode(backup)),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup decrypted')),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Decryption failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Recovery')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Text('Backup file'),
              title: Text(filename),
            ),
            ListTile(
              leading: const Text('Key ID (sha256)'),
              title: Text(keyID),
            ),
            ListTile(
              leading: const Text('Backup Key (base64)'),
              title: Text(backupKey),
            ),
            if (filename.isEmpty)
              ElevatedButton(
                onPressed: _pickFile,
                child: const Text('Select backup file'),
              ),
            if (backupKey.isEmpty && keyID.isNotEmpty)
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: pin,
                  decoration: const InputDecoration(labelText: 'Enter PIN'),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
              ),
            if (backupKey.isEmpty && keyID.isNotEmpty)
              ElevatedButton(
                onPressed: _recoverBackupKey,
                child: const Text('Ask keychain for backup key'),
              ),
            if (backupKey.isNotEmpty && file.isNotEmpty)
              ElevatedButton(
                onPressed: _decryptBackup,
                child: const Text('Decrypt Backup'),
              ),
          ],
        ),
      ),
    );
  }
}
