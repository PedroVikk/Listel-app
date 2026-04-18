import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/supabase_auth_repository_impl.dart';
import '../../../collections/presentation/providers/collections_provider.dart';
import '../../../items/presentation/providers/items_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepositoryImpl(Supabase.instance.client);
});

/// Stream do estado de autenticação — emite AppUser? a cada mudança de sessão.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Usuário atual de forma síncrona (null = não logado).
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).currentUser;
});

/// Profile do usuário com estatísticas agregadas.
/// Refetch quando authStateProvider ou collections mudam.
final userProfileProvider = FutureProvider<({
  AppUser user,
  int collectionsCount,
  int itemsCount,
  int friendsCount,
})?>((ref) async {
  final user = await ref.watch(authStateProvider.future);

  if (user == null) return null;

  try {
    final localCollections =
        await ref.watch(collectionsStreamProvider.future);
    final sharedCollections =
        await ref.watch(sharedCollectionsStreamProvider.future);

    final collectionsCount = localCollections.length + sharedCollections.length;

    // Calcula total de itens iterando coleções
    int totalItems = 0;
    final allCollectionIds = [
      ...localCollections.map((c) => c.id),
      ...sharedCollections.map((c) => c.id)
    ];

    for (final collectionId in allCollectionIds) {
      try {
        final items =
            await ref.watch(itemsByCollectionProvider(collectionId).future);
        totalItems += items.length;
      } catch (_) {
        // Ignora erros de coleções que não existem mais
      }
    }

    return (
      user: user,
      collectionsCount: collectionsCount,
      itemsCount: totalItems,
      friendsCount: 0, // hardcoded por enquanto
    );
  } catch (_) {
    // Se algo der errado, retorna usuário com zeros
    return (
      user: user,
      collectionsCount: 0,
      itemsCount: 0,
      friendsCount: 0,
    );
  }
});
