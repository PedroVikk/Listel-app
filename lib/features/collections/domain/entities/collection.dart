class Collection {
  final String id;
  final String name;
  final String? emoji;
  final int colorValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Collection({
    required this.id,
    required this.name,
    this.emoji,
    required this.colorValue,
    required this.createdAt,
    required this.updatedAt,
  });

  Collection copyWith({
    String? id,
    String? name,
    String? emoji,
    int? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
