// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'key_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$KeyInfoImpl _$$KeyInfoImplFromJson(Map<String, dynamic> json) =>
    _$KeyInfoImpl(
      keyId: json['keyId'] as String,
      key: (json['key'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      status: json['status'] as String,
      expiredAt: json['expiredAt'] as String?,
      label: json['label'] as String?,
    );

Map<String, dynamic> _$$KeyInfoImplToJson(_$KeyInfoImpl instance) =>
    <String, dynamic>{
      'keyId': instance.keyId,
      'key': instance.key,
      'status': instance.status,
      'expiredAt': instance.expiredAt,
      'label': instance.label,
    };
