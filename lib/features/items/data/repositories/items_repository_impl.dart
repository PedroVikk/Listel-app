import 'package:isar/isar.dart';
import '../../domain/entities/saved_item.dart';
import '../../domain/repositories/items_repository.dart';
import '../models/saved_item_model.dart';
import '../../../../core/services/isar_service.dart';

class ItemsRepositoryImpl implements ItemsRepository {
  Isar get _db => IsarService.db;

  @override
  Future<List<SavedItem>> getByCollection(String collectionId) async {
    final models = await _db.savedItemModels
        .where()
        .collectionIdEqualTo(collectionId)
        .sortByCreatedAtDesc()
        .findAll();
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  Future<SavedItem?> getById(String id) async {
    final model = await _db.savedItemModels.where().idEqualTo(id).findFirst();
    return model?.toDomain();
  }

  @override
  Future<void> save(SavedItem item) async {
    final existing =
        await _db.savedItemModels.where().idEqualTo(item.id).findFirst();
    final model = SavedItemModel.fromDomain(item);
    if (existing != null) model.isarId = existing.isarId;
    await _db.writeTxn(() => _db.savedItemModels.put(model));
  }

  @override
  Future<void> delete(String id) async {
    await _db.writeTxn(() async {
      final model = await _db.savedItemModels.where().idEqualTo(id).findFirst();
      if (model != null) await _db.savedItemModels.delete(model.isarId);
    });
  }

  @override
  Stream<List<SavedItem>> watchByCollection(String collectionId) {
    return _db.savedItemModels
        .where()
        .collectionIdEqualTo(collectionId)
        .watch(fireImmediately: true)
        .map((models) => models.map((m) => m.toDomain()).toList());
  }

  @override
  Future<List<SavedItem>> searchByName(String query) async {
    final results = await _db.savedItemModels
        .filter()
        .nameContains(query, caseSensitive: false)
        .sortByCreatedAtDesc()
        .findAll();
    return results.map((m) => m.toDomain()).toList();
  }
}
