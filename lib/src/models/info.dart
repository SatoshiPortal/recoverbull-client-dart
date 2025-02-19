class Info {
  final int cooldown;
  final int secretMaxLength;
  final String canary;

  Info({
    required this.cooldown,
    required this.secretMaxLength,
    required this.canary,
  });

  factory Info.fromMap(Map<String, dynamic> map) {
    return Info(
      canary: map['canary'] as String,
      cooldown: map['cooldown'] as int,
      secretMaxLength: map['secret_max_length'] as int,
    );
  }
}
