import 'package:freezed_annotation/freezed_annotation.dart';

part 'encryption_result.freezed.dart';
part 'encryption_result.g.dart';

@freezed
class EncryptionResult with _$EncryptionResult {
  factory EncryptionResult({
    required String nonce,

    /// - [ciphertext]: The encrypted backup data
    required String ciphertext,

    /// - [mac]: authentication mac for the encrypted data
    required String mac,
  }) = _EncryptionResult;

  factory EncryptionResult.fromJson(Map<String, dynamic> json) =>
      _$EncryptionResultFromJson(json);
}
