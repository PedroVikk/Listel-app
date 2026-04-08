import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/collection.dart';
import '../../domain/repositories/collections_repository.dart';
import '../../data/repositories/collections_repository_impl.dart';
import '../../data/repositories/remote_collections_repository_impl.dart';

final collectionsRepositoryProvider = Provider<CollectionsRepository>(
  (ref) => CollectionsRepositoryImpl(),
);

final remoteCollectionsRepositoryProvider = Provider<CollectionsRepository>(
  (ref) => RemoteCollectionsRepositoryImpl(Supabase.instance.client),
);

/// Stream das coleções locais (Isar).
final collectionsStreamProvider = StreamProvider<List<Collection>>((ref) {
  return ref.watch(collectionsRepositoryProvider).watchAll();
});

/// Stream das coleções compartilhadas (Supabase Realtime).
/// Emite lista vazia se não autenticado.
/// Faz overlay do coverImagePath salvo localmente no Isar (por id/remoteId).
final sharedCollectionsStreamProvider = StreamProvider<List<Collection>>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return const Stream.empty();

  final localRepo = ref.watch(collectionsRepositoryProvider);

  return ref.watch(remoteCollectionsRepositoryProvider).watchAll().asyncMap(
    (remoteCollections) => Future.wait(
      remoteCollections.map((c) async {
        final local = await localRepo.getById(c.id);
        if (local?.coverImagePath == null) return c;
        return c.copyWith(coverImagePath: local!.coverImagePath);
      }),
    ),
  );
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
    String? coverImagePath,
  }) async {
    final now = DateTime.now();
    final collection = Collection(
      id: const Uuid().v4(),
      name: name,
      emoji: emoji,
      colorValue: colorValue,
      createdAt: now,
      updatedAt: now,
      coverImagePath: coverImagePath,
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
    final existing = await ref.read(collectionsRepositoryProvider).getById(id);
    if (existing?.coverImagePath != null) {
      final file = File(existing!.coverImagePath!);
      if (await file.exists()) await file.delete();
    }
    await ref.read(collectionsRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}

final collectionsNotifierProvider =
    AsyncNotifierProvider<CollectionsNotifier, List<Collection>>(
  CollectionsNotifier.new,
);
