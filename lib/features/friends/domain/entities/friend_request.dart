import 'package:wish_nesita/features/friends/domain/entities/friend.dart';

enum FriendRequestStatus { pending, accepted, rejected }

class FriendRequest {
  final String id;
  final Friend friend;
  final FriendRequestStatus status;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.friend,
    required this.status,
    required this.createdAt,
  });

  FriendRequest copyWith({
    String? id,
    Friend? friend,
    FriendRequestStatus? status,
    DateTime? createdAt,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      friend: friend ?? this.friend,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
