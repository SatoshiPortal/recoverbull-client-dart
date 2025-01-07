// key_info.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'key_info.freezed.dart';
part 'key_info.g.dart';

@freezed
class KeyInfo with _$KeyInfo {
  factory KeyInfo({
    required String keyId,
    required List<int> key,
    required String status,
    String? expiredAt,
    String? label,
  }) = _KeyInfo;

  factory KeyInfo.fromJson(Map<String, dynamic> json) =>
      _$KeyInfoFromJson(json);
}
