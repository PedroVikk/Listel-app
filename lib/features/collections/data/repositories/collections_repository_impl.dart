import 'package:isar/isar.dart' hide Collection;
import '../../domain/entities/collection.dart';
import '../../domain/repositories/collections_repository.dart';
import '../models/collection_model.dart';
import '../../../../core/services/isar_service.dart';

class CollectionsRepositoryImpl implements CollectionsRepository {
  Isar get _db => IsarService.db;

  @override
  Future<List<Collection>> getAll() async {
    final models = await _db.collectionModels.where().sortByCreatedAtDesc().findAll();
    return models.where((m) => !m.isShared).map((m) => m.toDomain()).toList();
  }

  @override
  Future<Collection?> getById(String id) async {
    final model = await _db.collectionModels.where().idEqualTo(id).findFirst();
    return model?.toDomain();
  }

  @override
  Future<void> save(Collection collection) async {
    final model = CollectionModel.fromDomain(collection);
    await _db.writeTxn(() async {
      final existing = await _db.collectionModels.where().idEqualTo(collection.id).findFirst();
      if (existing != null) model.isarId = existing.isarId;
      await _db.collectionModels.put(model);
    });
  }

  @override
  Future<void> delete(String id) async {
    await _db.writeTxn(() async {
      final model = await _db.collectionModels.where().idEqualTo(id).findFirst();
      if (model != null) await _db.collectionModels.delete(model.isarId);
    });
  }

  @override
  Stream<List<Collection>> watchAll() {
    return _db.collectionModels
        .where()
        .watch(fireImmediately: true)
        .map((models) => models.where((m) => !m.isShared).map((m) => m.toDomain()).toList());
  }
}
