import 'dart:convert';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:wallet/features/backup-social/avatar.dart';
import 'package:wallet/global.dart';
import 'package:wallet/utils.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/html.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => SocialPageState();
}

class SocialPageState extends State<SocialPage> {
  late WebSocketChannel channel;
  final _pinController = TextEditingController();
  final _message = TextEditingController();
  final messages = <(String, String)>[];
  var _myPin = '';
  var _peerPin = '';
  var _peerPubKey = '';
  var isPeered = false;
  var _peerEncryptedBackupKey = '';

  @override
  void initState() {
    super.initState();
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    if (kIsWeb) {
      channel = HtmlWebSocketChannel.connect(Global.websocketUrl);
    } else {
      channel = IOWebSocketChannel.connect(Global.websocketUrl);
    }

    channel.stream.listen((message) => _handleWebSocketMessage(message));

    registerUser(channel, Global.pair.publicKey.toString());
  }

  void _handleWebSocketMessage(String message) async {
    final decodedMessage = jsonDecode(message);
    final eventType = decodedMessage["type"];
    final data = decodedMessage["data"];

    switch (eventType) {
      case "registration_success":
        setState(() {
          _myPin = data["pin"];
        });
        show('server', "Your pin is $_myPin");
        break;
      case "peer_success":
        setState(() {
          _peerPin = data["peer_pin"];
          _peerPubKey = data["peer_public_key"];
          isPeered = true;
        });
        show('server', "Peered with user $_peerPin");
        break;
      case "peer_failure":
        show('server', data["error"]);
        break;
      case "chat_message":
        final senderPin = data["sender_pin"];
        final message = data["message"];
        final plaintext = await decryptMessage(message, Global.pair.privateKey);
        show(senderPin, plaintext);
        break;
      case "social_backup":
        final senderPin = data["sender_pin"];
        _peerEncryptedBackupKey = data["backup_key"];
        show(senderPin,
            "Peer sent you his backup key, click download button and store securely the encrypted backup key and your private key");
        break;
      case "social_recover":
        final senderPin = data["sender_pin"];
        _peerEncryptedBackupKey = data["backup_key"];
        show(senderPin, "Peer sent you back backup key, click download button");
        break;
      case "disconnection_acknowledged":
        setState(() {
          _peerPin = '';
          isPeered = false;
        });
        show('server', "Disconnected");
        break;
      default:
        show('server', "Unknown event type: $eventType");
    }
  }

  void registerUser(WebSocketChannel channel, String publicKey) {
    final registrationMessage = jsonEncode({
      "type": "register",
      "data": {"public_key": publicKey}
    });
    channel.sink.add(registrationMessage);
  }

  void disconnect(WebSocketChannel channel, String myPin) {
    final disconnectMessage = jsonEncode({
      "type": "disconnect",
      "data": {"pin": myPin}
    });
    channel.sink.add(disconnectMessage);
  }

  void show(String author, String message) =>
      setState(() => messages.add((author, message)));

  void peerWithUser(WebSocketChannel channel, String pin) {
    final peerPin = pin.trim();
    if (peerPin.isEmpty) {
      show('server', "Please enter a pin to peer with.");
      return;
    }

    final peerRequestMessage = jsonEncode({
      "type": "peer_request",
      "data": {"pin": peerPin}
    });
    channel.sink.add(peerRequestMessage);
  }

  Future<void> send(
    WebSocketChannel channel,
    String message,
    String myPin,
    String peerPin,
    String peerPubKey,
  ) async {
    final messageContent = message.trim();

    if (messageContent.isEmpty || peerPin.isEmpty) {
      show('server', "Please enter a message to send.");
      return;
    }

    final ciphertext = await encryptMessage(message, peerPubKey);

    final chatMessage = jsonEncode({
      "type": "chat_message",
      "data": {
        "sender_pin": myPin,
        "recipient_pin": peerPin,
        "message": ciphertext,
      }
    });

    channel.sink.add(chatMessage);
    show(myPin, messageContent);
  }

  Future<void> sendBackupKey(
    WebSocketChannel channel,
    String myPin,
    String peerPin,
    String peerPubKey,
    String backupKey,
  ) async {
    if (Global.backupKey.isEmpty || peerPin.isEmpty || peerPubKey.isEmpty) {
      show('server', "Please enter a message to send.");
      return;
    }

    final encryptedBackupKey = await encryptMessage(backupKey, peerPubKey);

    final chatMessage = jsonEncode({
      "type": "social_backup",
      "data": {
        "sender_pin": myPin,
        "recipient_pin": peerPin,
        "backup_key": encryptedBackupKey,
      }
    });

    channel.sink.add(chatMessage);
    show(myPin, "Encrypted backup key sent");
  }

  @override
  void dispose() {
    channel.sink.close();
    _pinController.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Social backup')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text('You $_myPin'),
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Avatar(publicKey: Global.pair.publicKey),
                    ),
                  ],
                ),
                if (isPeered == true &&
                    _peerPin.isNotEmpty &&
                    _peerPubKey.isNotEmpty)
                  Column(
                    children: [
                      Text('Peer $_peerPin'),
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Avatar(publicKey: _peerPubKey),
                      ),
                    ],
                  )
              ],
            ),
            const SizedBox(height: 16),
            if (isPeered == false)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _pinController,
                      decoration:
                          const InputDecoration(labelText: 'Enter Peer PIN'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => peerWithUser(channel, _pinController.text),
                    child: const Text('Peer with User'),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final author = messages[index].$1;
                  final message = messages[index].$2;
                  return ListTile(leading: Text(author), title: Text(message));
                },
              ),
            ),
            if (isPeered)
              TextField(
                controller: _message,
                decoration: const InputDecoration(labelText: 'Enter Message'),
              ),
            const SizedBox(height: 16),
            if (isPeered)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await send(
                        channel,
                        _message.text,
                        _myPin,
                        _peerPin,
                        _peerPubKey,
                      );
                      _message.clear();
                      setState(() {});
                    },
                    child: const Text('Send Message'),
                  ),
                  if (_peerEncryptedBackupKey.isEmpty)
                    ElevatedButton(
                      onPressed: () async {
                        sendBackupKey(
                          channel,
                          _myPin,
                          _peerPin,
                          _peerPubKey,
                          Global.backupKey,
                        );
                      },
                      child: const Text('Send Backup Key to Peer'),
                    ),
                  if (_peerEncryptedBackupKey.isNotEmpty)
                    ElevatedButton(
                      onPressed: () async {
                        FileSaver.instance.saveFile(
                          name: 'encrypted-backup-key.txt',
                          bytes: Uint8List.fromList(
                              utf8.encode(_peerEncryptedBackupKey)),
                        );

                        FileSaver.instance.saveFile(
                          name: 'private-key.pem',
                          bytes: Uint8List.fromList(
                            utf8.encode(Global.pair.privateKey),
                          ),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Encrypted backup key downloaded & Private key downloaded')),
                        );
                      },
                      child: const Text('Download Peer Backup Key'),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      disconnect(channel, _myPin);
                      Navigator.pop(context);
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Disconnect'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
