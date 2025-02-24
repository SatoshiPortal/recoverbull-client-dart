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
class BackupException implements Exception {
  final String message;
  final dynamic cause;

  BackupException(this.message, [this.cause]);

  @override
  String toString() =>
      'BackupException: $message${cause != null ? ' ($cause)' : ''}';
}

/// Custom exception for key management operations
class KeyServiceException implements Exception {
  int? code;
  String? message;
  DateTime? requestedAt;
  int? cooldownInMinutes;

  KeyServiceException({
    this.code,
    this.message,
    this.requestedAt,
    this.cooldownInMinutes,
  });

  static KeyServiceException fromResponse(Response response) {
    final body = json.decode(response.body);
    final requestedAt = body['requested_at'] != null
        ? DateTime.parse(body['requested_at'])
        : null;
    final cooldownInMinutes = body['cooldown'];

    return KeyServiceException(
      code: response.statusCode,
      message: body['error'],
      requestedAt: requestedAt,
      cooldownInMinutes: cooldownInMinutes,
    );
  }

  @override
  String toString() =>
      'KeyServiceException(code: $code, message: $message, requestedAt: $requestedAt, cooldown: $cooldownInMinutes)';
}
