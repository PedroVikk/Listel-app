import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepositoryImpl(this._client);

  @override
  Stream<AppUser?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((event) {
        final user = event.session?.user;
        return user == null ? null : _mapUser(user);
      });

  @override
  AppUser? get currentUser {
    final user = _client.auth.currentUser;
    return user == null ? null : _mapUser(user);
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
    // Login direto após cadastro (email confirmation desabilitado temporariamente)
    await _client.auth.signInWithPassword(email: email, password: password);
    // TODO: reabilitar após configurar email confirmation corretamente
    // if (response.user != null) {
    //   await _client.from('profiles').upsert({
    //     'id': response.user!.id,
    //     'display_name': displayName,
    //   });
    // }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  AppUser _mapUser(User user) => AppUser(
        id: user.id,
        email: user.email ?? '',
        displayName: user.userMetadata?['display_name'] as String? ??
            user.email?.split('@').first ??
            'Usuário',
      );
}
