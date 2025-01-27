// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'encryption_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EncryptionResultImpl _$$EncryptionResultImplFromJson(
        Map<String, dynamic> json) =>
    _$EncryptionResultImpl(
      nonce: json['nonce'] as String,
      ciphertext: json['ciphertext'] as String,
      mac: json['mac'] as String,
    );

Map<String, dynamic> _$$EncryptionResultImplToJson(
        _$EncryptionResultImpl instance) =>
    <String, dynamic>{
      'nonce': instance.nonce,
      'ciphertext': instance.ciphertext,
      'mac': instance.mac,
    };
