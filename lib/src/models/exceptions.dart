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

  /// Server-advised backoff, parsed from the `Retry-After` HTTP header on the
  /// response that produced this exception. `null` when the header was
  /// absent or couldn't be parsed as the `delay-seconds` form (see
  /// [_parseRetryAfter]).
  Duration? retryAfter;

  KeyServerException({
    this.code,
    this.message,
    this.requestedAt,
    this.cooldownInMinutes,
    this.attempts,
    this.retryAfter,
  });

  /// Parses the `Retry-After` header value defensively.
  ///
  /// Only the RFC 9110 `delay-seconds` form (a non-negative integer number
  /// of seconds) is supported, since that's what this key server emits. The
  /// HTTP-date form is deliberately NOT handled: parsing and validating an
  /// HTTP-date is more surface for little benefit here, and a caller that
  /// gets `null` back simply falls back to its own backoff strategy instead
  /// of failing.
  ///
  /// A value of zero is treated as valid and returns `Duration.zero`: the
  /// server may legitimately advise "retry immediately" (e.g. right at
  /// cooldown expiry), and that is a meaningful signal distinct from "no
  /// header sent", which returns `null`.
  ///
  /// Absent, empty, non-numeric, or negative values all return `null`
  /// rather than throwing, so a malformed or missing header never turns
  /// into a crash on the error path.
  static Duration? _parseRetryAfter(String? header) {
    if (header == null || header.isEmpty) return null;
    final seconds = int.tryParse(header.trim());
    if (seconds == null || seconds < 0) return null;
    return Duration(seconds: seconds);
  }

  static KeyServerException fromResponse(
    int statusCode,
    String responseBody, {
    String? retryAfterHeader,
  }) {
    String? errorMessage;
    DateTime? requestedAt;
    int? cooldownInMinutes;
    int? attempts;
    final retryAfter = _parseRetryAfter(retryAfterHeader);
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
      return KeyServerRateLimitedException(
        code: statusCode,
        message: errorMessage,
        requestedAt: requestedAt,
        cooldownInMinutes: cooldownInMinutes,
        attempts: attempts,
        retryAfter: retryAfter,
      );
    }
    if (statusCode == 503) {
      return KeyServerUnavailableException(
        code: statusCode,
        message: errorMessage,
        retryAfter: retryAfter,
      );
    }
    return KeyServerException(
      code: statusCode,
      message: errorMessage,
      requestedAt: requestedAt,
      cooldownInMinutes: cooldownInMinutes,
      attempts: attempts,
      retryAfter: retryAfter,
    );
  }

  @override
  String toString() =>
      'KeyServerException(code: $code, message: $message, requestedAt: $requestedAt, cooldown: $cooldownInMinutes, attempts: $attempts, retryAfter: $retryAfter)';
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
    super.retryAfter,
  });
}

/// Legacy exception retained for source compatibility. New responses use
/// [KeyServerRateLimitedException] for every 429 status.
@Deprecated('Use KeyServerRateLimitedException for 429 responses.')
class KeyServerOverloadedException extends KeyServerException {
  KeyServerOverloadedException({
    super.code,
    super.message,
    super.requestedAt,
    super.cooldownInMinutes,
    super.attempts,
    super.retryAfter,
  });
}

/// Legacy exception retained for source compatibility. New responses use
/// [KeyServerUnavailableException] for every 503 status.
@Deprecated('Use KeyServerUnavailableException for 503 responses.')
class KeyServerCapacityException extends KeyServerException {
  KeyServerCapacityException({
    super.code,
    super.message,
    super.retryAfter,
  });
}

/// `503`: transient server unavailability.
class KeyServerUnavailableException extends KeyServerException {
  KeyServerUnavailableException({
    super.code,
    super.message,
    super.retryAfter,
  });
}
