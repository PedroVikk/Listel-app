import 'dart:async';
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
    // Usa RPC com SECURITY DEFINER para contornar o RLS:
    // um novo usuário ainda não é membro, então SELECT direto em
    // shared_collections seria bloqueado pela policy de SELECT.
    // A função no Supabase faz o SELECT e o INSERT internamente.
    final dynamic result = await _client.rpc(
      'join_shared_collection',
      params: {'p_invite_code': inviteCode.toUpperCase()},
    );

    if (result == null) {
      throw Exception('Código de convite inválido ou expirado');
    }

    final row = result is List ? result.first as Map<String, dynamic> : result as Map<String, dynamic>;
    return SharedCollectionDto.fromJson(row);
  }

  @override
  Future<List<CollectionMember>> getMembers(String collectionRemoteId) async {
    final memberRows = await _client
        .from('collection_members')
        .select('user_id, role')
        .eq('collection_id', collectionRemoteId);

    final members = memberRows as List;
    if (members.isEmpty) return [];

    final userIds = members.map((r) => r['user_id'] as String).toList();

    final profileRows = await _client
        .from('profiles')
        .select('id, display_name')
        .inFilter('id', userIds);

    final profileMap = <String, String>{
      for (final p in profileRows as List)
        p['id'] as String: (p['display_name'] as String?) ?? 'Usuário',
    };

    return members.map((r) {
      final userId = r['user_id'] as String;
      return CollectionMember(
        userId: userId,
        collectionId: collectionRemoteId,
        role: r['role'] == 'owner' ? MemberRole.owner : MemberRole.member,
        displayName: profileMap[userId] ?? 'Usuário',
      );
    }).toList();
  }

  @override
  Stream<List<CollectionMember>> watchMembers(String collectionRemoteId) {
    // Mesmo padrão de retry de watchByCollection em remote_items_repository_impl:
    // reconecta automaticamente após RealtimeSubscribeException (JWT expirado).
    late StreamController<List<CollectionMember>> controller;
    StreamSubscription? sub;

    Stream<List<CollectionMember>> buildStream() => _client
        .from('collection_members')
        .stream(primaryKey: ['collection_id', 'user_id'])
        .eq('collection_id', collectionRemoteId)
        .asyncMap((memberRows) async {
          if (memberRows.isEmpty) return <CollectionMember>[];

          final userIds =
              memberRows.map((r) => r['user_id'] as String).toList();

          final profileRows = await _client
              .from('profiles')
              .select('id, display_name')
              .inFilter('id', userIds);

          final profileMap = <String, String>{
            for (final p in profileRows as List)
              p['id'] as String: (p['display_name'] as String?) ?? 'Usuário',
          };

          return memberRows.map((r) {
            final userId = r['user_id'] as String;
            return CollectionMember(
              userId: userId,
              collectionId: collectionRemoteId,
              role:
                  r['role'] == 'owner' ? MemberRole.owner : MemberRole.member,
              displayName: profileMap[userId] ?? 'Usuário',
            );
          }).toList();
        });

    void subscribe() {
      sub?.cancel();
      sub = buildStream().listen(
        (data) => controller.add(data),
        onError: (Object e) async {
          if (e is RealtimeSubscribeException) {
            await Future<void>.delayed(const Duration(seconds: 5));
            try {
              await _client.auth.refreshSession();
            } catch (_) {}
            subscribe();
          } else {
            controller.addError(e);
          }
        },
      );
    }

    controller = StreamController<List<CollectionMember>>(
      onListen: subscribe,
      onCancel: () => sub?.cancel(),
    );

    return controller.stream;
  }

  @override
  Future<void> leaveCollection(String collectionRemoteId) async {
    final userId = _userId;

    final memberRow = await _client
        .from('collection_members')
        .select('role')
        .eq('collection_id', collectionRemoteId)
        .eq('user_id', userId)
        .maybeSingle();

    if (memberRow?['role'] == 'owner') {
      // Dono saindo → deleta a coleção inteira (CASCADE remove membros e itens)
      await _client
          .from('shared_collections')
          .delete()
          .eq('id', collectionRemoteId);
      return;
    }

    // Membro saindo → remove só sua entrada
    await _client
        .from('collection_members')
        .delete()
        .eq('collection_id', collectionRemoteId)
        .eq('user_id', userId);

    // Verifica se ainda existe algum owner na coleção.
    // Se não houver, a coleção está órfã e deve ser deletada do banco.
    final ownerRows = await _client
        .from('collection_members')
        .select('user_id')
        .eq('collection_id', collectionRemoteId)
        .eq('role', 'owner');

    if ((ownerRows as List).isEmpty) {
      await _client
          .from('shared_collections')
          .delete()
          .eq('id', collectionRemoteId);
    }
  }
}
