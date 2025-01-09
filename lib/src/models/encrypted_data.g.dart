// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'encrypted_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EncryptedDataImpl _$$EncryptedDataImplFromJson(Map<String, dynamic> json) =>
    _$EncryptedDataImpl(
      nonce: json['nonce'] as String,
      ciphertext: json['ciphertext'] as String,
      tag: json['tag'] as String?,
    );

Map<String, dynamic> _$$EncryptedDataImplToJson(_$EncryptedDataImpl instance) =>
    <String, dynamic>{
      'nonce': instance.nonce,
      'ciphertext': instance.ciphertext,
      'tag': instance.tag,
    };
