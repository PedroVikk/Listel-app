import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/collection.dart';
import '../../domain/repositories/collections_repository.dart';
import '../../data/repositories/collections_repository_impl.dart';
import '../../data/repositories/remote_collections_repository_impl.dart';
import '../../data/datasources/remote_collections_datasource.dart' as rds;

/// Provider do repositório local (Isar).
final collectionsRepositoryProvider = Provider<CollectionsRepository>(
  (ref) => CollectionsRepositoryImpl(),
);

/// Provider do repositório remoto (Supabase).
final remoteCollectionsRepositoryProvider = Provider<CollectionsRepository>(
  (ref) => RemoteCollectionsRepositoryImpl(Supabase.instance.client),
);

/// Provider da data source remota (Supabase) para acesso direto.
final remoteCollectionsDataSourceProvider =
    Provider<rds.RemoteCollectionsDataSource>((ref) {
  return rds.RemoteCollectionsDataSource(Supabase.instance.client);
});

/// Stream das coleções locais (Isar) — apenas locais, não compartilhadas.
final collectionsStreamProvider = StreamProvider<List<Collection>>((ref) {
  return ref.watch(collectionsRepositoryProvider).watchAll();
});

/// Stream das coleções do usuário no Supabase (próprias).
/// Compatível com nome anterior `sharedCollectionsStreamProvider`.
final sharedCollectionsStreamProvider = StreamProvider<List<Collection>>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return const Stream.empty();

  return ref.watch(remoteCollectionsRepositoryProvider).watchAll().asyncMap(
    (remoteCollections) async {
      // Overlay com coverImagePath local se existir
      final localRepo = ref.watch(collectionsRepositoryProvider);
      return Future.wait(
        remoteCollections.map((c) async {
          final local = await localRepo.getById(c.id);
          if (local?.coverImagePath == null) return c;
          return c.copyWith(coverImagePath: local!.coverImagePath);
        }),
      );
    },
  );
});

/// Stream das coleções públicas de um usuário específico (para perfil).
/// Recarrega quando userId muda.
final userPublicCollectionsStreamProvider =
    StreamProvider.family<List<Collection>, String>((ref, userId) {
  final dataSource = ref.watch(remoteCollectionsDataSourceProvider);
  return dataSource.watchPublicCollections(userId);
});

class CollectionsNotifier extends AsyncNotifier<List<Collection>> {
  @override
  Future<List<Collection>> build() async {
    return ref.watch(collectionsRepositoryProvider).getAll();
  }

  /// Cria nova coleção local (não sincronizada).
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

  /// Atualiza coleção existente e enfileira sincronização se remoteId existir.
  Future<void> updateCollection(Collection collection) async {
    final updated = collection.copyWith(updatedAt: DateTime.now());
    await ref.read(collectionsRepositoryProvider).save(updated);
    ref.invalidateSelf();
  }

  /// Deleta coleção localmente e enfileira exclusão remota se aplicável.
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

/// Notifier para gerenciar coleções locais.
final collectionsNotifierProvider =
    AsyncNotifierProvider<CollectionsNotifier, List<Collection>>(
  CollectionsNotifier.new,
);
