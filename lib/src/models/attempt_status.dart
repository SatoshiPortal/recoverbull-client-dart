/// Exact attempt counters for one identifier's current rate-limit window,
/// returned by the key server on a successful `/fetch` or `/trash`.
///
/// Semantics the consumer must know:
/// - [totalAttempts] counts distinct authentication candidates. A matching
///   lookup does not prove ownership, because a public `/store` caller can
///   plant a matching row.
/// - [totalRequests] counts all authentication requests, including replays
///   of the same candidate.
/// - A successful lookup never resets the counters; they expire after the
///   server cooldown.
/// - Timestamps are exact (second precision) by design: this response is
///   only reachable by someone who already knows the backup identifier.
class AttemptStatus {
  final int version;
  final int totalAttempts;
  final int totalRequests;
  final int failedAttempts;
  final int remainingAttempts;
  final DateTime windowStartedAt;
  final DateTime? previousAttemptAt;
  final DateTime resetsAt;

  AttemptStatus({
    required this.version,
    required this.totalAttempts,
    required this.totalRequests,
    required this.failedAttempts,
    required this.remainingAttempts,
    required this.windowStartedAt,
    required this.previousAttemptAt,
    required this.resetsAt,
  });

  factory AttemptStatus.fromMap(Map<String, dynamic> map) {
    final version = map['version'];
    if (version is! int || version != 1) {
      throw FormatException(
        'Unsupported telemetry version: $version (expected version 1)',
      );
    }

    return AttemptStatus(
      version: version,
      totalAttempts: map['total_attempts'] as int,
      totalRequests: (map['total_requests'] ?? map['total_attempts']) as int,
      failedAttempts: map['failed_attempts'] as int,
      remainingAttempts: map['remaining_attempts'] as int,
      windowStartedAt: DateTime.parse(map['window_started_at'] as String),
      previousAttemptAt: map['previous_attempt_at'] != null
          ? DateTime.parse(map['previous_attempt_at'] as String)
          : null,
      resetsAt: DateTime.parse(map['resets_at'] as String),
    );
  }
}
