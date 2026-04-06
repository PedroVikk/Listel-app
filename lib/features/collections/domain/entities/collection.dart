class Collection {
  final String id;
  final String name;
  final String? emoji;
  final int colorValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Campos de lista compartilhada (Fase 2+)
  /// true = lista remota no Supabase; false = local no Isar (padrão).
  final bool isShared;

  /// UUID Supabase para listas compartilhadas; null para locais.
  final String? remoteId;

  /// Código de convite de 8 chars; null para locais.
  final String? inviteCode;

  const Collection({
    required this.id,
    required this.name,
    this.emoji,
    required this.colorValue,
    required this.createdAt,
    required this.updatedAt,
    this.isShared = false,
    this.remoteId,
    this.inviteCode,
  });

  Collection copyWith({
    String? id,
    String? name,
    String? emoji,
    int? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isShared,
    String? remoteId,
    String? inviteCode,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isShared: isShared ?? this.isShared,
      remoteId: remoteId ?? this.remoteId,
      inviteCode: inviteCode ?? this.inviteCode,
    );
  }
}
