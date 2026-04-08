// Sentinel para distinguir "não passou" de "passou null" em copyWith.
const _kAbsent = Object();

class Collection {
  final String id;
  final String name;
  final String? emoji;
  final int colorValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Caminho local da foto de capa (arquivo no diretório de documentos do app).
  final String? coverImagePath;

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
    this.coverImagePath,
    this.isShared = false,
    this.remoteId,
    this.inviteCode,
  });

  Collection copyWith({
    String? id,
    String? name,
    Object? emoji = _kAbsent,
    int? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? coverImagePath = _kAbsent,
    bool? isShared,
    String? remoteId,
    String? inviteCode,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji == _kAbsent ? this.emoji : emoji as String?,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coverImagePath: coverImagePath == _kAbsent
          ? this.coverImagePath
          : coverImagePath as String?,
      isShared: isShared ?? this.isShared,
      remoteId: remoteId ?? this.remoteId,
      inviteCode: inviteCode ?? this.inviteCode,
    );
  }
}
