import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wallet/features/backup-social/handlers.dart';
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
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = [];
  String _myPin = '';
  String _peerPin = '';
  final String _publicKey = "placeholder";

  @override
  void initState() {
    super.initState();
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    if (kIsWeb) {
      channel = HtmlWebSocketChannel.connect('ws://localhost:8765');
    } else {
      channel = IOWebSocketChannel.connect('ws://localhost:8765');
    }

    channel.stream.listen((message) => _handleWebSocketMessage(message));

    registerUser(channel, _publicKey);
  }

  void _handleWebSocketMessage(String message) {
    final decodedMessage = jsonDecode(message);
    final eventType = decodedMessage["type"];
    final data = decodedMessage["data"];

    switch (eventType) {
      case "registration_success":
        setState(() {
          _myPin = data["pin"];
        });
        show("Registered successfully. Your pin: $_myPin");
        break;
      case "peer_success":
        setState(() {
          _peerPin = data["peer_pin"];
        });
        show("Peered successfully with user $_peerPin");
        break;
      case "peer_failure":
        show("Peering failed: ${data["error"]}");
        break;
      case "chat_message":
        final senderPin = data["sender_pin"];
        final messageContent = data["message"];
        show("Message from $senderPin: $messageContent");
        break;
      case "disconnection_acknowledged":
        show("Disconnected from the server.");
        break;
      default:
        show("Unknown event type: $eventType");
    }
  }

  void show(String message) => setState(() => _messages.add(message));

  @override
  void dispose() {
    channel.sink.close();
    _pinController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social backup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              _myPin.isNotEmpty ? 'Your Pin: $_myPin' : 'Registering...',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _pinController,
              decoration: const InputDecoration(labelText: 'Enter Peer Pin'),
            ),
            ElevatedButton(
              onPressed: () => peerWithUser(channel, _pinController.text),
              child: const Text('Peer with User'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(_messages[index]),
                ),
              ),
            ),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'Enter Message'),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () =>
                      send(channel, _messageController.text, _myPin, _peerPin),
                  child: const Text('Send Message'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => disconnect(channel, _myPin),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
