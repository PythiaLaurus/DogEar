// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserPreferencesModel _$UserPreferencesModelFromJson(
  Map<String, dynamic> json,
) => _UserPreferencesModel(
  shortcut: json['shortcut'] == null
      ? null
      : HotKey.fromJson(json['shortcut'] as Map<String, dynamic>),
  dogEarColorARGB: (json['dogEarColorARGB'] as num?)?.toInt() ?? 0xFFBCAAA4,
  closeToTray: json['closeToTray'] as bool? ?? true,
  showTrayIcon: json['showTrayIcon'] as bool? ?? true,
);

Map<String, dynamic> _$UserPreferencesModelToJson(
  _UserPreferencesModel instance,
) => <String, dynamic>{
  'shortcut': instance.shortcut,
  'dogEarColorARGB': instance.dogEarColorARGB,
  'closeToTray': instance.closeToTray,
  'showTrayIcon': instance.showTrayIcon,
};
