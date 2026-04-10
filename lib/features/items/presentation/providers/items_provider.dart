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

/// Determina se a coleção é compartilhada. Aguarda a primeira emissão do
/// stream de coleções compartilhadas para evitar a race condition onde
/// valueOrNull == null durante AsyncLoading. Se o Realtime der timeout ou
/// falhar por qualquer motivo de rede, assume local (false) para não quebrar
/// coleções locais que independem do Supabase.
final _collectionIsSharedProvider =
    FutureProvider.family<bool, String>((ref, collectionId) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return false;

  // Se o stream já emitiu pelo menos uma vez, usa o valor em cache.
  final cached = ref.read(sharedCollectionsStreamProvider).valueOrNull;
  if (cached != null) {
    return cached.any((c) => c.remoteId == collectionId || c.id == collectionId);
  }

  // Aguarda a primeira emissão; captura falhas de Realtime para não
  // propagar o erro para coleções locais.
  try {
    final shared = await ref.watch(sharedCollectionsStreamProvider.future);
    return shared.any((c) => c.remoteId == collectionId || c.id == collectionId);
  } catch (_) {
    // Realtime indisponível (timeout, sem rede etc.) — trata como local.
    return false;
  }
});

/// Stream dos itens da coleção. Aguarda saber se é compartilhada antes de
/// abrir o stream do repo correto (Isar local ou Supabase remoto).
final itemsByCollectionProvider =
    StreamProvider.family<List<SavedItem>, String>((ref, collectionId) async* {
  final isShared =
      await ref.watch(_collectionIsSharedProvider(collectionId).future);
  final repo = isShared
      ? ref.watch(remoteItemsRepositoryProvider)
      : ref.watch(itemsRepositoryProvider);
  yield* repo.watchByCollection(collectionId);
});

class ItemsNotifier extends FamilyAsyncNotifier<List<SavedItem>, String> {
  /// Repo assíncrono: aguarda determinar se a coleção é compartilhada antes
  /// de retornar o repo correto. Garante que writes nunca vão para o lugar errado.
  Future<ItemsRepository> get _repoAsync async {
    final isShared =
        await ref.read(_collectionIsSharedProvider(arg).future);
    return isShared
        ? ref.read(remoteItemsRepositoryProvider)
        : ref.read(itemsRepositoryProvider);
  }

  @override
  Future<List<SavedItem>> build(String collectionId) async {
    final isShared =
        await ref.watch(_collectionIsSharedProvider(collectionId).future);
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
    final repo = await _repoAsync;
    await repo.save(item);
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
    final repo = await _repoAsync;
    await repo.save(item);
    ref.invalidateSelf();
  }

  Future<void> toggleStatus(SavedItem item) async {
    final updated = item.copyWith(
      status: item.isPurchased ? ItemStatus.pending : ItemStatus.purchased,
      updatedAt: DateTime.now(),
    );
    final repo = await _repoAsync;
    await repo.save(updated);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    final repo = await _repoAsync;
    await repo.delete(id);
    ref.invalidateSelf();
  }

  Future<void> updateItem(SavedItem item) async {
    final repo = await _repoAsync;
    await repo.save(item.copyWith(updatedAt: DateTime.now()));
    ref.invalidateSelf();
  }

  Future<void> moveToCollection(
      SavedItem item, String targetCollectionId) async {
    final updated = item.copyWith(
      collectionId: targetCollectionId,
      updatedAt: DateTime.now(),
    );
    final targetIsShared =
        await ref.read(_collectionIsSharedProvider(targetCollectionId).future);
    final targetRepo = targetIsShared
        ? ref.read(remoteItemsRepositoryProvider)
        : ref.read(itemsRepositoryProvider);
    final repo = await _repoAsync;
    await repo.delete(item.id);
    await targetRepo.save(updated);
    ref.invalidateSelf();
  }
}

final itemsNotifierProvider =
    AsyncNotifierProviderFamily<ItemsNotifier, List<SavedItem>, String>(
  ItemsNotifier.new,
);

// ─── Pesquisa global ──────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider =
    FutureProvider.autoDispose<List<SavedItem>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  final repo = ref.watch(itemsRepositoryProvider);
  return repo.searchByName(query.trim());
});
