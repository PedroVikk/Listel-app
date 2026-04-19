import 'dart:convert';
import 'package:isar/isar.dart' hide Collection;
import '../../domain/entities/collection.dart';
import '../models/collection_model.dart';
import '../../../../core/services/isar_service.dart';
import '../../../../core/services/sync_orchestrator.dart';

/// Data source local para operações de coleções com suporte a sincronização.
/// Coordena com SyncOrchestrator para enfileirar operações offline.
class LocalCollectionsDataSource {
  final Isar _db;
  final SyncOrchestrator _syncOrchestrator;

  LocalCollectionsDataSource({
    Isar? db,
    SyncOrchestrator? syncOrchestrator,
  })  : _db = db ?? IsarService.db,
        _syncOrchestrator = syncOrchestrator ?? SyncOrchestrator();

  /// Retorna todas as coleções locais (não compartilhadas).
  Future<List<Collection>> getAll() async {
    final models = await _db.collectionModels
        .where()
        .sortByCreatedAtDesc()
        .findAll();
    return models.where((m) => !m.isShared).map((m) => m.toDomain()).toList();
  }

  /// Retorna coleção por ID.
  Future<Collection?> getById(String id) async {
    final model = await _db.collectionModels
        .where()
        .idEqualTo(id)
        .findFirst();
    return model?.toDomain();
  }

  /// Salva coleção localmente e enfileira para sincronização se remoteId existir.
  /// Se isPublic=true e remoteId=null, cria entrada em Supabase (via sync).
  Future<void> save(Collection collection) async {
    final model = CollectionModel.fromDomain(collection);
    model.needsSync = true;
    model.syncedAt = DateTime.now().millisecondsSinceEpoch;

    await _db.writeTxn(() async {
      final existing = await _db.collectionModels
          .where()
          .idEqualTo(collection.id)
          .findFirst();
      if (existing != null) model.isarId = existing.isarId;
      await _db.collectionModels.put(model);
    });

    // Se tem remoteId, enfileira atualização
    if (collection.remoteId != null) {
      await _syncOrchestrator.enqueueOperation(
        operationType: 'update',
        entityType: 'collection',
        entityId: collection.remoteId!,
        payload: {
          'name': collection.name,
          'emoji': collection.emoji,
          'color_value': collection.colorValue,
          'is_public': collection.isPublic,
          'updated_at': DateTime.now().toIso8601String(),
        },
        localSnapshot: jsonEncode({
          'id': collection.id,
          'name': collection.name,
          'emoji': collection.emoji,
          'color_value': collection.colorValue,
          'is_public': collection.isPublic,
        }),
      );
    }
  }

  /// Deleta coleção localmente e enfileira exclusão remota se aplicável.
  Future<void> delete(String id) async {
    final model = await _db.collectionModels
        .where()
        .idEqualTo(id)
        .findFirst();

    if (model != null) {
      await _db.writeTxn(() async {
        await _db.collectionModels.delete(model.isarId);
      });

      // Se tem remoteId, enfileira deleção
      if (model.remoteId != null) {
        await _syncOrchestrator.enqueueOperation(
          operationType: 'delete',
          entityType: 'collection',
          entityId: model.remoteId!,
          payload: {'id': model.remoteId},
        );
      }
    }
  }

  /// Streams todas as coleções locais com mudanças em tempo real.
  Stream<List<Collection>> watchAll() {
    return _db.collectionModels
        .where()
        .watch(fireImmediately: true)
        .map((models) =>
            models.where((m) => !m.isShared).map((m) => m.toDomain()).toList());
  }

  /// Marca coleção como sincronizada com sucesso.
  Future<void> markSynced(String id) async {
    final model = await _db.collectionModels
        .where()
        .idEqualTo(id)
        .findFirst();

    if (model != null) {
      model.needsSync = false;
      model.syncedAt = DateTime.now().millisecondsSinceEpoch;

      await _db.writeTxn(() async {
        await _db.collectionModels.put(model);
      });
    }
  }

  /// Retorna todas as coleções que precisam sincronizar.
  Future<List<Collection>> getUnsyncedCollections() async {
    final models = await _db.collectionModels.where().findAll();
    return models
        .where((m) => m.needsSync)
        .map((m) => m.toDomain())
        .toList();
  }
}
