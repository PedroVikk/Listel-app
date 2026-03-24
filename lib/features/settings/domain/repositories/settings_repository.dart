import '../entities/theme_settings.dart';

abstract interface class SettingsRepository {
  Future<ThemeSettings> get();
  Future<void> save(ThemeSettings settings);
  Stream<ThemeSettings> watch();
}
