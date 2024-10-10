import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wallet/global.dart';

class KeychainPage extends StatefulWidget {
  const KeychainPage({super.key});

  @override
  State<KeychainPage> createState() => _PinSelectionPageState();
}

class _PinSelectionPageState extends State<KeychainPage> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _isPinConfirmed = false;

  void _confirmPin() {
    if (_pinController.text == _confirmPinController.text) {
      _isPinConfirmed = true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match')),
      );
    }
    setState(() {});
  }

  Future<void> _secureBackupKey() async {
    final pinHash = sha256.convert(utf8.encode(_pinController.text)).toString();

    final response = await http.post(
      Uri.parse('${Global.keychainUrl}/key'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'secret_hash': pinHash,
        'backup_key': Global.backupKey,
      }),
    );

    if (!mounted) return;
    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Key secured \n${response.statusCode}')),
      );
    } else if (response.statusCode == 403) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Key already stored')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Key not secured \n${response.statusCode}')),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keychain')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!_isPinConfirmed)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: _pinController,
                      decoration: const InputDecoration(labelText: 'Enter PIN'),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: _confirmPinController,
                      decoration:
                          const InputDecoration(labelText: 'Confirm PIN'),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                    ),
                  ),
                ],
              ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              if (!_isPinConfirmed)
                ElevatedButton(
                  onPressed: _confirmPin,
                  child: const Text('Confirm PIN'),
                ),
              if (_isPinConfirmed)
                ElevatedButton(
                  onPressed: _secureBackupKey,
                  child: const Text('Secure my backup key'),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}
