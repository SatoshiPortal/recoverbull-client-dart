import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:http/http.dart';

List<int> generateRandomBytes({int length = 32}) {
  final secureRandom = Random.secure();
  final bytes = Uint8List(length);
  for (int i = 0; i < length; i++) {
    bytes[i] = secureRandom.nextInt(256);
  }
  return bytes;
}

// Constant-time comparison to prevent timing attacks
bool constantTimeComparison(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var result = 0;
  for (var i = 0; i < a.length; i++) {
    result |= a[i] ^ b[i];
  }
  return result == 0;
}

Response parseHttpResponse(List<int> bytes) {
  try {
    final decoded = utf8.decode(bytes, allowMalformed: true);
    final parts = decoded.split('\r\n\r\n');
    if (parts.length < 2) throw Exception('Invalid HTTP response format');

    final body = parts.sublist(1).join('\r\n\r\n');

    final lines = parts[0].split('\r\n');
    if (lines.isEmpty) {
      throw Exception('Malformed HTTP response: Missing status line');
    }

    final statusParts = lines.first.split(' ');
    if (statusParts.length < 3) {
      throw Exception('Malformed HTTP status line: ${lines.first}');
    }

    final statusCode = int.tryParse(statusParts[1]);
    if (statusCode == null) {
      throw Exception('Malformed HTTP status code: ${statusParts[1]}');
    }

    return Response.bytes(utf8.encode(body), statusCode);
  } catch (_) {
    rethrow;
  }
}
