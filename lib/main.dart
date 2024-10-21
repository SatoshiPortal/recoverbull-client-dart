import 'package:flutter/material.dart';
import 'package:wallet/features/backup-keychain/page.dart';
import 'package:wallet/features/backup-social/page.dart';
import 'package:wallet/features/backup/page.dart';
import 'package:wallet/features/recover-keychain/page.dart';
import 'package:wallet/features/recover-manual/page.dart';
import 'package:wallet/features/recover-social/page.dart';
import 'package:wallet/global.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Global.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallet Demo',
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.black),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.deepOrange,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
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
        title: Text("${Global.branch} ${Global.commit.substring(0, 10)}"),
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
                    Column(
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
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const KeychainPage()),
                            );
                          },
                          child: const Text('Keychain Backup'),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SocialPage()),
                            );
                          },
                          child: const Text('Social Backup'),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ManualRecoveryPage()),
                            );
                          },
                          child: const Text('Manual Recovery'),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const KeychainRecoveryPage()),
                            );
                          },
                          child: const Text('Keychain Recovery'),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const SocialRecoveryPage()),
                            );
                          },
                          child: const Text('Social Recovery'),
                        ),
                      ],
                    )
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}
