import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wallet/global.dart';
import 'package:wallet/utils.dart';

class ManualRecoveryPage extends StatefulWidget {
  const ManualRecoveryPage({super.key});

  @override
  State<ManualRecoveryPage> createState() => _RecoverPageState();
}

class _RecoverPageState extends State<ManualRecoveryPage> {
  var filename = '';
  var file = '';

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.bytes != null) {
      filename = result.files.single.name;
      file = utf8.decode(result.files.single.bytes!);
      setState(() {});
    }
  }

  void _decryptBackup() async {
    if (!mounted) return;
    try {
      final backup = decryptBackup(file, Global.backupKey);

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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (filename.isEmpty)
                ElevatedButton(
                  onPressed: _pickFile,
                  child: Text(filename.isNotEmpty
                      ? 'Select Backup File'
                      : 'File Selected'),
                ),
              if (filename.isNotEmpty) Text(filename),
              if (filename.isNotEmpty)
                ElevatedButton(
                  onPressed: _decryptBackup,
                  child: const Text('Decrypt Backup'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
