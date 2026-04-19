import 'package:wish_nesita/features/friends/domain/entities/friend.dart';
import 'package:wish_nesita/features/friends/domain/entities/friend_request.dart';
import 'friend_dto.dart';

class FriendRequestDto {
  static FriendRequest fromJson(
    Map<String, dynamic> json, {
    required Friend fromFriend,
  }) {
    final statusStr = json['status'] as String;
    final status = FriendRequestStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => FriendRequestStatus.pending,
    );

    return FriendRequest(
      id: json['id'] as String,
      friend: fromFriend,
      status: status,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static FriendRequest fromJsonWithProfile(
    Map<String, dynamic> json, {
    required Map<String, dynamic> profileJson,
  }) {
    final friend = FriendDto.fromProfileJson(profileJson);
    return fromJson(json, fromFriend: friend);
  }

  static Map<String, dynamic> toJson(FriendRequest entity) => {
        'id': entity.id,
        'status': entity.status.name,
        'created_at': entity.createdAt.toIso8601String(),
      };

  static Map<String, dynamic> toInsertJson({
    required String fromUserId,
    required String toUserId,
  }) =>
      {
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'status': 'pending',
      };

  static Map<String, dynamic> toUpdateJson(FriendRequestStatus status) => {
        'status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      };
}
