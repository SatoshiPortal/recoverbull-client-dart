import 'dart:math';
import 'dart:typed_data';

Uint8List generateRandomSalt({int length = 32}) {
  final secureRandom = Random.secure();
  final saltBytes = Uint8List(length);
  for (int i = 0; i < length; i++) {
    saltBytes[i] = secureRandom.nextInt(256);
  }
  return saltBytes;
}
