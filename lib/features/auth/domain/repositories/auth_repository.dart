import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser> signIn({required String email, required String password});

  /// Kayıt sonrası oturum açıldıysa [AuthUser] döner;
  /// e-posta doğrulaması gerekiyorsa null döner.
  Future<AuthUser?> signUp({required String email, required String password});

  Future<void> signOut();

  AuthUser? get currentUser;
}
