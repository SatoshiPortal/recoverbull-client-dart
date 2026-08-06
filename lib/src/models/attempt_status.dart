/// Exact attempt counters for one identifier's current rate-limit window,
/// returned by the key server on a successful `/fetch` or `/trash`.
///
/// Semantics the consumer must know:
/// - [totalAttempts] counts **all** lookups, including database hits: a hit
///   does not prove ownership, because a public `/store` caller can plant a
///   matching row. A total higher than the user's own operations is the
///   warning signal.
/// - A successful lookup never resets the counters; they expire after the
///   server cooldown.
/// - Timestamps are exact (second precision) by design: this response is
///   only reachable by someone who already knows the backup identifier.
class AttemptStatus {
  final int totalAttempts;
  final int failedAttempts;
  final int remainingAttempts;
  final DateTime windowStartedAt;
  final DateTime? previousAttemptAt;
  final DateTime resetsAt;

  AttemptStatus({
    required this.totalAttempts,
    required this.failedAttempts,
    required this.remainingAttempts,
    required this.windowStartedAt,
    required this.previousAttemptAt,
    required this.resetsAt,
  });

  factory AttemptStatus.fromMap(Map<String, dynamic> map) {
    return AttemptStatus(
      totalAttempts: map['total_attempts'] as int,
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
