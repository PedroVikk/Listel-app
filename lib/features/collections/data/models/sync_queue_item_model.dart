import 'package:isar/isar.dart';

part 'sync_queue_item_model.g.dart';

@collection
class SyncQueueItemModel {
  Id? isarId;

  /// UUID único para idempotência (evita duplicatas em retry)
  @Index(unique: true)
  late String operationId;

  /// Tipo de operação: 'create', 'update', 'delete'
  late String operationType;

  /// Entidade afetada: 'collection', 'item'
  late String entityType;

  /// ID remoto (Supabase) da entidade
  late String entityId;

  /// Payload JSON serializado com dados a sincronizar
  /// Ex: "{\"name\":\"Tech Setup\",\"is_public\":true}"
  late String payloadJson;

  /// Timestamp de quando foi enfileirado (ms desde epoch)
  late int createdAt;

  /// Número de tentativas de sincronização
  int retryCount = 0;

  /// Mensagem de erro da última tentativa (se houver)
  String? lastError;

  /// Flag: tem conflito detectado?
  bool hasConflict = false;

  /// Resolução do conflito: 'keep_local', 'use_remote', 'merge'
  String? conflictResolution;

  /// JSON serializado do estado local no momento da fila
  /// Usado para comparação em caso de conflito
  String? localSnapshot;
}
