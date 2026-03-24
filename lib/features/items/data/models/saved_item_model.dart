import 'package:isar/isar.dart';
import '../../domain/entities/saved_item.dart';

part 'saved_item_model.g.dart';

@collection
class SavedItemModel {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  @Index()
  late String collectionId;

  String? url;
  late String name;
  String? imageUrl;
  String? localImagePath;
  double? price;
  String? store;
  String? notes;

  @Enumerated(EnumType.name)
  late ItemStatus status;

  @Enumerated(EnumType.name)
  late ItemSource source;

  late DateTime createdAt;
  late DateTime updatedAt;

  SavedItem toDomain() => SavedItem(
        id: id,
        collectionId: collectionId,
        url: url,
        name: name,
        imageUrl: imageUrl,
        localImagePath: localImagePath,
        price: price,
        store: store,
        notes: notes,
        status: status,
        source: source,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static SavedItemModel fromDomain(SavedItem entity) => SavedItemModel()
    ..id = entity.id
    ..collectionId = entity.collectionId
    ..url = entity.url
    ..name = entity.name
    ..imageUrl = entity.imageUrl
    ..localImagePath = entity.localImagePath
    ..price = entity.price
    ..store = entity.store
    ..notes = entity.notes
    ..status = entity.status
    ..source = entity.source
    ..createdAt = entity.createdAt
    ..updatedAt = entity.updatedAt;
}
