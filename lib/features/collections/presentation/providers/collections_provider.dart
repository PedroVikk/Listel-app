import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/collection.dart';
import '../../domain/repositories/collections_repository.dart';
import '../../data/repositories/collections_repository_impl.dart';

final collectionsRepositoryProvider = Provider<CollectionsRepository>(
  (ref) => CollectionsRepositoryImpl(),
);

final collectionsStreamProvider = StreamProvider<List<Collection>>((ref) {
  return ref.watch(collectionsRepositoryProvider).watchAll();
});

class CollectionsNotifier extends AsyncNotifier<List<Collection>> {
  @override
  Future<List<Collection>> build() async {
    return ref.watch(collectionsRepositoryProvider).getAll();
  }

  Future<void> create({
    required String name,
    String? emoji,
    required int colorValue,
  }) async {
    final now = DateTime.now();
    final collection = Collection(
      id: const Uuid().v4(),
      name: name,
      emoji: emoji,
      colorValue: colorValue,
      createdAt: now,
      updatedAt: now,
    );
    await ref.read(collectionsRepositoryProvider).save(collection);
    ref.invalidateSelf();
  }

  Future<void> updateCollection(Collection collection) async {
    final updated = collection.copyWith(updatedAt: DateTime.now());
    await ref.read(collectionsRepositoryProvider).save(updated);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await ref.read(collectionsRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}

final collectionsNotifierProvider =
    AsyncNotifierProvider<CollectionsNotifier, List<Collection>>(
  CollectionsNotifier.new,
);
