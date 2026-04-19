import 'package:isar/isar.dart' hide Collection;
import '../../domain/entities/collection.dart';
import '../../domain/repositories/collections_repository.dart';
import '../datasources/local_collections_datasource.dart';
import '../../../../core/services/sync_orchestrator.dart';

/// Repositório local para coleções com suporte a sincronização Supabase.
/// Coordena operações locais com SyncOrchestrator para fila de sync offline.
class CollectionsRepositoryImpl implements CollectionsRepository {
  late final LocalCollectionsDataSource _localDataSource;
  final Isar? _db;
  final SyncOrchestrator? _syncOrchestrator;

  CollectionsRepositoryImpl({Isar? db, SyncOrchestrator? syncOrchestrator})
      : _db = db,
        _syncOrchestrator = syncOrchestrator {
    _localDataSource = LocalCollectionsDataSource(
      db: _db,
      syncOrchestrator: _syncOrchestrator,
    );
  }

  @override
  Future<List<Collection>> getAll() async {
    return _localDataSource.getAll();
  }

  @override
  Future<Collection?> getById(String id) async {
    return _localDataSource.getById(id);
  }

  @override
  Future<void> save(Collection collection) async {
    return _localDataSource.save(collection);
  }

  @override
  Future<void> delete(String id) async {
    return _localDataSource.delete(id);
  }

  @override
  Stream<List<Collection>> watchAll() {
    return _localDataSource.watchAll();
  }

  /// Retorna coleções que ainda não foram sincronizadas.
  /// Útil para diagnóstico e monitoramento de sync.
  Future<List<Collection>> getUnsyncedCollections() async {
    return _localDataSource.getUnsyncedCollections();
  }

  /// Marca coleção como sincronizada com sucesso.
  /// Chamado após sync bem-sucedido do SyncService.
  Future<void> markCollectionSynced(String id) async {
    return _localDataSource.markSynced(id);
  }
}
