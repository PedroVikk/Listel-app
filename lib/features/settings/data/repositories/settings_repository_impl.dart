import 'package:isar/isar.dart';
import '../../domain/entities/theme_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../models/theme_settings_model.dart';
import '../../../../core/services/isar_service.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  Isar get _db => IsarService.db;

  @override
  Future<ThemeSettings> get() async {
    final model = await _db.themeSettingsModels.get(1);
    return model?.toDomain() ?? ThemeSettings.defaults;
  }

  @override
  Future<void> save(ThemeSettings settings) async {
    final model = ThemeSettingsModel.fromDomain(settings);
    await _db.writeTxn(() => _db.themeSettingsModels.put(model));
  }

  @override
  Stream<ThemeSettings> watch() {
    return _db.themeSettingsModels
        .watchObject(1, fireImmediately: true)
        .map((model) => model?.toDomain() ?? ThemeSettings.defaults);
  }
}
