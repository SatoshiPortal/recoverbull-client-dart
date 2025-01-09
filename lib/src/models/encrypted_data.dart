import 'package:freezed_annotation/freezed_annotation.dart';

part 'encrypted_data.freezed.dart';
part 'encrypted_data.g.dart';

@freezed
class EncryptedData with _$EncryptedData {
  factory EncryptedData({
    required String nonce,

    /// - [ciphertext]: The encrypted backup data
    required String ciphertext,

    /// - [tag]: Optional authentication tag for the encrypted data
    String? tag,
  }) = _EncryptedData;

  factory EncryptedData.fromJson(Map<String, dynamic> json) =>
      _$EncryptedDataFromJson(json);
}
