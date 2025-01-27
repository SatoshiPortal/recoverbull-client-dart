// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'encryption_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EncryptionResult _$EncryptionResultFromJson(Map<String, dynamic> json) {
  return _EncryptionResult.fromJson(json);
}

/// @nodoc
mixin _$EncryptionResult {
  String get nonce => throw _privateConstructorUsedError;

  /// - [ciphertext]: The encrypted backup data
  String get ciphertext => throw _privateConstructorUsedError;

  /// - [mac]: authentication mac for the encrypted data
  String get mac => throw _privateConstructorUsedError;

  /// Serializes this EncryptionResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EncryptionResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EncryptionResultCopyWith<EncryptionResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EncryptionResultCopyWith<$Res> {
  factory $EncryptionResultCopyWith(
          EncryptionResult value, $Res Function(EncryptionResult) then) =
      _$EncryptionResultCopyWithImpl<$Res, EncryptionResult>;
  @useResult
  $Res call({String nonce, String ciphertext, String mac});
}

/// @nodoc
class _$EncryptionResultCopyWithImpl<$Res, $Val extends EncryptionResult>
    implements $EncryptionResultCopyWith<$Res> {
  _$EncryptionResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EncryptionResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nonce = null,
    Object? ciphertext = null,
    Object? mac = null,
  }) {
    return _then(_value.copyWith(
      nonce: null == nonce
          ? _value.nonce
          : nonce // ignore: cast_nullable_to_non_nullable
              as String,
      ciphertext: null == ciphertext
          ? _value.ciphertext
          : ciphertext // ignore: cast_nullable_to_non_nullable
              as String,
      mac: null == mac
          ? _value.mac
          : mac // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EncryptionResultImplCopyWith<$Res>
    implements $EncryptionResultCopyWith<$Res> {
  factory _$$EncryptionResultImplCopyWith(_$EncryptionResultImpl value,
          $Res Function(_$EncryptionResultImpl) then) =
      __$$EncryptionResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String nonce, String ciphertext, String mac});
}

/// @nodoc
class __$$EncryptionResultImplCopyWithImpl<$Res>
    extends _$EncryptionResultCopyWithImpl<$Res, _$EncryptionResultImpl>
    implements _$$EncryptionResultImplCopyWith<$Res> {
  __$$EncryptionResultImplCopyWithImpl(_$EncryptionResultImpl _value,
      $Res Function(_$EncryptionResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of EncryptionResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nonce = null,
    Object? ciphertext = null,
    Object? mac = null,
  }) {
    return _then(_$EncryptionResultImpl(
      nonce: null == nonce
          ? _value.nonce
          : nonce // ignore: cast_nullable_to_non_nullable
              as String,
      ciphertext: null == ciphertext
          ? _value.ciphertext
          : ciphertext // ignore: cast_nullable_to_non_nullable
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
class _$EncryptionResultImpl implements _EncryptionResult {
  _$EncryptionResultImpl(
      {required this.nonce, required this.ciphertext, required this.mac});

  factory _$EncryptionResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$EncryptionResultImplFromJson(json);

  @override
  final String nonce;

  /// - [ciphertext]: The encrypted backup data
  @override
  final String ciphertext;

  /// - [mac]: authentication mac for the encrypted data
  @override
  final String mac;

  @override
  String toString() {
    return 'EncryptionResult(nonce: $nonce, ciphertext: $ciphertext, mac: $mac)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EncryptionResultImpl &&
            (identical(other.nonce, nonce) || other.nonce == nonce) &&
            (identical(other.ciphertext, ciphertext) ||
                other.ciphertext == ciphertext) &&
            (identical(other.mac, mac) || other.mac == mac));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, nonce, ciphertext, mac);

  /// Create a copy of EncryptionResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EncryptionResultImplCopyWith<_$EncryptionResultImpl> get copyWith =>
      __$$EncryptionResultImplCopyWithImpl<_$EncryptionResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EncryptionResultImplToJson(
      this,
    );
  }
}

abstract class _EncryptionResult implements EncryptionResult {
  factory _EncryptionResult(
      {required final String nonce,
      required final String ciphertext,
      required final String mac}) = _$EncryptionResultImpl;

  factory _EncryptionResult.fromJson(Map<String, dynamic> json) =
      _$EncryptionResultImpl.fromJson;

  @override
  String get nonce;

  /// - [ciphertext]: The encrypted backup data
  @override
  String get ciphertext;

  /// - [mac]: authentication mac for the encrypted data
  @override
  String get mac;

  /// Create a copy of EncryptionResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EncryptionResultImplCopyWith<_$EncryptionResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
