import '../../domain/entities/saved_item.dart';

/// Mapeia JSON do Supabase ↔ entidade SavedItem para listas compartilhadas.
/// added_by e purchased_by chegam como UUID, mas o DTO os guarda como String?
/// para serem resolvidos para display_name no repositório quando necessário.
class SharedItemDto {
  static SavedItem fromJson(
    Map<String, dynamic> json, {
    String? addedByName,
    String? purchasedByName,
  }) =>
      SavedItem(
        id: json['id'] as String,
        collectionId: json['collection_id'] as String,
        url: json['url'] as String?,
        name: json['name'] as String,
        imageUrl: json['image_url'] as String?,
        price: (json['price'] as num?)?.toDouble(),
        store: json['store'] as String?,
        notes: json['notes'] as String?,
        status: json['status'] == 'purchased'
            ? ItemStatus.purchased
            : ItemStatus.pending,
        source: json['source'] == 'shared' ? ItemSource.shared : ItemSource.manual,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        addedBy: addedByName,
        purchasedBy: purchasedByName,
      );

  static Map<String, dynamic> toInsertJson({
    required SavedItem item,
    required String addedByUserId,
  }) =>
      {
        'id': item.id,
        'collection_id': item.collectionId,
        'url': item.url,
        'name': item.name,
        'image_url': item.imageUrl,
        'price': item.price,
        'store': item.store,
        'notes': item.notes,
        'status': item.status.name,
        'source': item.source.name,
        'added_by': addedByUserId,
        'created_at': item.createdAt.toIso8601String(),
        'updated_at': item.updatedAt.toIso8601String(),
      };

  static Map<String, dynamic> toUpdateJson({
    required SavedItem item,
    String? purchasedByUserId,
  }) =>
      {
        'name': item.name,
        'url': item.url,
        'image_url': item.imageUrl,
        'price': item.price,
        'store': item.store,
        'notes': item.notes,
        'status': item.status.name,
        'purchased_by': purchasedByUserId,
        'updated_at': item.updatedAt.toIso8601String(),
      };
}
