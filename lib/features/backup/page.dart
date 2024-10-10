import 'dart:convert';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wallet/features/backup/service.dart';
import 'package:wallet/features/backup-keychain/page.dart';
import 'package:wallet/global.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final _textController = TextEditingController(
    text: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit',
  );

  Future<void> _generateBackup() async {
    if (!mounted) return;
    try {
      final backup =
          await generateBackup(_textController.text, Global.backupKey);

      FileSaver.instance.saveFile(
        name: 'backup.json',
        bytes: Uint8List.fromList(utf8.encode(backup)),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup downloaded')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const KeychainPage()),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextFormField(
                controller: _textController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Enter text to backup',
                  border: OutlineInputBorder(),
                ),
              ),
              ElevatedButton(
                onPressed: _generateBackup,
                child: const Text('Generate Encrypted Backup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
