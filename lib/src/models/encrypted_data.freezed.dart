// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'encrypted_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EncryptedData _$EncryptedDataFromJson(Map<String, dynamic> json) {
  return _EncryptedData.fromJson(json);
}

/// @nodoc
mixin _$EncryptedData {
  String get nonce => throw _privateConstructorUsedError;

  /// - [ciphertext]: The encrypted backup data
  String get ciphertext => throw _privateConstructorUsedError;

  /// - [tag]: Optional authentication tag for the encrypted data
  String? get tag => throw _privateConstructorUsedError;

  /// Serializes this EncryptedData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EncryptedData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EncryptedDataCopyWith<EncryptedData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EncryptedDataCopyWith<$Res> {
  factory $EncryptedDataCopyWith(
          EncryptedData value, $Res Function(EncryptedData) then) =
      _$EncryptedDataCopyWithImpl<$Res, EncryptedData>;
  @useResult
  $Res call({String nonce, String ciphertext, String? tag});
}

/// @nodoc
class _$EncryptedDataCopyWithImpl<$Res, $Val extends EncryptedData>
    implements $EncryptedDataCopyWith<$Res> {
  _$EncryptedDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EncryptedData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nonce = null,
    Object? ciphertext = null,
    Object? tag = freezed,
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
      tag: freezed == tag
          ? _value.tag
          : tag // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EncryptedDataImplCopyWith<$Res>
    implements $EncryptedDataCopyWith<$Res> {
  factory _$$EncryptedDataImplCopyWith(
          _$EncryptedDataImpl value, $Res Function(_$EncryptedDataImpl) then) =
      __$$EncryptedDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String nonce, String ciphertext, String? tag});
}

/// @nodoc
class __$$EncryptedDataImplCopyWithImpl<$Res>
    extends _$EncryptedDataCopyWithImpl<$Res, _$EncryptedDataImpl>
    implements _$$EncryptedDataImplCopyWith<$Res> {
  __$$EncryptedDataImplCopyWithImpl(
      _$EncryptedDataImpl _value, $Res Function(_$EncryptedDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of EncryptedData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nonce = null,
    Object? ciphertext = null,
    Object? tag = freezed,
  }) {
    return _then(_$EncryptedDataImpl(
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
class _$EncryptedDataImpl implements _EncryptedData {
  _$EncryptedDataImpl(
      {required this.nonce, required this.ciphertext, this.tag});

  factory _$EncryptedDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$EncryptedDataImplFromJson(json);

  @override
  final String nonce;

  /// - [ciphertext]: The encrypted backup data
  @override
  final String ciphertext;

  /// - [tag]: Optional authentication tag for the encrypted data
  @override
  final String? tag;

  @override
  String toString() {
    return 'EncryptedData(nonce: $nonce, ciphertext: $ciphertext, tag: $tag)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EncryptedDataImpl &&
            (identical(other.nonce, nonce) || other.nonce == nonce) &&
            (identical(other.ciphertext, ciphertext) ||
                other.ciphertext == ciphertext) &&
            (identical(other.tag, tag) || other.tag == tag));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, nonce, ciphertext, tag);

  /// Create a copy of EncryptedData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EncryptedDataImplCopyWith<_$EncryptedDataImpl> get copyWith =>
      __$$EncryptedDataImplCopyWithImpl<_$EncryptedDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EncryptedDataImplToJson(
      this,
    );
  }
}

abstract class _EncryptedData implements EncryptedData {
  factory _EncryptedData(
      {required final String nonce,
      required final String ciphertext,
      final String? tag}) = _$EncryptedDataImpl;

  factory _EncryptedData.fromJson(Map<String, dynamic> json) =
      _$EncryptedDataImpl.fromJson;

  @override
  String get nonce;

  /// - [ciphertext]: The encrypted backup data
  @override
  String get ciphertext;

  /// - [tag]: Optional authentication tag for the encrypted data
  @override
  String? get tag;

  /// Create a copy of EncryptedData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EncryptedDataImplCopyWith<_$EncryptedDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
