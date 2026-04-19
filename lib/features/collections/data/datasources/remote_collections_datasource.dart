import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/collection.dart';
import '../models/shared_collection_dto.dart';

/// Data source remoto para operações em Supabase.
/// Gerencia coleções compartilhadas e públicas.
class RemoteCollectionsDataSource {
  final SupabaseClient _client;

  RemoteCollectionsDataSource(this._client);

  /// Retorna todas as coleções do usuário (próprias + compartilhadas).
  /// Filtra por owner_id = current user.
  Future<List<Collection>> getAllByUser() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from('shared_collections')
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: false);

    return (rows as List).map((r) => SharedCollectionDto.fromJson(r)).toList();
  }

  /// Retorna coleções públicas (is_public = true).
  /// Usado para listar públicas no perfil do usuário.
  Future<List<Collection>> getPublicCollections({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = await _client
        .from('shared_collections')
        .select()
        .eq('owner_id', userId)
        .eq('is_public', true)
        .order('updated_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (rows as List).map((r) => SharedCollectionDto.fromJson(r)).toList();
  }

  /// Retorna coleção por ID se o usuário tem acesso.
  Future<Collection?> getById(String id) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await _client
        .from('shared_collections')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (row == null) return null;

    final collection = SharedCollectionDto.fromJson(row);
    // RLS policy garante que user só vê sua própria ou pública
    return collection;
  }

  /// Cria ou atualiza coleção em Supabase.
  /// Se a coleção não tem remoteId, cria nova; senão atualiza.
  Future<Collection> upsert(Collection collection) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final data = {
      'name': collection.name,
      'emoji': collection.emoji,
      'color_value': collection.colorValue,
      'is_public': collection.isPublic,
      'updated_at': DateTime.now().toIso8601String(),
    };

    late final Map<String, dynamic> result;

    if (collection.remoteId != null) {
      // Update existing
      result = await _client
          .from('shared_collections')
          .update(data)
          .eq('id', collection.remoteId!)
          .select()
          .single();
    } else {
      // Create new
      result = await _client
          .from('shared_collections')
          .insert({
            ...data,
            'owner_id': userId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
    }

    return SharedCollectionDto.fromJson(result);
  }

  /// Deleta coleção em Supabase.
  Future<void> delete(String remoteId) async {
    await _client
        .from('shared_collections')
        .delete()
        .eq('id', remoteId);
  }

  /// Streams coleções do usuário com Realtime.
  /// Emite atualizações em tempo real.
  Stream<List<Collection>> watchUserCollections() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _client
        .from('shared_collections')
        .stream(primaryKey: ['id'])
        .eq('owner_id', userId)
        .order('updated_at', ascending: false)
        .map((rows) => rows.map(SharedCollectionDto.fromJson).toList());
  }

  /// Streams coleções públicas de um usuário específico.
  /// Usado para carregar perfil do usuário.
  Stream<List<Collection>> watchPublicCollections(String userId) {
    return _client
        .from('shared_collections')
        .stream(primaryKey: ['id'])
        .map((rows) {
          return rows
              .where((row) =>
                  row['owner_id'] == userId && row['is_public'] == true)
              .map(SharedCollectionDto.fromJson)
              .toList();
        });
  }

  /// Atualiza apenas a visibilidade (is_public) de uma coleção.
  Future<void> updateVisibility(String remoteId, bool isPublic) async {
    await _client
        .from('shared_collections')
        .update({
          'is_public': isPublic,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', remoteId);
  }
}
