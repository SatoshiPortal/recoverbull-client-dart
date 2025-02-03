// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BackupImpl _$$BackupImplFromJson(Map<String, dynamic> json) => _$BackupImpl(
      createdAt: (json['createdAt'] as num).toInt(),
      id: json['id'] as String,
      ciphertext: json['ciphertext'] as String,
      salt: json['salt'] as String,
    );

Map<String, dynamic> _$$BackupImplToJson(_$BackupImpl instance) =>
    <String, dynamic>{
      'createdAt': instance.createdAt,
      'id': instance.id,
      'ciphertext': instance.ciphertext,
      'salt': instance.salt,
    };
