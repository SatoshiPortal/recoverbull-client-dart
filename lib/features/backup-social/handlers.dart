import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

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
