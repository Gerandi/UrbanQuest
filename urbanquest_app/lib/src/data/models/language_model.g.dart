// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Language _$LanguageFromJson(Map<String, dynamic> json) => Language(
      code: json['code'] as String,
      name: json['name'] as String,
      nativeName: json['native_name'] as String,
      flagEmoji: json['flag_emoji'] as String?,
      flagUrl: json['flag_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isDefault: json['is_default'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$LanguageToJson(Language instance) => <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'native_name': instance.nativeName,
      'flag_emoji': instance.flagEmoji,
      'flag_url': instance.flagUrl,
      'is_active': instance.isActive,
      'is_default': instance.isDefault,
      'sort_order': instance.sortOrder,
    };
