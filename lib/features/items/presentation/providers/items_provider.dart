import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/saved_item.dart';
import '../../domain/repositories/items_repository.dart';
import '../../data/repositories/items_repository_impl.dart';
import '../../data/repositories/remote_items_repository_impl.dart';
import '../../../collections/presentation/providers/collections_provider.dart';

final itemsRepositoryProvider = Provider<ItemsRepository>(
  (ref) => ItemsRepositoryImpl(),
);

final remoteItemsRepositoryProvider = Provider<ItemsRepository>(
  (ref) => RemoteItemsRepositoryImpl(Supabase.instance.client),
);

/// Decide qual repositório usar baseado em se a coleção é compartilhada.
final _collectionIsSharedProvider =
    Provider.family<bool, String>((ref, collectionId) {
  final local = ref.watch(collectionsStreamProvider).valueOrNull ?? [];
  final shared = ref.watch(sharedCollectionsStreamProvider).valueOrNull ?? [];
  return shared.any((c) => c.remoteId == collectionId || c.id == collectionId) &&
      !local.any((c) => c.id == collectionId);
});

final itemsByCollectionProvider =
    StreamProvider.family<List<SavedItem>, String>((ref, collectionId) {
  final isShared = ref.watch(_collectionIsSharedProvider(collectionId));
  final repo = isShared
      ? ref.watch(remoteItemsRepositoryProvider)
      : ref.watch(itemsRepositoryProvider);
  return repo.watchByCollection(collectionId);
});

class ItemsNotifier extends FamilyAsyncNotifier<List<SavedItem>, String> {
  @override
  Future<List<SavedItem>> build(String collectionId) async {
    return ref.watch(itemsRepositoryProvider).getByCollection(collectionId);
  }

  Future<void> createFromShare({
    required String collectionId,
    required String name,
    String? url,
    String? imageUrl,
    double? price,
    String? store,
    String? notes,
  }) async {
    final now = DateTime.now();
    final item = SavedItem(
      id: const Uuid().v4(),
      collectionId: collectionId,
      url: url,
      name: name,
      imageUrl: imageUrl,
      price: price,
      store: store,
      notes: notes,
      status: ItemStatus.pending,
      source: ItemSource.shared,
      createdAt: now,
      updatedAt: now,
    );
    await ref.read(itemsRepositoryProvider).save(item);
    ref.invalidateSelf();
  }

  Future<void> createManual({
    required String collectionId,
    required String name,
    String? localImagePath,
    double? price,
    String? notes,
  }) async {
    final now = DateTime.now();
    final item = SavedItem(
      id: const Uuid().v4(),
      collectionId: collectionId,
      name: name,
      localImagePath: localImagePath,
      price: price,
      notes: notes,
      status: ItemStatus.pending,
      source: ItemSource.manual,
      createdAt: now,
      updatedAt: now,
    );
    await ref.read(itemsRepositoryProvider).save(item);
    ref.invalidateSelf();
  }

  Future<void> toggleStatus(SavedItem item) async {
    final updated = item.copyWith(
      status: item.isPurchased ? ItemStatus.pending : ItemStatus.purchased,
      updatedAt: DateTime.now(),
    );
    await ref.read(itemsRepositoryProvider).save(updated);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await ref.read(itemsRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}

final itemsNotifierProvider =
    AsyncNotifierProviderFamily<ItemsNotifier, List<SavedItem>, String>(
  ItemsNotifier.new,
);
