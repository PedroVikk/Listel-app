import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepositoryImpl(this._client);

  // ─── Auth state ──────────────────────────────────────────────────────────

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

  // ─── Sign-in ─────────────────────────────────────────────────────────────

  @override
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthException(_translate(e));
    }
  }

  // ─── Sign-up ─────────────────────────────────────────────────────────────

  @override
  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

      // Se o Supabase não criou sessão, a confirmação de e-mail está ativa.
      if (response.session == null) {
        throw AuthException(
          'Cadastro realizado! Verifique seu e-mail para confirmar a conta.',
        );
      }

      // Upsert do perfil público (tabela profiles).
      final uid = response.user!.id;
      await _client.from('profiles').upsert({
        'id': uid,
        'display_name': displayName,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } on AuthException {
      rethrow;
    } catch (e) {
      // Falha no upsert de profiles — usuário foi criado, login já está ativo,
      // então apenas logamos e deixamos seguir.
      // ignore: avoid_print
      print('[Auth] profiles upsert falhou (não bloqueante): $e');
    }
  }

  // ─── Sign-out ─────────────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  AppUser _mapUser(User user) => AppUser(
        id: user.id,
        email: user.email ?? '',
        displayName: user.userMetadata?['display_name'] as String? ??
            user.email?.split('@').first ??
            'Usuário',
      );

  /// Traduz mensagens de erro do Supabase Auth para português.
  String _translate(AuthException e) {
    final msg = e.message.toLowerCase();
    final code = e.statusCode;

    // Credenciais / conta
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid email or password')) {
      return 'E-mail ou senha incorretos.';
    }
    if (msg.contains('email not confirmed')) {
      return 'E-mail ainda não confirmado. Verifique sua caixa de entrada.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already been registered') ||
        msg.contains('email address is already registered')) {
      return 'Este e-mail já está cadastrado.';
    }
    if (msg.contains('user not found')) {
      return 'Nenhuma conta encontrada com este e-mail.';
    }

    // Senha
    if (msg.contains('password should be at least') ||
        msg.contains('weak password') ||
        msg.contains('password is too short')) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    if (msg.contains('same password')) {
      return 'A nova senha deve ser diferente da senha atual.';
    }

    // E-mail inválido
    if (msg.contains('unable to validate email') ||
        msg.contains('invalid email')) {
      return 'Endereço de e-mail inválido.';
    }

    // Rate limit / segurança
    if (code == '429' ||
        msg.contains('rate limit') ||
        msg.contains('too many requests')) {
      return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
    }
    if (msg.contains('for security purposes') ||
        msg.contains('after') && msg.contains('seconds')) {
      return 'Por segurança, aguarde antes de tentar novamente.';
    }

    // Sessão / token
    if (msg.contains('token has expired') || msg.contains('session expired')) {
      return 'Sessão expirada. Faça login novamente.';
    }
    if (msg.contains('refresh token')) {
      return 'Sessão inválida. Faça login novamente.';
    }

    // Signup desabilitado
    if (msg.contains('signup is disabled') ||
        msg.contains('signups not allowed')) {
      return 'Cadastro desabilitado no momento.';
    }

    // Fallback: devolve a mensagem original sem tradução.
    return e.message;
  }
}
