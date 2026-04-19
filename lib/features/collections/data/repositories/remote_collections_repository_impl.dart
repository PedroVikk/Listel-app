import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/collection.dart';
import '../../domain/repositories/collections_repository.dart';
import '../datasources/remote_collections_datasource.dart';

/// Repositório remoto para coleções compartilhadas via Supabase.
/// Gerencia coleções públicas/privadas e sincronização.
class RemoteCollectionsRepositoryImpl implements CollectionsRepository {
  late final RemoteCollectionsDataSource _remoteDataSource;

  RemoteCollectionsRepositoryImpl(SupabaseClient client) {
    _remoteDataSource = RemoteCollectionsDataSource(client);
  }

  @override
  Future<List<Collection>> getAll() async {
    return _remoteDataSource.getAllByUser();
  }

  @override
  Future<Collection?> getById(String id) async {
    return _remoteDataSource.getById(id);
  }

  @override
  Future<void> save(Collection collection) async {
    await _remoteDataSource.upsert(collection);
  }

  @override
  Future<void> delete(String id) async {
    // Espera remoteId, não local id
    return _remoteDataSource.delete(id);
  }

  @override
  Stream<List<Collection>> watchAll() {
    return _remoteDataSource.watchUserCollections();
  }

  /// Retorna coleções públicas de um usuário específico.
  /// Usado para carregar perfil do usuário.
  Stream<List<Collection>> watchPublicCollections(String userId) {
    return _remoteDataSource.watchPublicCollections(userId);
  }

  /// Busca coleções públicas de um usuário com paginação.
  Future<List<Collection>> getPublicCollections({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    return _remoteDataSource.getPublicCollections(
      userId: userId,
      limit: limit,
      offset: offset,
    );
  }

  /// Atualiza apenas a visibilidade (is_public) de uma coleção.
  Future<void> updateVisibility(String remoteId, bool isPublic) async {
    return _remoteDataSource.updateVisibility(remoteId, isPublic);
  }
}
