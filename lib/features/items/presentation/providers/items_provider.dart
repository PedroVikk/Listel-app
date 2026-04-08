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
  /// Retorna o repositório correto: remoto se a coleção for compartilhada, local caso contrário.
  ItemsRepository get _repo {
    final isShared = ref.read(_collectionIsSharedProvider(arg));
    return isShared
        ? ref.read(remoteItemsRepositoryProvider)
        : ref.read(itemsRepositoryProvider);
  }

  @override
  Future<List<SavedItem>> build(String collectionId) async {
    final isShared = ref.watch(_collectionIsSharedProvider(collectionId));
    final repo = isShared
        ? ref.watch(remoteItemsRepositoryProvider)
        : ref.watch(itemsRepositoryProvider);
    return repo.getByCollection(collectionId);
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
    await _repo.save(item);
    ref.invalidateSelf();
  }

  Future<void> createManual({
    required String collectionId,
    required String name,
    String? localImagePath,
    String? url,
    double? price,
    String? notes,
  }) async {
    final now = DateTime.now();
    final item = SavedItem(
      id: const Uuid().v4(),
      collectionId: collectionId,
      name: name,
      localImagePath: localImagePath,
      url: url,
      price: price,
      notes: notes,
      status: ItemStatus.pending,
      source: ItemSource.manual,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.save(item);
    ref.invalidateSelf();
  }

  Future<void> toggleStatus(SavedItem item) async {
    final updated = item.copyWith(
      status: item.isPurchased ? ItemStatus.pending : ItemStatus.purchased,
      updatedAt: DateTime.now(),
    );
    await _repo.save(updated);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    ref.invalidateSelf();
  }

  Future<void> moveToCollection(
      SavedItem item, String targetCollectionId) async {
    final updated = item.copyWith(
      collectionId: targetCollectionId,
      updatedAt: DateTime.now(),
    );
    final targetIsShared =
        ref.read(_collectionIsSharedProvider(targetCollectionId));
    final targetRepo = targetIsShared
        ? ref.read(remoteItemsRepositoryProvider)
        : ref.read(itemsRepositoryProvider);
    await _repo.delete(item.id);
    await targetRepo.save(updated);
    ref.invalidateSelf();
  }
}

final itemsNotifierProvider =
    AsyncNotifierProviderFamily<ItemsNotifier, List<SavedItem>, String>(
  ItemsNotifier.new,
);
