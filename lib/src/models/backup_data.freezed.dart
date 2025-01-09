// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'backup_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BackupMetadata _$BackupMetadataFromJson(Map<String, dynamic> json) {
  return _BackupMetadata.fromJson(json);
}

/// @nodoc
mixin _$BackupMetadata {
  /// Unique identifier for the backup
  String get backupId => throw _privateConstructorUsedError;

  /// Encryption data used to secure the backup
  EncryptedData get encryptedData => throw _privateConstructorUsedError;

  /// Unix timestamp (in seconds) when the backup was created
  int get createdAt => throw _privateConstructorUsedError;

  /// Serializes this BackupMetadata to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BackupMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BackupMetadataCopyWith<BackupMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BackupMetadataCopyWith<$Res> {
  factory $BackupMetadataCopyWith(
          BackupMetadata value, $Res Function(BackupMetadata) then) =
      _$BackupMetadataCopyWithImpl<$Res, BackupMetadata>;
  @useResult
  $Res call({String backupId, EncryptedData encryptedData, int createdAt});

  $EncryptedDataCopyWith<$Res> get encryptedData;
}

/// @nodoc
class _$BackupMetadataCopyWithImpl<$Res, $Val extends BackupMetadata>
    implements $BackupMetadataCopyWith<$Res> {
  _$BackupMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BackupMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? backupId = null,
    Object? encryptedData = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      backupId: null == backupId
          ? _value.backupId
          : backupId // ignore: cast_nullable_to_non_nullable
              as String,
      encryptedData: null == encryptedData
          ? _value.encryptedData
          : encryptedData // ignore: cast_nullable_to_non_nullable
              as EncryptedData,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  /// Create a copy of BackupMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EncryptedDataCopyWith<$Res> get encryptedData {
    return $EncryptedDataCopyWith<$Res>(_value.encryptedData, (value) {
      return _then(_value.copyWith(encryptedData: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BackupMetadataImplCopyWith<$Res>
    implements $BackupMetadataCopyWith<$Res> {
  factory _$$BackupMetadataImplCopyWith(_$BackupMetadataImpl value,
          $Res Function(_$BackupMetadataImpl) then) =
      __$$BackupMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String backupId, EncryptedData encryptedData, int createdAt});

  @override
  $EncryptedDataCopyWith<$Res> get encryptedData;
}

/// @nodoc
class __$$BackupMetadataImplCopyWithImpl<$Res>
    extends _$BackupMetadataCopyWithImpl<$Res, _$BackupMetadataImpl>
    implements _$$BackupMetadataImplCopyWith<$Res> {
  __$$BackupMetadataImplCopyWithImpl(
      _$BackupMetadataImpl _value, $Res Function(_$BackupMetadataImpl) _then)
      : super(_value, _then);

  /// Create a copy of BackupMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? backupId = null,
    Object? encryptedData = null,
    Object? createdAt = null,
  }) {
    return _then(_$BackupMetadataImpl(
      backupId: null == backupId
          ? _value.backupId
          : backupId // ignore: cast_nullable_to_non_nullable
              as String,
      encryptedData: null == encryptedData
          ? _value.encryptedData
          : encryptedData // ignore: cast_nullable_to_non_nullable
              as EncryptedData,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BackupMetadataImpl implements _BackupMetadata {
  const _$BackupMetadataImpl(
      {required this.backupId,
      required this.encryptedData,
      required this.createdAt});

  factory _$BackupMetadataImpl.fromJson(Map<String, dynamic> json) =>
      _$$BackupMetadataImplFromJson(json);

  /// Unique identifier for the backup
  @override
  final String backupId;

  /// Encryption data used to secure the backup
  @override
  final EncryptedData encryptedData;

  /// Unix timestamp (in seconds) when the backup was created
  @override
  final int createdAt;

  @override
  String toString() {
    return 'BackupMetadata(backupId: $backupId, encryptedData: $encryptedData, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BackupMetadataImpl &&
            (identical(other.backupId, backupId) ||
                other.backupId == backupId) &&
            (identical(other.encryptedData, encryptedData) ||
                other.encryptedData == encryptedData) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, backupId, encryptedData, createdAt);

  /// Create a copy of BackupMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BackupMetadataImplCopyWith<_$BackupMetadataImpl> get copyWith =>
      __$$BackupMetadataImplCopyWithImpl<_$BackupMetadataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BackupMetadataImplToJson(
      this,
    );
  }
}

abstract class _BackupMetadata implements BackupMetadata {
  const factory _BackupMetadata(
      {required final String backupId,
      required final EncryptedData encryptedData,
      required final int createdAt}) = _$BackupMetadataImpl;

  factory _BackupMetadata.fromJson(Map<String, dynamic> json) =
      _$BackupMetadataImpl.fromJson;

  /// Unique identifier for the backup
  @override
  String get backupId;

  /// Encryption data used to secure the backup
  @override
  EncryptedData get encryptedData;

  /// Unix timestamp (in seconds) when the backup was created
  @override
  int get createdAt;

  /// Create a copy of BackupMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BackupMetadataImplCopyWith<_$BackupMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
