import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/sharing_repository.dart';
import '../../data/repositories/supabase_sharing_repository_impl.dart';
import '../../../collections/domain/entities/collection.dart';
import '../../../auth/domain/entities/collection_member.dart';

final sharingRepositoryProvider = Provider<SharingRepository>(
  (ref) => SupabaseSharingRepositoryImpl(Supabase.instance.client),
);

final membersProvider =
    FutureProvider.family<List<CollectionMember>, String>((ref, remoteId) {
  return ref.watch(sharingRepositoryProvider).getMembers(remoteId);
});

class SharingNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Collection> createSharedCollection({
    required String name,
    String? emoji,
    required int colorValue,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => ref
        .read(sharingRepositoryProvider)
        .createSharedCollection(name: name, emoji: emoji, colorValue: colorValue));
    state = result.whenData((_) {});
    return result.value!;
  }

  Future<Collection> joinByInviteCode(String code) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
        () => ref.read(sharingRepositoryProvider).joinByInviteCode(code));
    state = result.whenData((_) {});
    return result.value!;
  }

  Future<void> leaveCollection(String remoteId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(sharingRepositoryProvider).leaveCollection(remoteId));
  }
}

final sharingNotifierProvider =
    AsyncNotifierProvider<SharingNotifier, void>(SharingNotifier.new);
