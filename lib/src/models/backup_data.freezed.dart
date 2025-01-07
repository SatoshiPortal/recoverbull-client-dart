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
  int get version => throw _privateConstructorUsedError;
  String get backupId => throw _privateConstructorUsedError;
  String get keyId => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError;
  String get nonce => throw _privateConstructorUsedError;
  String get ciphertext => throw _privateConstructorUsedError;
  String? get tag => throw _privateConstructorUsedError;

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
  $Res call(
      {int version,
      String backupId,
      String keyId,
      int createdAt,
      String nonce,
      String ciphertext,
      String? tag});
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
    Object? version = null,
    Object? backupId = null,
    Object? keyId = null,
    Object? createdAt = null,
    Object? nonce = null,
    Object? ciphertext = null,
    Object? tag = freezed,
  }) {
    return _then(_value.copyWith(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      backupId: null == backupId
          ? _value.backupId
          : backupId // ignore: cast_nullable_to_non_nullable
              as String,
      keyId: null == keyId
          ? _value.keyId
          : keyId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      nonce: null == nonce
          ? _value.nonce
          : nonce // ignore: cast_nullable_to_non_nullable
              as String,
      ciphertext: null == ciphertext
          ? _value.ciphertext
          : ciphertext // ignore: cast_nullable_to_non_nullable
              as String,
      tag: freezed == tag
          ? _value.tag
          : tag // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
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
  $Res call(
      {int version,
      String backupId,
      String keyId,
      int createdAt,
      String nonce,
      String ciphertext,
      String? tag});
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
    Object? version = null,
    Object? backupId = null,
    Object? keyId = null,
    Object? createdAt = null,
    Object? nonce = null,
    Object? ciphertext = null,
    Object? tag = freezed,
  }) {
    return _then(_$BackupMetadataImpl(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      backupId: null == backupId
          ? _value.backupId
          : backupId // ignore: cast_nullable_to_non_nullable
              as String,
      keyId: null == keyId
          ? _value.keyId
          : keyId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      nonce: null == nonce
          ? _value.nonce
          : nonce // ignore: cast_nullable_to_non_nullable
              as String,
      ciphertext: null == ciphertext
          ? _value.ciphertext
          : ciphertext // ignore: cast_nullable_to_non_nullable
              as String,
      tag: freezed == tag
          ? _value.tag
          : tag // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BackupMetadataImpl extends _BackupMetadata {
  _$BackupMetadataImpl(
      {this.version = 1,
      required this.backupId,
      required this.keyId,
      required this.createdAt,
      required this.nonce,
      required this.ciphertext,
      this.tag})
      : super._();

  factory _$BackupMetadataImpl.fromJson(Map<String, dynamic> json) =>
      _$$BackupMetadataImplFromJson(json);

  @override
  @JsonKey()
  final int version;
  @override
  final String backupId;
  @override
  final String keyId;
  @override
  final int createdAt;
  @override
  final String nonce;
  @override
  final String ciphertext;
  @override
  final String? tag;

  @override
  String toString() {
    return 'BackupMetadata(version: $version, backupId: $backupId, keyId: $keyId, createdAt: $createdAt, nonce: $nonce, ciphertext: $ciphertext, tag: $tag)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BackupMetadataImpl &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.backupId, backupId) ||
                other.backupId == backupId) &&
            (identical(other.keyId, keyId) || other.keyId == keyId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.nonce, nonce) || other.nonce == nonce) &&
            (identical(other.ciphertext, ciphertext) ||
                other.ciphertext == ciphertext) &&
            (identical(other.tag, tag) || other.tag == tag));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, version, backupId, keyId, createdAt, nonce, ciphertext, tag);

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

abstract class _BackupMetadata extends BackupMetadata {
  factory _BackupMetadata(
      {final int version,
      required final String backupId,
      required final String keyId,
      required final int createdAt,
      required final String nonce,
      required final String ciphertext,
      final String? tag}) = _$BackupMetadataImpl;
  _BackupMetadata._() : super._();

  factory _BackupMetadata.fromJson(Map<String, dynamic> json) =
      _$BackupMetadataImpl.fromJson;

  @override
  int get version;
  @override
  String get backupId;
  @override
  String get keyId;
  @override
  int get createdAt;
  @override
  String get nonce;
  @override
  String get ciphertext;
  @override
  String? get tag;

  /// Create a copy of BackupMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BackupMetadataImplCopyWith<_$BackupMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
