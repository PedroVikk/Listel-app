import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/sharing_repository.dart';
import '../../../collections/domain/entities/collection.dart';
import '../../../collections/data/models/shared_collection_dto.dart';
import '../../../auth/domain/entities/collection_member.dart';

class SupabaseSharingRepositoryImpl implements SharingRepository {
  final SupabaseClient _client;

  SupabaseSharingRepositoryImpl(this._client);

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('Usuário não autenticado');
    return id;
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  @override
  Future<Collection> createSharedCollection({
    required String name,
    String? emoji,
    required int colorValue,
  }) async {
    final ownerId = _userId;
    final now = DateTime.now();
    String? remoteId;

    // Tenta gerar invite_code único (retry em colisão)
    for (int attempt = 0; attempt < 5; attempt++) {
      final code = _generateInviteCode();
      try {
        final draft = Collection(
          id: '',
          name: name,
          emoji: emoji,
          colorValue: colorValue,
          createdAt: now,
          updatedAt: now,
        );
        final row = await _client
            .from('shared_collections')
            .insert(SharedCollectionDto.toInsertJson(
              entity: draft,
              ownerId: ownerId,
              inviteCode: code,
            ))
            .select()
            .single();

        remoteId = row['id'] as String;

        // Adiciona o criador como owner em collection_members
        await _client.from('collection_members').insert({
          'collection_id': remoteId,
          'user_id': ownerId,
          'role': 'owner',
        });

        return SharedCollectionDto.fromJson(row);
      } on PostgrestException catch (e) {
        if (e.code == '23505') continue; // colisão no invite_code → retry
        rethrow;
      }
    }
    throw Exception('Não foi possível gerar código de convite único');
  }

  @override
  Future<Collection> joinByInviteCode(String inviteCode) async {
    final userId = _userId;

    final row = await _client
        .from('shared_collections')
        .select()
        .eq('invite_code', inviteCode.toUpperCase())
        .maybeSingle();

    if (row == null) {
      throw Exception('Código de convite inválido ou expirado');
    }

    final collectionId = row['id'] as String;

    // Upsert — idempotente se já for membro
    await _client.from('collection_members').upsert({
      'collection_id': collectionId,
      'user_id': userId,
      'role': 'member',
    });

    return SharedCollectionDto.fromJson(row);
  }

  @override
  Future<List<CollectionMember>> getMembers(String collectionRemoteId) async {
    final rows = await _client
        .from('collection_members')
        .select('user_id, role, profiles(display_name)')
        .eq('collection_id', collectionRemoteId);

    return (rows as List).map((r) {
      final profile = r['profiles'] as Map<String, dynamic>?;
      return CollectionMember(
        userId: r['user_id'] as String,
        collectionId: collectionRemoteId,
        role: r['role'] == 'owner' ? MemberRole.owner : MemberRole.member,
        displayName: profile?['display_name'] as String? ?? 'Usuário',
      );
    }).toList();
  }

  @override
  Future<void> leaveCollection(String collectionRemoteId) async {
    final userId = _userId;

    // Se for dono, deleta a coleção inteira (CASCADE remove membros e itens)
    final memberRow = await _client
        .from('collection_members')
        .select('role')
        .eq('collection_id', collectionRemoteId)
        .eq('user_id', userId)
        .maybeSingle();

    if (memberRow?['role'] == 'owner') {
      await _client
          .from('shared_collections')
          .delete()
          .eq('id', collectionRemoteId);
    } else {
      await _client
          .from('collection_members')
          .delete()
          .eq('collection_id', collectionRemoteId)
          .eq('user_id', userId);
    }
  }
}
