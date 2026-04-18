import 'dart:io';
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
    String displayName, {
    required String username,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();

    // Pré-checagem de unicidade (UX): evita criar conta no Auth se o @ já existe.
    try {
      final available = await isUsernameAvailable(normalizedUsername);
      if (!available) {
        throw AuthException('Este @usuário já está em uso.');
      }
    } on AuthException {
      rethrow;
    } catch (_) {
      // Se o SELECT falhar (rede/offline), deixa o upsert decidir via UNIQUE index.
    }

    final AuthResponse response;
    try {
      response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
          'username': normalizedUsername,
        },
      );
    } on AuthException catch (e) {
      throw AuthException(_translate(e));
    }

    // Se o Supabase não criou sessão, a confirmação de e-mail está ativa.
    if (response.session == null) {
      throw AuthException(
        'Cadastro realizado! Verifique seu e-mail para confirmar a conta.',
      );
    }

    // Upsert do perfil público (tabela profiles).
    try {
      final uid = response.user!.id;
      await _client.from('profiles').upsert({
        'id': uid,
        'display_name': displayName,
        'username': normalizedUsername,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      // 23505 = unique_violation (username ou id duplicado).
      if (e.code == '23505') {
        throw AuthException('Este @usuário já está em uso.');
      }
      // ignore: avoid_print
      print('[Auth] profiles upsert falhou (não bloqueante): $e');
    } catch (e) {
      // ignore: avoid_print
      print('[Auth] profiles upsert falhou (não bloqueante): $e');
    }
  }

  // ─── Username availability ───────────────────────────────────────────────

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    final row = await _client
        .from('profiles')
        .select('id')
        .eq('username', normalized)
        .limit(1)
        .maybeSingle();

    return row == null;
  }

  // ─── Sign-out ─────────────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ─── Reset password ──────────────────────────────────────────────────────

  @override
  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw AuthException(_translate(e));
    }
  }

  // ─── Update profile ──────────────────────────────────────────────────────

  @override
  Future<void> updateDisplayName(String newDisplayName) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw AuthException('Usuário não autenticado.');
      await _client.auth.updateUser(
        UserAttributes(data: {'display_name': newDisplayName}),
      );
      await _client.from('profiles').update({
        'display_name': newDisplayName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } on AuthException catch (e) {
      throw AuthException(_translate(e));
    } catch (e) {
      throw AuthException('Erro ao atualizar nome: $e');
    }
  }

  @override
  Future<void> updateUsername(String newUsername) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw AuthException('Usuário não autenticado.');
      final normalized = newUsername.trim().toLowerCase();

      // Verifica se o username já está em uso por outro usuário
      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('username', normalized)
          .neq('id', user.id)
          .limit(1)
          .maybeSingle();

      if (existing != null) {
        throw AuthException('Este @usuário já está em uso.');
      }

      await _client.from('profiles').update({
        'username': normalized,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } on AuthException catch (e) {
      throw AuthException(_translate(e));
    } catch (e) {
      throw AuthException('Erro ao atualizar @usuário: $e');
    }
  }

  @override
  Future<String> uploadAvatarAndUpdate(String filePath) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw AuthException('Usuário não autenticado.');

      final file = File(filePath);
      if (!await file.exists()) {
        throw AuthException('Arquivo de imagem não encontrado.');
      }

      final fileName = 'avatar_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final remotePath = '${user.id}/$fileName';

      await _client.storage.from('avatars').upload(remotePath, file);

      final publicUrl = _client.storage.from('avatars').getPublicUrl(remotePath);

      await _client.from('profiles').update({
        'avatar_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      return publicUrl;
    } on StorageException catch (e) {
      throw AuthException('Erro ao fazer upload da imagem: ${e.message}');
    } on PostgrestException catch (e) {
      throw AuthException('Erro ao atualizar perfil: ${e.message}');
    } catch (e) {
      throw AuthException('Erro ao fazer upload do avatar: $e');
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  AppUser _mapUser(User user) => AppUser(
        id: user.id,
        email: user.email ?? '',
        displayName: user.userMetadata?['display_name'] as String? ??
            user.email?.split('@').first ??
            'Usuário',
        username: user.userMetadata?['username'] as String?,
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
