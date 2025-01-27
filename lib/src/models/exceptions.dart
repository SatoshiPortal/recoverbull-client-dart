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
  final String message;
  final dynamic cause;

  const KeyServiceException(this.message, [this.cause]);

  @override
  String toString() =>
      'KeyServiceException: $message${cause != null ? ' ($cause)' : ''}';
}
