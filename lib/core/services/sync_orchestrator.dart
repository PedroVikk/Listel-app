import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../../features/collections/data/models/sync_queue_item_model.dart';
import 'isar_service.dart';

/// Estados possíveis de uma operação sincronizada.
enum SyncStatus {
  pending, // Aguardando sincronização
  syncing, // Em progresso
  synced, // Sincronizado com sucesso
  conflict, // Conflito detectado
  failed, // Falha após retries
}

/// Gerencia a fila de operações offline e coordena sincronização com Supabase.
/// Responsabilidades:
/// - Enfileirar operações de create/update/delete quando offline
/// - Processar fila quando online (Last-Write-Wins conflict resolution)
/// - Rastrear status e erros de sincronização
class SyncOrchestrator {
  final Isar _isar;
  static final Uuid _uuid = Uuid();

  SyncOrchestrator({Isar? isar}) : _isar = isar ?? IsarService.db;

  /// Enfileira uma operação de sincronização (create/update/delete).
  /// Retorna o operationId para rastreamento.
  Future<String> enqueueOperation({
    required String operationType, // 'create', 'update', 'delete'
    required String entityType, // 'collection', 'item'
    required String entityId,
    required Map<String, dynamic> payload,
    String? localSnapshot,
  }) async {
    final operationId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    final queueItem = SyncQueueItemModel()
      ..operationId = operationId
      ..operationType = operationType
      ..entityType = entityType
      ..entityId = entityId
      ..payloadJson = jsonEncode(payload)
      ..createdAt = now
      ..retryCount = 0
      ..hasConflict = false
      ..localSnapshot = localSnapshot;

    await _isar.writeTxn(() async {
      await _isar.syncQueueItemModels.put(queueItem);
    });

    return operationId;
  }

  /// Retorna todas as operações pendentes (não sincronizadas).
  Future<List<SyncQueueItemModel>> getPendingOperations() async {
    return await _isar.syncQueueItemModels
        .where()
        .findAll();
  }

  /// Marca uma operação como sincronizada com sucesso.
  Future<void> markAsSynced(String operationId) async {
    final existing = await _isar.syncQueueItemModels
        .where()
        .operationIdEqualTo(operationId)
        .findFirst();

    if (existing != null) {
      await _isar.writeTxn(() async {
        await _isar.syncQueueItemModels.delete(existing.isarId ?? 0);
      });
    }
  }

  /// Registra erro em uma operação e incrementa retryCount.
  /// Se retryCount >= 3, marca como failed.
  Future<void> recordError(String operationId, String error) async {
    final existing = await _isar.syncQueueItemModels
        .where()
        .operationIdEqualTo(operationId)
        .findFirst();

    if (existing != null) {
      existing.lastError = error;
      existing.retryCount += 1;

      await _isar.writeTxn(() async {
        await _isar.syncQueueItemModels.put(existing);
      });
    }
  }

  /// Marca uma operação como tendo conflito detectado.
  /// resolution: 'keep_local', 'use_remote', ou 'merge'
  Future<void> markConflict(
    String operationId,
    String conflictResolution,
    String remoteSnapshot,
  ) async {
    final existing = await _isar.syncQueueItemModels
        .where()
        .operationIdEqualTo(operationId)
        .findFirst();

    if (existing != null) {
      existing.hasConflict = true;
      existing.conflictResolution = conflictResolution;
      existing.localSnapshot = remoteSnapshot; // Sobrescreve local com remote

      await _isar.writeTxn(() async {
        await _isar.syncQueueItemModels.put(existing);
      });
    }
  }

  /// Remove todas as operações processadas (synced) da fila.
  Future<int> clearProcessed() async {
    final allItems = await _isar.syncQueueItemModels.where().findAll();
    final itemsToDelete = allItems.where((item) {
      // Remove apenas se retryCount >= 3 (falhou após retries)
      return item.retryCount >= 3;
    }).toList();

    int deleted = 0;
    if (itemsToDelete.isNotEmpty) {
      await _isar.writeTxn(() async {
        deleted = await _isar.syncQueueItemModels.deleteAll(
          itemsToDelete.map((item) => item.isarId ?? 0).toList(),
        );
      });
    }
    return deleted;
  }

  /// Retorna estatísticas da fila de sincronização.
  Future<SyncQueueStats> getStats() async {
    final allItems = await _isar.syncQueueItemModels.where().findAll();

    final pending = allItems.where((item) => item.retryCount < 3).length;
    final failed = allItems.where((item) => item.retryCount >= 3).length;
    final conflicts = allItems.where((item) => item.hasConflict).length;

    return SyncQueueStats(
      totalQueued: allItems.length,
      pending: pending,
      failed: failed,
      conflicts: conflicts,
    );
  }
}

/// Estatísticas da fila de sincronização.
class SyncQueueStats {
  final int totalQueued;
  final int pending;
  final int failed;
  final int conflicts;

  SyncQueueStats({
    required this.totalQueued,
    required this.pending,
    required this.failed,
    required this.conflicts,
  });

  bool get isEmpty => totalQueued == 0;
  bool get hasFailures => failed > 0;
  bool get hasConflicts => conflicts > 0;
}
