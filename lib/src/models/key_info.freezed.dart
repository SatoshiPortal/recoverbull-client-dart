// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'key_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

KeyInfo _$KeyInfoFromJson(Map<String, dynamic> json) {
  return _KeyInfo.fromJson(json);
}

/// @nodoc
mixin _$KeyInfo {
  String get keyId => throw _privateConstructorUsedError;
  List<int> get key => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get expiredAt => throw _privateConstructorUsedError;
  String? get label => throw _privateConstructorUsedError;

  /// Serializes this KeyInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of KeyInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $KeyInfoCopyWith<KeyInfo> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $KeyInfoCopyWith<$Res> {
  factory $KeyInfoCopyWith(KeyInfo value, $Res Function(KeyInfo) then) =
      _$KeyInfoCopyWithImpl<$Res, KeyInfo>;
  @useResult
  $Res call(
      {String keyId,
      List<int> key,
      String status,
      String? expiredAt,
      String? label});
}

/// @nodoc
class _$KeyInfoCopyWithImpl<$Res, $Val extends KeyInfo>
    implements $KeyInfoCopyWith<$Res> {
  _$KeyInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of KeyInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keyId = null,
    Object? key = null,
    Object? status = null,
    Object? expiredAt = freezed,
    Object? label = freezed,
  }) {
    return _then(_value.copyWith(
      keyId: null == keyId
          ? _value.keyId
          : keyId // ignore: cast_nullable_to_non_nullable
              as String,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as List<int>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      expiredAt: freezed == expiredAt
          ? _value.expiredAt
          : expiredAt // ignore: cast_nullable_to_non_nullable
              as String?,
      label: freezed == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$KeyInfoImplCopyWith<$Res> implements $KeyInfoCopyWith<$Res> {
  factory _$$KeyInfoImplCopyWith(
          _$KeyInfoImpl value, $Res Function(_$KeyInfoImpl) then) =
      __$$KeyInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String keyId,
      List<int> key,
      String status,
      String? expiredAt,
      String? label});
}

/// @nodoc
class __$$KeyInfoImplCopyWithImpl<$Res>
    extends _$KeyInfoCopyWithImpl<$Res, _$KeyInfoImpl>
    implements _$$KeyInfoImplCopyWith<$Res> {
  __$$KeyInfoImplCopyWithImpl(
      _$KeyInfoImpl _value, $Res Function(_$KeyInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of KeyInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keyId = null,
    Object? key = null,
    Object? status = null,
    Object? expiredAt = freezed,
    Object? label = freezed,
  }) {
    return _then(_$KeyInfoImpl(
      keyId: null == keyId
          ? _value.keyId
          : keyId // ignore: cast_nullable_to_non_nullable
              as String,
      key: null == key
          ? _value._key
          : key // ignore: cast_nullable_to_non_nullable
              as List<int>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      expiredAt: freezed == expiredAt
          ? _value.expiredAt
          : expiredAt // ignore: cast_nullable_to_non_nullable
              as String?,
      label: freezed == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$KeyInfoImpl implements _KeyInfo {
  _$KeyInfoImpl(
      {required this.keyId,
      required final List<int> key,
      required this.status,
      this.expiredAt,
      this.label})
      : _key = key;

  factory _$KeyInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$KeyInfoImplFromJson(json);

  @override
  final String keyId;
  final List<int> _key;
  @override
  List<int> get key {
    if (_key is EqualUnmodifiableListView) return _key;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_key);
  }

  @override
  final String status;
  @override
  final String? expiredAt;
  @override
  final String? label;

  @override
  String toString() {
    return 'KeyInfo(keyId: $keyId, key: $key, status: $status, expiredAt: $expiredAt, label: $label)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KeyInfoImpl &&
            (identical(other.keyId, keyId) || other.keyId == keyId) &&
            const DeepCollectionEquality().equals(other._key, _key) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.expiredAt, expiredAt) ||
                other.expiredAt == expiredAt) &&
            (identical(other.label, label) || other.label == label));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, keyId,
      const DeepCollectionEquality().hash(_key), status, expiredAt, label);

  /// Create a copy of KeyInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$KeyInfoImplCopyWith<_$KeyInfoImpl> get copyWith =>
      __$$KeyInfoImplCopyWithImpl<_$KeyInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$KeyInfoImplToJson(
      this,
    );
  }
}

abstract class _KeyInfo implements KeyInfo {
  factory _KeyInfo(
      {required final String keyId,
      required final List<int> key,
      required final String status,
      final String? expiredAt,
      final String? label}) = _$KeyInfoImpl;

  factory _KeyInfo.fromJson(Map<String, dynamic> json) = _$KeyInfoImpl.fromJson;

  @override
  String get keyId;
  @override
  List<int> get key;
  @override
  String get status;
  @override
  String? get expiredAt;
  @override
  String? get label;

  /// Create a copy of KeyInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$KeyInfoImplCopyWith<_$KeyInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
