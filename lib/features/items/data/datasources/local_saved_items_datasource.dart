import 'dart:convert';
import 'package:isar/isar.dart';
import '../../domain/entities/saved_item.dart';
import '../models/saved_item_model.dart';
import '../../../../core/services/isar_service.dart';
import '../../../../core/services/sync_orchestrator.dart';

/// Data source local para operações de itens salvos com suporte a sincronização.
/// Coordena com SyncOrchestrator para enfileirar operações offline.
class LocalSavedItemsDataSource {
  final Isar _db;
  final SyncOrchestrator _syncOrchestrator;

  LocalSavedItemsDataSource({
    Isar? db,
    SyncOrchestrator? syncOrchestrator,
  })  : _db = db ?? IsarService.db,
        _syncOrchestrator = syncOrchestrator ?? SyncOrchestrator();

  /// Retorna todos os itens de uma coleção, ordenados por sortOrder.
  Future<List<SavedItem>> getByCollection(String collectionId) async {
    final models = await _db.savedItemModels
        .where()
        .collectionIdEqualTo(collectionId)
        .findAll();
    models.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return models.map((m) => m.toDomain()).toList();
  }

  /// Retorna item por ID.
  Future<SavedItem?> getById(String id) async {
    final model = await _db.savedItemModels
        .where()
        .idEqualTo(id)
        .findFirst();
    return model?.toDomain();
  }

  /// Salva item localmente e enfileira para sincronização se remoteId existir.
  Future<void> save(SavedItem item) async {
    final model = SavedItemModel.fromDomain(item);
    model.needsSync = true;
    model.syncedAt = DateTime.now().millisecondsSinceEpoch;

    await _db.writeTxn(() async {
      final existing = await _db.savedItemModels
          .where()
          .idEqualTo(item.id)
          .findFirst();
      if (existing != null) {
        model.isarId = existing.isarId;
        model.remoteId = existing.remoteId; // Preserva remoteId se existir
      }
      await _db.savedItemModels.put(model);
    });

    // Busca novamente para verificar remoteId
    final savedModel = await _db.savedItemModels
        .where()
        .idEqualTo(item.id)
        .findFirst();

    // Se tem remoteId, enfileira sincronização
    if (savedModel?.remoteId != null) {
      await _syncOrchestrator.enqueueOperation(
        operationType: 'update',
        entityType: 'item',
        entityId: savedModel!.remoteId!,
        payload: {
          'name': item.name,
          'price': item.price,
          'url': item.url,
          'store': item.store,
          'notes': item.notes,
          'status': item.status.name,
          'source': item.source.name,
          'sort_order': item.sortOrder,
          'updated_at': DateTime.now().toIso8601String(),
        },
        localSnapshot: jsonEncode({
          'id': item.id,
          'name': item.name,
          'price': item.price,
          'status': item.status.name,
        }),
      );
    }
  }

  /// Deleta item localmente e enfileira exclusão remota se aplicável.
  Future<void> delete(String id) async {
    final model = await _db.savedItemModels
        .where()
        .idEqualTo(id)
        .findFirst();

    if (model != null) {
      final remoteId = model.remoteId;

      await _db.writeTxn(() async {
        await _db.savedItemModels.delete(model.isarId);
      });

      // Se tem remoteId, enfileira deleção
      if (remoteId != null) {
        await _syncOrchestrator.enqueueOperation(
          operationType: 'delete',
          entityType: 'item',
          entityId: remoteId,
          payload: {'id': remoteId},
        );
      }
    }
  }

  /// Streams todos os itens de uma coleção com mudanças em tempo real.
  Stream<List<SavedItem>> watchByCollection(String collectionId) {
    return _db.savedItemModels
        .where()
        .collectionIdEqualTo(collectionId)
        .watch(fireImmediately: true)
        .map((models) {
          models.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          return models.map((m) => m.toDomain()).toList();
        });
  }

  /// Marca item como sincronizado com sucesso.
  Future<void> markSynced(String id) async {
    final model = await _db.savedItemModels
        .where()
        .idEqualTo(id)
        .findFirst();

    if (model != null) {
      model.needsSync = false;
      model.syncedAt = DateTime.now().millisecondsSinceEpoch;

      await _db.writeTxn(() async {
        await _db.savedItemModels.put(model);
      });
    }
  }

  /// Retorna todos os itens que precisam sincronizar.
  Future<List<SavedItem>> getUnsyncedItems() async {
    final models = await _db.savedItemModels.where().findAll();
    return models
        .where((m) => m.needsSync)
        .map((m) => m.toDomain())
        .toList();
  }

  /// Reordena itens e marca como precisando sincronizar.
  Future<void> reorder(List<SavedItem> items) async {
    await _db.writeTxn(() async {
      for (int i = 0; i < items.length; i++) {
        final model = await _db.savedItemModels
            .where()
            .idEqualTo(items[i].id)
            .findFirst();

        if (model != null) {
          model.sortOrder = i;
          model.needsSync = true;
          model.syncedAt = DateTime.now().millisecondsSinceEpoch;
          await _db.savedItemModels.put(model);

          // Enfileira atualização de ordem se remoteId existir
          if (model.remoteId != null) {
            await _syncOrchestrator.enqueueOperation(
              operationType: 'update',
              entityType: 'item',
              entityId: model.remoteId!,
              payload: {
                'sort_order': i,
                'updated_at': DateTime.now().toIso8601String(),
              },
            );
          }
        }
      }
    });
  }
}
