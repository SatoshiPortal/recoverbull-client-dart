import 'package:dio/dio.dart';

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
  late int? code;
  late String? message;

  KeyServiceException({this.code, this.message});

  KeyServiceException.fromResponse(Response<dynamic> response) {
    KeyServiceException(
      code: response.statusCode,
      message: response.data['error'],
    );
  }
}
