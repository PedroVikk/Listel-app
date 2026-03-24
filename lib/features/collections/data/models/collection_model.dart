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

  Collection toDomain() => Collection(
        id: id,
        name: name,
        emoji: emoji,
        colorValue: colorValue,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static CollectionModel fromDomain(Collection entity) => CollectionModel()
    ..id = entity.id
    ..name = entity.name
    ..emoji = entity.emoji
    ..colorValue = entity.colorValue
    ..createdAt = entity.createdAt
    ..updatedAt = entity.updatedAt;
}
