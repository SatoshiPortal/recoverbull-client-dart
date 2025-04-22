class Info {
  final int cooldown;
  final int maxFailedAttempts;
  final int secretMaxLength;
  final String canary;

  Info({
    required this.cooldown,
    required this.maxFailedAttempts,
    required this.secretMaxLength,
    required this.canary,
  });

  factory Info.fromMap(Map<String, dynamic> map) {
    return Info(
      canary: map['canary'] as String,
      secretMaxLength: map['secret_max_length'] as int,
      cooldown: map['rate_limit_cooldown'] as int,
      maxFailedAttempts: map['rate_limit_max_failed_attempts'] as int,
    );
  }
}
