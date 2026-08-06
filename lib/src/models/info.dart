class Info {
  final int cooldown;
  final int maxFailedAttempts;
  final int secretMaxLength;
  final String canary;

  /// Hour-truncated start of the server's attempt collection. Changes when
  /// the server restarts and wipes its in-memory rate-limit map: clients
  /// reset their telemetry baseline on change. Null against older servers.
  final DateTime? attemptsCollectionStartedAt;

  /// Capacity of the server's in-memory rate-limit map, so clients can warn
  /// when the service is under pressure. Null against older servers.
  final int? maxAttemptIdentifiers;

  Info({
    required this.cooldown,
    required this.maxFailedAttempts,
    required this.secretMaxLength,
    required this.canary,
    this.attemptsCollectionStartedAt,
    this.maxAttemptIdentifiers,
  });

  factory Info.fromMap(Map<String, dynamic> map) {
    return Info(
      canary: map['canary'] as String,
      secretMaxLength: map['secret_max_length'] as int,
      cooldown: map['rate_limit_cooldown'] as int,
      maxFailedAttempts: map['rate_limit_max_failed_attempts'] as int,
      attemptsCollectionStartedAt: map['attempts_collection_started_at'] != null
          ? DateTime.parse(map['attempts_collection_started_at'] as String)
          : null,
      maxAttemptIdentifiers: map['max_attempt_identifiers'] as int?,
    );
  }
}
