import 'dart:convert';

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
  int? attempts;

  KeyServerException({
    this.code,
    this.message,
    this.requestedAt,
    this.cooldownInMinutes,
    this.attempts,
  });

  static KeyServerException fromResponse(int statusCode, String responseBody) {
    String? errorMessage;
    DateTime? requestedAt;
    int? cooldownInMinutes;
    int? attempts;
    try {
      final body = json.decode(responseBody);
      errorMessage = body['error'];
      requestedAt = body['requested_at'] != null
          ? DateTime.parse(body['requested_at'])
          : null;
      cooldownInMinutes = body['rate_limit_cooldown'];
      attempts = body['attempts'];
    } catch (_) {
      // some rejections are not JSON (e.g. the 413 body-limit rejection)
      errorMessage = responseBody;
    }

    if (statusCode == 429) {
      // The targeted per-identifier lockout carries this exact message; any
      // other 429 is a global bucket exhaustion. Ambiguity defaults to the
      // global variant: service pressure must never be read as an attack.
      if (errorMessage == 'Too many attempts') {
        return KeyServerRateLimitedException(
          code: statusCode,
          message: errorMessage,
          requestedAt: requestedAt,
          cooldownInMinutes: cooldownInMinutes,
          attempts: attempts,
        );
      }
      return KeyServerOverloadedException(
        code: statusCode,
        message: errorMessage,
        requestedAt: requestedAt,
        cooldownInMinutes: cooldownInMinutes,
        attempts: attempts,
      );
    }
    if (statusCode == 503) {
      if (errorMessage != null &&
          errorMessage.startsWith('Rate-limit capacity exhausted')) {
        return KeyServerCapacityException(
          code: statusCode,
          message: errorMessage,
        );
      }
      return KeyServerUnavailableException(
        code: statusCode,
        message: errorMessage,
      );
    }
    return KeyServerException(
      code: statusCode,
      message: errorMessage,
      requestedAt: requestedAt,
      cooldownInMinutes: cooldownInMinutes,
      attempts: attempts,
    );
  }

  @override
  String toString() =>
      'KeyServerException(code: $code, message: $message, requestedAt: $requestedAt, cooldown: $cooldownInMinutes, attempts: $attempts)';
}

/// Per-identifier `429`: the targeted identifier's attempt budget is
/// exhausted. On the user's own fetch this is an alarm signal: someone may
/// be probing or griefing this backup.
class KeyServerRateLimitedException extends KeyServerException {
  KeyServerRateLimitedException({
    super.code,
    super.message,
    super.requestedAt,
    super.cooldownInMinutes,
    super.attempts,
  });
}

/// Global `429`: the server's whole lookup/store/attempts bucket is
/// exhausted. Service-wide pressure, **not** an attack signal.
class KeyServerOverloadedException extends KeyServerException {
  KeyServerOverloadedException({
    super.code,
    super.message,
    super.requestedAt,
    super.cooldownInMinutes,
    super.attempts,
  });
}

/// `503`: the server's rate-limit map is full. Service pressure, not an
/// attack signal.
class KeyServerCapacityException extends KeyServerException {
  KeyServerCapacityException({super.code, super.message});
}

/// `503`: the server's database is busy. Transient unavailability, not an
/// attack signal.
class KeyServerUnavailableException extends KeyServerException {
  KeyServerUnavailableException({super.code, super.message});
}
