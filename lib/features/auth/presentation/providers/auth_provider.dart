import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/supabase_auth_repository_impl.dart';

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
