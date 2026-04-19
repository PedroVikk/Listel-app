import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wish_nesita/features/friends/data/models/friend_dto.dart';
import 'package:wish_nesita/features/friends/data/models/friend_request_dto.dart';
import 'package:wish_nesita/features/friends/domain/entities/friend.dart';
import 'package:wish_nesita/features/friends/domain/entities/friend_request.dart';
import 'package:wish_nesita/features/friends/domain/entities/suggestion.dart';
import 'package:wish_nesita/features/friends/domain/repositories/friends_repository.dart';

class SupabaseFriendsRepositoryImpl implements FriendsRepository {
  final SupabaseClient _client;

  SupabaseFriendsRepositoryImpl(this._client);

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('Usuário não autenticado');
    return id;
  }

  @override
  Future<List<FriendRequest>> getPendingRequests() async {
    try {
      final response = await _client
          .from('friend_requests')
          .select('''
            id,
            status,
            created_at,
            from_user_id,
            profiles!from_user_id(id, display_name, avatar_url, username)
          ''')
          .eq('to_user_id', _userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) {
            final profileData = data['profiles'] as Map<String, dynamic>;
            final friend = FriendDto.fromProfileJson(profileData);
            return FriendRequestDto.fromJson(
              data as Map<String, dynamic>,
              fromFriend: friend,
            );
          })
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar convites pendentes: $e');
    }
  }

  @override
  Future<List<Suggestion>> getSuggestions({int limit = 6, int offset = 0}) async {
    try {
      // Busca usuários que NÃO são amigos ainda
      final response = await _client.rpc('get_friend_suggestions', params: {
        'user_id': _userId,
        'limit_count': limit,
        'offset_count': offset,
      });

      if (response == null || response is! List) {
        return [];
      }

      return (response)
          .map((data) {
            final friend = FriendDto.fromProfileJson(
              data['profile'] as Map<String, dynamic>,
            );
            return Suggestion(
              friend: friend,
              mutualFriendsCount: data['mutual_friends_count'] as int? ?? 0,
              isInContacts: data['is_in_contacts'] as bool? ?? false,
            );
          })
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar sugestões: $e');
    }
  }

  @override
  Future<List<Friend>> searchFriends(String query) async {
    try {
      if (query.isEmpty) return [];

      final response = await _client
          .from('profiles')
          .select('id, display_name, avatar_url, username')
          .or('display_name.ilike.%$query%, username.ilike.%$query%')
          .neq('id', _userId)
          .limit(10);

      return (response as List)
          .map((data) => FriendDto.fromProfileJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar amigos: $e');
    }
  }

  @override
  Future<void> acceptRequest(String requestId) async {
    try {
      await _client
          .from('friend_requests')
          .update({'status': 'accepted'})
          .eq('id', requestId)
          .eq('to_user_id', _userId);

      // Fetch request details para registrar amizade
      final requestData = await _client
          .from('friend_requests')
          .select('from_user_id')
          .eq('id', requestId)
          .single();

      final fromUserId = requestData['from_user_id'] as String;

      // Criar registro bidirecional de amizade
      await _client.from('friends').insert({
        'user_id': _userId,
        'friend_id': fromUserId,
      });

      await _client.from('friends').insert({
        'user_id': fromUserId,
        'friend_id': _userId,
      });
    } catch (e) {
      throw Exception('Erro ao aceitar convite: $e');
    }
  }

  @override
  Future<void> rejectRequest(String requestId) async {
    try {
      await _client
          .from('friend_requests')
          .update({'status': 'rejected'})
          .eq('id', requestId)
          .eq('to_user_id', _userId);
    } catch (e) {
      throw Exception('Erro ao rejeitar convite: $e');
    }
  }

  @override
  Future<void> sendFriendRequest(String toUserId) async {
    try {
      // Verificar se já não existe request
      final existing = await _client
          .from('friend_requests')
          .select()
          .eq('from_user_id', _userId)
          .eq('to_user_id', toUserId)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Solicitação já enviada para este usuário');
      }

      await _client.from('friend_requests').insert({
        'from_user_id': _userId,
        'to_user_id': toUserId,
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Erro ao enviar solicitação: $e');
    }
  }

  @override
  Future<List<Friend>> getFriendsList() async {
    try {
      final response = await _client.from('friends').select('''
        friend_id,
        friend:friend_id(id, display_name, avatar_url, username, created_at)
      ''').eq('user_id', _userId);

      return (response as List)
          .map((data) {
            final friendData = data['friend'] as Map<String, dynamic>;
            return FriendDto.fromProfileJson(friendData);
          })
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar lista de amigos: $e');
    }
  }

  @override
  Future<void> removeFriend(String friendId) async {
    try {
      // Remove ambos os lados da amizade
      await Future.wait([
        _client
            .from('friends')
            .delete()
            .eq('user_id', _userId)
            .eq('friend_id', friendId),
        _client
            .from('friends')
            .delete()
            .eq('user_id', friendId)
            .eq('friend_id', _userId),
      ]);
    } catch (e) {
      throw Exception('Erro ao remover amigo: $e');
    }
  }
}
