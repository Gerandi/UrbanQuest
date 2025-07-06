import 'package:json_annotation/json_annotation.dart';

part 'language_model.g.dart';

@JsonSerializable()
class Language {
  final String code;
  final String name;
  @JsonKey(name: 'native_name')
  final String nativeName;
  @JsonKey(name: 'flag_emoji')
  final String? flagEmoji;
  @JsonKey(name: 'flag_url')
  final String? flagUrl;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'is_default')
  final bool isDefault;
  @JsonKey(name: 'sort_order')
  final int sortOrder;

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    this.flagEmoji,
    this.flagUrl,
    this.isActive = true,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  factory Language.fromJson(Map<String, dynamic> json) => _$LanguageFromJson(json);
  Map<String, dynamic> toJson() => _$LanguageToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => '$name ($code)';
} 