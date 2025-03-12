import 'dart:convert';

import 'package:http/http.dart';

/// Custom exception for encryption operations
class EncryptionException implements Exception {
  final String message;
  final dynamic cause;

  EncryptionException(this.message, [this.cause]);

  @override
  String toString() =>
      'EncryptionException: $message${cause != null ? ' ($cause)' : ''}';
}

/// Exception specific to backup operations
class RecoverBullException implements Exception {
  final String message;
  final dynamic cause;

  RecoverBullException(this.message, [this.cause]);

  @override
  String toString() =>
      'RecoverBullException: $message${cause != null ? ' ($cause)' : ''}';
}

/// Custom exception for key management operations
class KeyServerException implements Exception {
  int? code;
  String? message;
  DateTime? requestedAt;
  int? cooldownInMinutes;

  KeyServerException({
    this.code,
    this.message,
    this.requestedAt,
    this.cooldownInMinutes,
  });

  static KeyServerException fromResponse(Response response) {
    final body = json.decode(response.body);
    final requestedAt = body['requested_at'] != null
        ? DateTime.parse(body['requested_at'])
        : null;
    final cooldownInMinutes = body['cooldown'];

    return KeyServerException(
      code: response.statusCode,
      message: body['error'],
      requestedAt: requestedAt,
      cooldownInMinutes: cooldownInMinutes,
    );
  }

  @override
  String toString() =>
      'KeyServerException(code: $code, message: $message, requestedAt: $requestedAt, cooldown: $cooldownInMinutes)';
}
