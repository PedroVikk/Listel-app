import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/collections/data/models/collection_model.dart';
import '../../features/items/data/models/saved_item_model.dart';
import '../../features/settings/data/models/theme_settings_model.dart';

class IsarService {
  static Isar? _instance;

  static Future<Isar> getInstance() async {
    if (_instance != null && _instance!.isOpen) return _instance!;
    final dir = await getApplicationDocumentsDirectory();
    _instance = await Isar.open(
      [
        CollectionModelSchema,
        SavedItemModelSchema,
        ThemeSettingsModelSchema,
      ],
      directory: dir.path,
      name: 'wish_nesita_db',
    );
    return _instance!;
  }

  static Isar get db {
    assert(_instance != null && _instance!.isOpen, 'Isar not initialized. Call IsarService.getInstance() first.');
    return _instance!;
  }
}
