import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/theme_settings.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(),
);

/// Único provider de tema. Carrega do DB no build, atualiza ao salvar.
/// main.dart observa este provider para aplicar o tema em tempo real.
class ThemeSettingsNotifier extends AsyncNotifier<ThemeSettings> {
  @override
  Future<ThemeSettings> build() async {
    return ref.watch(settingsRepositoryProvider).get();
  }

  Future<void> updatePrimaryColor(Color color) async {
    final current = state.valueOrNull ?? ThemeSettings.defaults;
    final updated = current.copyWith(primaryColorValue: color.toARGB32());
    await ref.read(settingsRepositoryProvider).save(updated);
    state = AsyncData(updated);
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final current = state.valueOrNull ?? ThemeSettings.defaults;
    final updated = current.copyWith(themeMode: mode);
    await ref.read(settingsRepositoryProvider).save(updated);
    state = AsyncData(updated);
  }
}

final themeSettingsProvider =
    AsyncNotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
  ThemeSettingsNotifier.new,
);
