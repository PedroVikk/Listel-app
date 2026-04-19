import 'package:wish_nesita/features/friends/domain/entities/friend.dart';
import 'package:wish_nesita/features/friends/domain/entities/friend_request.dart';
import 'package:wish_nesita/features/friends/domain/entities/suggestion.dart';

abstract class FriendsRepository {
  Future<List<FriendRequest>> getPendingRequests();
  Future<List<Suggestion>> getSuggestions({int limit = 6, int offset = 0});
  Future<List<Friend>> searchFriends(String query);
  Future<void> acceptRequest(String requestId);
  Future<void> rejectRequest(String requestId);
  Future<void> sendFriendRequest(String toUserId);
  Future<List<Friend>> getFriendsList();
  Future<void> removeFriend(String friendId);
}
