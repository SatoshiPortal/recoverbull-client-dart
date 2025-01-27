// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BackupImpl _$$BackupImplFromJson(Map<String, dynamic> json) => _$BackupImpl(
      createdAt: (json['createdAt'] as num).toInt(),
      backupId: json['backupId'] as String,
      nonce: json['nonce'] as String,
      ciphertext: json['ciphertext'] as String,
      salt: json['salt'] as String,
      mac: json['mac'] as String,
    );

Map<String, dynamic> _$$BackupImplToJson(_$BackupImpl instance) =>
    <String, dynamic>{
      'createdAt': instance.createdAt,
      'backupId': instance.backupId,
      'nonce': instance.nonce,
      'ciphertext': instance.ciphertext,
      'salt': instance.salt,
      'mac': instance.mac,
    };
