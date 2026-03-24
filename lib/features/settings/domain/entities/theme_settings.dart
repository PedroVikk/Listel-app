import 'package:flutter/material.dart';

class ThemeSettings {
  final int primaryColorValue;
  final ThemeMode themeMode;

  const ThemeSettings({
    required this.primaryColorValue,
    required this.themeMode,
  });

  static const ThemeSettings defaults = ThemeSettings(
    primaryColorValue: 0xFFE91E8C, // pink accent
    themeMode: ThemeMode.system,
  );

  Color get primaryColor => Color(primaryColorValue);

  ThemeSettings copyWith({
    int? primaryColorValue,
    ThemeMode? themeMode,
  }) {
    return ThemeSettings(
      primaryColorValue: primaryColorValue ?? this.primaryColorValue,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
