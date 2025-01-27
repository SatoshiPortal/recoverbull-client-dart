import 'package:pointycastle/pointycastle.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:recoverbull/recoverbull.dart';

/// The [Argon2] class provides functionalities to derive and verify password hashes
/// using the Argon2id variant with specified parameters.
class Argon2 {
  static const algo = 'argon2';

  /// iteration count of 2
  static const iterations = 2;

  /// 19 MiB of memory
  static const memory = 19 * 1024;

  /// 1 degree of parallelism
  static const parallelism = 1;

  /// Derives a cryptographic hash from the given `password` and `salt`.
  ///
  /// - `password`: The plaintext password to hash.
  /// - `salt`: A unique, random salt to prevent rainbow table attacks.
  /// - `length`: Desired length of the derived hash in bytes.
  ///
  /// Returns a list of integers representing the derived hash.
  static List<int> hash({
    required String password,
    required List<int> salt,
    required int length,
  }) {
    final passwordBytes = utf8.encode(password);

    final argon2Params = Argon2Parameters(
      Argon2Parameters.ARGON2_id,
      Uint8List.fromList(salt),
      version: Argon2Parameters.ARGON2_VERSION_13,
      iterations: Argon2.iterations,
      memory: Argon2.memory,
      lanes: Argon2.parallelism,
      desiredKeyLength: length,
    );

    final argon2 = KeyDerivator(Argon2.algo)..init(argon2Params);
    return argon2.process(passwordBytes);
  }

  /// Verifies whether the provided `password` matches the `hash` using the `salt`.
  ///
  /// - `password`: The plaintext password to verify.
  /// - `hash`: The stored hash to compare against.
  /// - `salt`: The salt used during the original hash derivation.
  ///
  /// Returns `true` if the password is valid; otherwise, `false`.
  static bool verify({
    required String password,
    required List<int> hash,
    required Uint8List salt,
  }) {
    final newHash = Argon2.hash(
      password: password,
      salt: salt,
      length: hash.length,
    );

    return constantTimeComparison(Uint8List.fromList(hash), newHash);
  }
}
