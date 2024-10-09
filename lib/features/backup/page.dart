import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wallet/features/backup/service.dart';
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
  final _pathController = TextEditingController();

  Future<void> _generateBackup() async {
    final directory = await getApplicationDocumentsDirectory();

    final backup = await generateBackup(
      directory.path,
      _textController.text,
      Global.backupKey,
    );

    _pathController.text = backup.path;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup Page')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _textController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Enter text to backup',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generateBackup,
              child: const Text('Generate Encrypted Backup'),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _pathController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Backup Path',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
