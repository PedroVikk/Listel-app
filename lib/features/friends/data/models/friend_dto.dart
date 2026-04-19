import 'package:wish_nesita/features/friends/domain/entities/friend.dart';

class FriendDto {
  static Friend fromJson(Map<String, dynamic> json) => Friend(
        id: json['id'] as String,
        displayName: json['display_name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        username: json['username'] as String?,
        addedAt: DateTime.parse(json['created_at'] as String),
      );

  static Friend fromProfileJson(Map<String, dynamic> json) => Friend(
        id: json['id'] as String,
        displayName: json['display_name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        username: json['username'] as String?,
        addedAt: DateTime.now(),
      );

  static Map<String, dynamic> toJson(Friend entity) => {
        'id': entity.id,
        'display_name': entity.displayName,
        'avatar_url': entity.avatarUrl,
        'username': entity.username,
        'created_at': entity.addedAt.toIso8601String(),
      };
}
