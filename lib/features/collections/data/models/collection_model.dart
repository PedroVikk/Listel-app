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

  // Campos de lista compartilhada — nullable/default → migração automática pelo Isar
  bool isShared = false;
  String? remoteId;
  String? inviteCode;

  Collection toDomain() => Collection(
        id: id,
        name: name,
        emoji: emoji,
        colorValue: colorValue,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isShared: isShared,
        remoteId: remoteId,
        inviteCode: inviteCode,
      );

  static CollectionModel fromDomain(Collection entity) => CollectionModel()
    ..id = entity.id
    ..name = entity.name
    ..emoji = entity.emoji
    ..colorValue = entity.colorValue
    ..createdAt = entity.createdAt
    ..updatedAt = entity.updatedAt
    ..isShared = entity.isShared
    ..remoteId = entity.remoteId
    ..inviteCode = entity.inviteCode;
}
