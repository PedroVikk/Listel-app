import '../../domain/entities/collection.dart';

/// Mapeia JSON do Supabase ↔ entidade Collection (isShared=true).
class SharedCollectionDto {
  static Collection fromJson(Map<String, dynamic> json) => Collection(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String?,
        colorValue: (json['color_value'] as num).toInt(),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        isShared: true,
        remoteId: json['id'] as String,
        inviteCode: json['invite_code'] as String?,
      );

  static Map<String, dynamic> toJson(Collection entity) => {
        'name': entity.name,
        'emoji': entity.emoji,
        'color_value': entity.colorValue,
        'updated_at': entity.updatedAt.toIso8601String(),
      };

  static Map<String, dynamic> toInsertJson({
    required Collection entity,
    required String ownerId,
    required String inviteCode,
  }) =>
      {
        'name': entity.name,
        'emoji': entity.emoji,
        'color_value': entity.colorValue,
        'owner_id': ownerId,
        'invite_code': inviteCode,
        'created_at': entity.createdAt.toIso8601String(),
        'updated_at': entity.updatedAt.toIso8601String(),
      };
}
