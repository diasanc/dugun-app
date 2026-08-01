import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_auth_exception.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';

enum AuthStatus {
  loading,
  authenticated,
  unauthenticated,
  emailConfirmationPending,
  error,
}

class AuthController extends ChangeNotifier {
  final SignInUseCase _signIn;
  final SignUpUseCase _signUp;
  final SignOutUseCase _signOut;
  final GetCurrentUserUseCase _getCurrentUser;

  AuthController({
    required SignInUseCase signIn,
    required SignUpUseCase signUp,
    required SignOutUseCase signOut,
    required GetCurrentUserUseCase getCurrentUser,
  })  : _signIn = signIn,
        _signUp = signUp,
        _signOut = signOut,
        _getCurrentUser = getCurrentUser {
    _checkSession();
  }

  AuthStatus _status = AuthStatus.loading;
  AuthUser? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  String? get errorMessage => _errorMessage;

  void _checkSession() {
    _user = _getCurrentUser();
    _status =
        _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
  }

  static const _timeout = Duration(seconds: 20);

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      _user = await _signIn(email: email, password: password)
          .timeout(_timeout);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
    } on AppAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
    } catch (_) {
      _status = AuthStatus.error;
      _errorMessage = 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.';
    }
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      final user = await _signUp(email: email, password: password)
          .timeout(_timeout);
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.emailConfirmationPending;
      }
      _errorMessage = null;
    } on AppAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
    } catch (_) {
      _status = AuthStatus.error;
      _errorMessage = 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.';
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    _setLoading();
    try {
      await _signOut();
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
    } on AppAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
    } catch (_) {
      _status = AuthStatus.error;
      _errorMessage = 'Beklenmeyen bir hata oluştu.';
    }
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }
}
