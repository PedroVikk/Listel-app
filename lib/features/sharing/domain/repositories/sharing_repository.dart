import '../../../collections/domain/entities/collection.dart';
import '../../../auth/domain/entities/collection_member.dart';

abstract class SharingRepository {
  /// Cria uma nova coleção compartilhada no Supabase e retorna-a com remoteId e inviteCode preenchidos.
  Future<Collection> createSharedCollection({
    required String name,
    String? emoji,
    required int colorValue,
  });

  /// Entra em uma coleção pelo código de convite. Retorna a coleção acessada.
  Future<Collection> joinByInviteCode(String inviteCode);

  /// Lista os membros de uma coleção compartilhada.
  Future<List<CollectionMember>> getMembers(String collectionRemoteId);

  /// Remove o usuário atual de uma coleção (ou deleta se for dono).
  Future<void> leaveCollection(String collectionRemoteId);
}
