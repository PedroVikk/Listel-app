import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/collection.dart';
import '../../domain/repositories/collections_repository.dart';
import '../models/shared_collection_dto.dart';

/// Repositório de coleções compartilhadas via Supabase Realtime.
/// Implementa a mesma interface do repositório local — providers roteiam
/// para cá quando collection.isShared == true.
class RemoteCollectionsRepositoryImpl implements CollectionsRepository {
  final SupabaseClient _client;

  RemoteCollectionsRepositoryImpl(this._client);

  @override
  Future<List<Collection>> getAll() async {
    final rows = await _client
        .from('shared_collections')
        .select()
        .order('created_at');
    return (rows as List).map((r) => SharedCollectionDto.fromJson(r)).toList();
  }

  @override
  Future<Collection?> getById(String id) async {
    final row = await _client
        .from('shared_collections')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : SharedCollectionDto.fromJson(row);
  }

  @override
  Future<void> save(Collection collection) async {
    if (collection.remoteId == null) return;
    await _client
        .from('shared_collections')
        .update(SharedCollectionDto.toJson(collection))
        .eq('id', collection.remoteId!);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('shared_collections').delete().eq('id', id);
  }

  @override
  Stream<List<Collection>> watchAll() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    // Stream inicial + Postgres Changes para INSERT/UPDATE/DELETE
    return _client
        .from('shared_collections')
        .stream(primaryKey: ['id'])
        .map((rows) => rows.map(SharedCollectionDto.fromJson).toList());
  }
}
