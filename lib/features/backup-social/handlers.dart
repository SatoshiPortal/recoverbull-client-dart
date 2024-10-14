import 'dart:convert';

import 'package:wallet/features/backup-social/page.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void registerUser(WebSocketChannel channel, String publicKey) {
  final registrationMessage = jsonEncode({
    "type": "register",
    "data": {"public_key": publicKey}
  });
  channel.sink.add(registrationMessage);
}

void peerWithUser(WebSocketChannel channel, String pin) {
  final peerPin = pin.trim();
  if (peerPin.isEmpty) {
    SocialPageState().show("Please enter a pin to peer with.");
    return;
  }

  final peerRequestMessage = jsonEncode({
    "type": "peer_request",
    "data": {"pin": peerPin}
  });
  channel.sink.add(peerRequestMessage);
}

void send(
    WebSocketChannel channel, String message, String myPin, String peerPin) {
  final messageContent = message.trim();
  if (messageContent.isEmpty || peerPin.isEmpty) {
    SocialPageState().show("Please enter a message and ensure you are peered.");
    return;
  }

  final chatMessage = jsonEncode({
    "type": "chat_message",
    "data": {
      "sender_pin": myPin,
      "recipient_pin": peerPin,
      "message": messageContent,
    }
  });
  channel.sink.add(chatMessage);
}

void disconnect(WebSocketChannel channel, String myPin) {
  final disconnectMessage = jsonEncode({
    "type": "disconnect",
    "data": {"pin": myPin}
  });
  channel.sink.add(disconnectMessage);
  channel.sink.close();
}
