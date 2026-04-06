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
    String displayName,
  );

  Future<void> signOut();
}
