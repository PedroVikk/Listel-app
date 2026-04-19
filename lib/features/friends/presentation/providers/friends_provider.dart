import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wish_nesita/features/friends/data/repositories/supabase_friends_repository_impl.dart';
import 'package:wish_nesita/features/friends/domain/entities/friend.dart';
import 'package:wish_nesita/features/friends/domain/entities/friend_request.dart';
import 'package:wish_nesita/features/friends/domain/entities/suggestion.dart';
import 'package:wish_nesita/features/friends/domain/repositories/friends_repository.dart';

// Repository provider
final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return SupabaseFriendsRepositoryImpl(Supabase.instance.client);
});

// State class para friends
class FriendsState {
  final List<FriendRequest> pendingRequests;
  final List<Suggestion> suggestions;
  final int suggestionsOffset;
  final bool isLoadingMore;

  const FriendsState({
    required this.pendingRequests,
    required this.suggestions,
    this.suggestionsOffset = 0,
    this.isLoadingMore = false,
  });

  FriendsState copyWith({
    List<FriendRequest>? pendingRequests,
    List<Suggestion>? suggestions,
    int? suggestionsOffset,
    bool? isLoadingMore,
  }) {
    return FriendsState(
      pendingRequests: pendingRequests ?? this.pendingRequests,
      suggestions: suggestions ?? this.suggestions,
      suggestionsOffset: suggestionsOffset ?? this.suggestionsOffset,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// Main notifier para gerenciar friends data
class FriendsNotifier extends AsyncNotifier<FriendsState> {
  late FriendsRepository _repo;

  @override
  Future<FriendsState> build() async {
    _repo = ref.watch(friendsRepositoryProvider);

    final pendingRequests = await _repo.getPendingRequests();
    final suggestions = await _repo.getSuggestions(limit: 6);

    return FriendsState(
      pendingRequests: pendingRequests,
      suggestions: suggestions,
      suggestionsOffset: 0,
      isLoadingMore: false,
    );
  }

  Future<void> acceptRequest(String requestId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final currentState = state.valueOrNull;
      if (currentState == null) throw Exception('Estado inválido');

      await _repo.acceptRequest(requestId);

      final updatedRequests = currentState.pendingRequests
          .where((r) => r.id != requestId)
          .toList();

      return currentState.copyWith(
        pendingRequests: updatedRequests,
      );
    });
  }

  Future<void> rejectRequest(String requestId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final currentState = state.valueOrNull;
      if (currentState == null) throw Exception('Estado inválido');

      await _repo.rejectRequest(requestId);

      final updatedRequests = currentState.pendingRequests
          .where((r) => r.id != requestId)
          .toList();

      return currentState.copyWith(
        pendingRequests: updatedRequests,
      );
    });
  }

  Future<void> sendFriendRequest(String toUserId) async {
    await AsyncValue.guard(() async {
      await _repo.sendFriendRequest(toUserId);
    });
  }

  Future<void> loadMoreSuggestions() async {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.isLoadingMore) return;

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    final result = await AsyncValue.guard(() async {
      final moreSuggestions = await _repo.getSuggestions(
        limit: 6,
        offset: currentState.suggestionsOffset + 6,
      );

      final allSuggestions = [
        ...currentState.suggestions,
        ...moreSuggestions,
      ];

      return currentState.copyWith(
        suggestions: allSuggestions,
        suggestionsOffset: currentState.suggestionsOffset + 6,
        isLoadingMore: false,
      );
    });

    state = result;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}

final friendsNotifierProvider =
    AsyncNotifierProvider<FriendsNotifier, FriendsState>(
  () => FriendsNotifier(),
);

// Search provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Search results provider
final searchResultsProvider = FutureProvider.family<List<Friend>, String>(
  (ref, query) async {
    if (query.isEmpty) return [];

    final repo = ref.watch(friendsRepositoryProvider);
    return repo.searchFriends(query);
  },
);

// Filtered suggestions provider
final filteredSuggestionsProvider = Provider<List<Suggestion>>((ref) {
  final state = ref.watch(friendsNotifierProvider).valueOrNull;
  if (state == null) return [];

  final query = ref.watch(searchQueryProvider).toLowerCase();
  if (query.isEmpty) return state.suggestions;

  return state.suggestions
      .where((s) =>
          s.friend.displayName.toLowerCase().contains(query) ||
          (s.friend.username?.toLowerCase().contains(query) ?? false))
      .toList();
});

// Friends list provider
final friendsListProvider = FutureProvider<List<Friend>>((ref) async {
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.getFriendsList();
});
