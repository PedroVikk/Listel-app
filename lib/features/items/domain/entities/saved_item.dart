enum ItemStatus { pending, purchased }

enum ItemSource { shared, manual }

class SavedItem {
  final String id;
  final String collectionId;
  final String? url;
  final String name;
  final String? imageUrl;
  final String? localImagePath;
  final double? price;
  final String? store;
  final String? notes;
  final ItemStatus status;
  final ItemSource source;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavedItem({
    required this.id,
    required this.collectionId,
    this.url,
    required this.name,
    this.imageUrl,
    this.localImagePath,
    this.price,
    this.store,
    this.notes,
    required this.status,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPurchased => status == ItemStatus.purchased;

  SavedItem copyWith({
    String? id,
    String? collectionId,
    String? url,
    String? name,
    String? imageUrl,
    String? localImagePath,
    double? price,
    String? store,
    String? notes,
    ItemStatus? status,
    ItemSource? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedItem(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      url: url ?? this.url,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      price: price ?? this.price,
      store: store ?? this.store,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
