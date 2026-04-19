import 'package:wish_nesita/features/friends/domain/entities/friend.dart';

class Suggestion {
  final Friend friend;
  final int mutualFriendsCount;
  final bool isInContacts;

  const Suggestion({
    required this.friend,
    required this.mutualFriendsCount,
    required this.isInContacts,
  });

  String get label {
    if (mutualFriendsCount > 0) {
      return mutualFriendsCount == 1
          ? '1 amigo em comum'
          : '$mutualFriendsCount amigos em comum';
    }
    if (isInContacts) {
      return 'Na sua lista de contatos';
    }
    return 'Novo no Listel';
  }

  double get score => mutualFriendsCount * 10 + (isInContacts ? 5 : 0);

  Suggestion copyWith({
    Friend? friend,
    int? mutualFriendsCount,
    bool? isInContacts,
  }) {
    return Suggestion(
      friend: friend ?? this.friend,
      mutualFriendsCount: mutualFriendsCount ?? this.mutualFriendsCount,
      isInContacts: isInContacts ?? this.isInContacts,
    );
  }
}
