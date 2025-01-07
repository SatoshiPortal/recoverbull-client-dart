// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BackupMetadataImpl _$$BackupMetadataImplFromJson(Map<String, dynamic> json) =>
    _$BackupMetadataImpl(
      version: (json['version'] as num?)?.toInt() ?? 1,
      backupId: json['backupId'] as String,
      keyId: json['keyId'] as String,
      createdAt: (json['createdAt'] as num).toInt(),
      nonce: json['nonce'] as String,
      ciphertext: json['ciphertext'] as String,
      tag: json['tag'] as String?,
    );

Map<String, dynamic> _$$BackupMetadataImplToJson(
        _$BackupMetadataImpl instance) =>
    <String, dynamic>{
      'version': instance.version,
      'backupId': instance.backupId,
      'keyId': instance.keyId,
      'createdAt': instance.createdAt,
      'nonce': instance.nonce,
      'ciphertext': instance.ciphertext,
      'tag': instance.tag,
    };
