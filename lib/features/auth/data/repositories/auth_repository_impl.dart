import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;

  const AuthRepositoryImpl(this._datasource);

  @override
  Future<AuthUser> signIn({required String email, required String password}) =>
      _datasource.signIn(email: email, password: password);

  @override
  Future<AuthUser?> signUp({required String email, required String password}) =>
      _datasource.signUp(email: email, password: password);

  @override
  Future<void> signOut() => _datasource.signOut();

  @override
  AuthUser? get currentUser => _datasource.currentUser;
}
