// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'backup.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Backup _$BackupFromJson(Map<String, dynamic> json) {
  return _Backup.fromJson(json);
}

/// @nodoc
mixin _$Backup {
  /// Unix timestamp (in seconds) when the backup was created
  int get createdAt => throw _privateConstructorUsedError;

  /// Unique identifier for the backup
  String get backupId => throw _privateConstructorUsedError;

  /// Hex encoded nonce used for backup file encryption
  String get nonce => throw _privateConstructorUsedError;

  /// Encryption data used to secure the backup
  String get ciphertext => throw _privateConstructorUsedError;

  /// Hex encoded salt may be used for password key derivation (Argon2)
  String get salt => throw _privateConstructorUsedError;

  /// - [mac]: Optional authentication mac for the encrypted data
  String get mac => throw _privateConstructorUsedError;

  /// Serializes this Backup to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Backup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BackupCopyWith<Backup> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BackupCopyWith<$Res> {
  factory $BackupCopyWith(Backup value, $Res Function(Backup) then) =
      _$BackupCopyWithImpl<$Res, Backup>;
  @useResult
  $Res call(
      {int createdAt,
      String backupId,
      String nonce,
      String ciphertext,
      String salt,
      String mac});
}

/// @nodoc
class _$BackupCopyWithImpl<$Res, $Val extends Backup>
    implements $BackupCopyWith<$Res> {
  _$BackupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Backup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? createdAt = null,
    Object? backupId = null,
    Object? nonce = null,
    Object? ciphertext = null,
    Object? salt = null,
    Object? mac = null,
  }) {
    return _then(_value.copyWith(
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      backupId: null == backupId
          ? _value.backupId
          : backupId // ignore: cast_nullable_to_non_nullable
              as String,
      nonce: null == nonce
          ? _value.nonce
          : nonce // ignore: cast_nullable_to_non_nullable
              as String,
      ciphertext: null == ciphertext
          ? _value.ciphertext
          : ciphertext // ignore: cast_nullable_to_non_nullable
              as String,
      salt: null == salt
          ? _value.salt
          : salt // ignore: cast_nullable_to_non_nullable
              as String,
      mac: null == mac
          ? _value.mac
          : mac // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BackupImplCopyWith<$Res> implements $BackupCopyWith<$Res> {
  factory _$$BackupImplCopyWith(
          _$BackupImpl value, $Res Function(_$BackupImpl) then) =
      __$$BackupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int createdAt,
      String backupId,
      String nonce,
      String ciphertext,
      String salt,
      String mac});
}

/// @nodoc
class __$$BackupImplCopyWithImpl<$Res>
    extends _$BackupCopyWithImpl<$Res, _$BackupImpl>
    implements _$$BackupImplCopyWith<$Res> {
  __$$BackupImplCopyWithImpl(
      _$BackupImpl _value, $Res Function(_$BackupImpl) _then)
      : super(_value, _then);

  /// Create a copy of Backup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? createdAt = null,
    Object? backupId = null,
    Object? nonce = null,
    Object? ciphertext = null,
    Object? salt = null,
    Object? mac = null,
  }) {
    return _then(_$BackupImpl(
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      backupId: null == backupId
          ? _value.backupId
          : backupId // ignore: cast_nullable_to_non_nullable
              as String,
      nonce: null == nonce
          ? _value.nonce
          : nonce // ignore: cast_nullable_to_non_nullable
              as String,
      ciphertext: null == ciphertext
          ? _value.ciphertext
          : ciphertext // ignore: cast_nullable_to_non_nullable
              as String,
      salt: null == salt
          ? _value.salt
          : salt // ignore: cast_nullable_to_non_nullable
              as String,
      mac: null == mac
          ? _value.mac
          : mac // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BackupImpl implements _Backup {
  const _$BackupImpl(
      {required this.createdAt,
      required this.backupId,
      required this.nonce,
      required this.ciphertext,
      required this.salt,
      required this.mac});

  factory _$BackupImpl.fromJson(Map<String, dynamic> json) =>
      _$$BackupImplFromJson(json);

  /// Unix timestamp (in seconds) when the backup was created
  @override
  final int createdAt;

  /// Unique identifier for the backup
  @override
  final String backupId;

  /// Hex encoded nonce used for backup file encryption
  @override
  final String nonce;

  /// Encryption data used to secure the backup
  @override
  final String ciphertext;

  /// Hex encoded salt may be used for password key derivation (Argon2)
  @override
  final String salt;

  /// - [mac]: Optional authentication mac for the encrypted data
  @override
  final String mac;

  @override
  String toString() {
    return 'Backup(createdAt: $createdAt, backupId: $backupId, nonce: $nonce, ciphertext: $ciphertext, salt: $salt, mac: $mac)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BackupImpl &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.backupId, backupId) ||
                other.backupId == backupId) &&
            (identical(other.nonce, nonce) || other.nonce == nonce) &&
            (identical(other.ciphertext, ciphertext) ||
                other.ciphertext == ciphertext) &&
            (identical(other.salt, salt) || other.salt == salt) &&
            (identical(other.mac, mac) || other.mac == mac));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, createdAt, backupId, nonce, ciphertext, salt, mac);

  /// Create a copy of Backup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BackupImplCopyWith<_$BackupImpl> get copyWith =>
      __$$BackupImplCopyWithImpl<_$BackupImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BackupImplToJson(
      this,
    );
  }
}

abstract class _Backup implements Backup {
  const factory _Backup(
      {required final int createdAt,
      required final String backupId,
      required final String nonce,
      required final String ciphertext,
      required final String salt,
      required final String mac}) = _$BackupImpl;

  factory _Backup.fromJson(Map<String, dynamic> json) = _$BackupImpl.fromJson;

  /// Unix timestamp (in seconds) when the backup was created
  @override
  int get createdAt;

  /// Unique identifier for the backup
  @override
  String get backupId;

  /// Hex encoded nonce used for backup file encryption
  @override
  String get nonce;

  /// Encryption data used to secure the backup
  @override
  String get ciphertext;

  /// Hex encoded salt may be used for password key derivation (Argon2)
  @override
  String get salt;

  /// - [mac]: Optional authentication mac for the encrypted data
  @override
  String get mac;

  /// Create a copy of Backup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BackupImplCopyWith<_$BackupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
