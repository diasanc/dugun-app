import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../../core/errors/app_auth_exception.dart';
import '../../../../core/supabase/supabase_init.dart';
import '../../domain/entities/auth_user.dart';

abstract class AuthRemoteDatasource {
  Future<AuthUser> signIn({required String email, required String password});
  Future<AuthUser?> signUp({required String email, required String password});
  Future<void> signOut();
  AuthUser? get currentUser;
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final SupabaseClient _client;

  AuthRemoteDatasourceImpl() : _client = SupabaseInit.client;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) throw const AppAuthException('Giriş başarısız.');
      return AuthUser(id: user.id, email: user.email ?? email);
    } on AuthException catch (e) {
      throw AppAuthException(_mapError(e.message));
    }
  }

  @override
  Future<AuthUser?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) throw const AppAuthException('Kayıt başarısız.');
      // session null → Supabase e-posta doğrulaması bekliyor
      if (response.session == null) return null;
      return AuthUser(id: user.id, email: user.email ?? email);
    } on AuthException catch (e) {
      throw AppAuthException(_mapError(e.message));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AppAuthException(_mapError(e.message));
    }
  }

  @override
  AuthUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return AuthUser(id: user.id, email: user.email ?? '');
  }

  String _mapError(String raw) {
    if (raw.contains('Invalid login credentials')) {
      return 'E-posta veya şifre hatalı.';
    }
    if (raw.contains('Email not confirmed')) {
      return 'E-postanızı doğrulamadan giriş yapamazsınız.';
    }
    if (raw.contains('User already registered')) {
      return 'Bu e-posta adresi zaten kayıtlı.';
    }
    if (raw.contains('Password should be at least')) {
      return 'Şifre en az 6 karakter olmalıdır.';
    }
    return raw;
  }
}
