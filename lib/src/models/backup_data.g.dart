// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BackupMetadataImpl _$$BackupMetadataImplFromJson(Map<String, dynamic> json) =>
    _$BackupMetadataImpl(
      backupId: json['backupId'] as String,
      encryptedData:
          EncryptedData.fromJson(json['encryptedData'] as Map<String, dynamic>),
      createdAt: (json['createdAt'] as num).toInt(),
    );

Map<String, dynamic> _$$BackupMetadataImplToJson(
        _$BackupMetadataImpl instance) =>
    <String, dynamic>{
      'backupId': instance.backupId,
      'encryptedData': instance.encryptedData,
      'createdAt': instance.createdAt,
    };
