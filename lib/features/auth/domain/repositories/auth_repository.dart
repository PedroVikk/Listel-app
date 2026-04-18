import '../entities/app_user.dart';

abstract class AuthRepository {
  /// Stream que emite o usuário atual (ou null quando deslogado).
  Stream<AppUser?> get authStateChanges;

  /// Usuário atualmente logado (null se deslogado).
  AppUser? get currentUser;

  Future<void> signInWithEmail(String email, String password);

  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName, {
    required String username,
  });

  /// Verifica se um `username` (normalizado para lowercase) já está em uso.
  Future<bool> isUsernameAvailable(String username);

  Future<void> signOut();

  /// Envia e-mail de redefinição de senha para o endereço informado.
  Future<void> resetPasswordForEmail(String email);

  /// Atualiza o displayName do usuário.
  Future<void> updateDisplayName(String newDisplayName);

  /// Atualiza o username do usuário.
  Future<void> updateUsername(String newUsername);

  /// Faz upload do avatar para Supabase Storage e atualiza o perfil.
  Future<String> uploadAvatarAndUpdate(String filePath);
}
