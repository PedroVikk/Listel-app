import 'package:isar/isar.dart' hide Collection;
import '../../domain/entities/collection.dart';

part 'collection_model.g.dart';

@collection
class CollectionModel {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String name;
  String? emoji;
  late int colorValue;
  late DateTime createdAt;
  late DateTime updatedAt;

  // Foto de capa — nullable → migração automática pelo Isar
  String? coverImagePath;

  // Campos de lista compartilhada — nullable/default → migração automática pelo Isar
  bool isShared = false;
  String? remoteId;
  String? inviteCode;

  // Campos de visibilidade pública/privada
  bool isPublic = false;

  // Campos de sincronização ISAR ↔ Supabase
  late int syncedAt; // Timestamp (ms) da última sincronização
  bool needsSync = false; // Tem mudanças não sincronizadas?

  Collection toDomain() => Collection(
        id: id,
        name: name,
        emoji: emoji,
        colorValue: colorValue,
        createdAt: createdAt,
        updatedAt: updatedAt,
        coverImagePath: coverImagePath,
        isShared: isShared,
        remoteId: remoteId,
        inviteCode: inviteCode,
        isPublic: isPublic,
      );

  static CollectionModel fromDomain(Collection entity) => CollectionModel()
    ..id = entity.id
    ..name = entity.name
    ..emoji = entity.emoji
    ..colorValue = entity.colorValue
    ..createdAt = entity.createdAt
    ..updatedAt = entity.updatedAt
    ..coverImagePath = entity.coverImagePath
    ..isShared = entity.isShared
    ..remoteId = entity.remoteId
    ..inviteCode = entity.inviteCode
    ..isPublic = entity.isPublic
    ..syncedAt = DateTime.now().millisecondsSinceEpoch
    ..needsSync = false;
}
