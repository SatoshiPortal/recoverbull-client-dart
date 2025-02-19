class Payload {
  final int timestamp;
  final String data;

  Payload({required this.timestamp, required this.data});

  factory Payload.fromMap(Map<String, dynamic> map) {
    return Payload(
      data: map['data'] as String,
      timestamp: map['timestamp'] as int,
    );
  }
}
