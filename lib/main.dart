import 'package:flutter/material.dart';
import 'package:wallet/features/backup/page.dart';
import 'package:wallet/features/recover-manual/page.dart';
import 'package:wallet/global.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallet Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Backup/Recover Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 500,
              child: TextFormField(
                initialValue: Global.backupKey,
                decoration:
                    const InputDecoration(labelText: 'Backup Key (base64)'),
                onChanged: (v) => setState(() => Global.backupKey = v),
                maxLength: 44,
              ),
            ),
            SizedBox(
              width: 500,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const BackupPage()),
                        );
                      },
                      child: const Text('Backup'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ManualRecoveryPage()),
                        );
                      },
                      child: const Text('Manual Recovery'),
                    ),
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}
