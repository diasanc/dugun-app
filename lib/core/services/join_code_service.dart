import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_init.dart';

class JoinCodeService {
  JoinCodeService({SupabaseClient? client})
      : _client = client ?? SupabaseInit.client;

  final SupabaseClient _client;

  static const _weddingsTable = 'weddings';
  static const _membersTable = 'wedding_members';

  // Pending code: RegisterPage'den dönüş sonrası işlenmek üzere saklanır.
  static String? _pendingCode;

  static void setPendingCode(String code) => _pendingCode = code;

  static String? consumePendingCode() {
    final code = _pendingCode;
    _pendingCode = null;
    return code;
  }

  static bool get hasPendingCode => _pendingCode != null;

  /// Kullanıcının düğün kaydını bulur; join_code yoksa oluşturur ve döner.
  Future<String> getOrCreateJoinCode(String userId) async {
    final row = await _client
        .from(_weddingsTable)
        .select('id, join_code')
        .eq('owner_id', userId)
        .maybeSingle();

    if (row != null) {
      final existing = row['join_code'] as String?;
      if (existing != null && existing.isNotEmpty) return existing;

      final code = _generateCode();
      await _client
          .from(_weddingsTable)
          .update({'join_code': code})
          .eq('owner_id', userId);
      return code;
    }

    final code = _generateCode();
    await _client.from(_weddingsTable).insert({
      'owner_id': userId,
      'join_code': code,
    });
    return code;
  }

  /// Kodu `weddings` tablosunda arar. Geçerliyse wedding_id, değilse null döner.
  Future<String?> validateCode(String code) async {
    final row = await _client
        .from(_weddingsTable)
        .select('id')
        .eq('join_code', code.toUpperCase().trim())
        .maybeSingle();

    return row?['id'] as String?;
  }

  /// Kodu doğrulayıp kullanıcıyı `wedding_members`'a viewer olarak ekler.
  Future<void> joinByCode(String code, String userId) async {
    final weddingId = await validateCode(code);
    if (weddingId == null) throw const _InvalidCodeException();

    await _client.from(_membersTable).upsert(
      {
        'wedding_id': weddingId,
        'user_id': userId,
        'role': 'viewer',
      },
      onConflict: 'wedding_id,user_id',
    );
  }

  static String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

class _InvalidCodeException implements Exception {
  const _InvalidCodeException();
  @override
  String toString() => 'Geçersiz katılım kodu.';
}

/// Dışarıdan kullanılabilir hata tipi.
class InvalidJoinCodeException implements Exception {
  const InvalidJoinCodeException();
}
