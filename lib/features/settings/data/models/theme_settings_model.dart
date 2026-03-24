import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../../domain/entities/theme_settings.dart';

part 'theme_settings_model.g.dart';

@collection
class ThemeSettingsModel {
  Id isarId = 1; // singleton — always id=1

  late int primaryColorValue;
  late int themeModeIndex; // ThemeMode.index

  ThemeSettings toDomain() => ThemeSettings(
        primaryColorValue: primaryColorValue,
        themeMode: ThemeMode.values[themeModeIndex],
      );

  static ThemeSettingsModel fromDomain(ThemeSettings entity) =>
      ThemeSettingsModel()
        ..isarId = 1
        ..primaryColorValue = entity.primaryColorValue
        ..themeModeIndex = entity.themeMode.index;

  static ThemeSettingsModel get defaultModel => ThemeSettingsModel()
    ..isarId = 1
    ..primaryColorValue = ThemeSettings.defaults.primaryColorValue
    ..themeModeIndex = ThemeSettings.defaults.themeMode.index;
}
