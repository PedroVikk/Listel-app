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

  // Migração automática: int não-nullable com default 0 → Isar usa 0 para registros antigos
  int sortOrder = 0;

  // Campos de lista compartilhada — nullable → migração automática pelo Isar
  String? addedBy;
  String? purchasedBy;

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
        sortOrder: sortOrder,
        createdAt: createdAt,
        updatedAt: updatedAt,
        addedBy: addedBy,
        purchasedBy: purchasedBy,
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
    ..sortOrder = entity.sortOrder
    ..createdAt = entity.createdAt
    ..updatedAt = entity.updatedAt
    ..addedBy = entity.addedBy
    ..purchasedBy = entity.purchasedBy;
}
