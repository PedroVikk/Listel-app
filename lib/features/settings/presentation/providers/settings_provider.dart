import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/theme_settings.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(),
);

final themeSettingsProvider = StreamProvider<ThemeSettings>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watch();
});

class ThemeSettingsNotifier extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() => ThemeSettings.defaults;

  Future<void> updatePrimaryColor(Color color) async {
    final updated = state.copyWith(primaryColorValue: color.toARGB32());
    await _repo.save(updated);
    state = updated;
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final updated = state.copyWith(themeMode: mode);
    await _repo.save(updated);
    state = updated;
  }

  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);
}

final themeSettingsNotifierProvider =
    NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
  ThemeSettingsNotifier.new,
);
