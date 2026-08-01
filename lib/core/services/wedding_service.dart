import 'package:supabase_flutter/supabase_flutter.dart';

import '../prefs/wedding_prefs.dart';
import '../supabase/supabase_init.dart';

class WeddingRecord {
  final String id;
  final double? totalBudget;
  final String? title;

  const WeddingRecord({required this.id, this.totalBudget, this.title});

  factory WeddingRecord.fromJson(Map<String, dynamic> json) => WeddingRecord(
        id: json['id'] as String,
        totalBudget: _toDouble(json['total_budget']),
        title: json['title'] as String?,
      );

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

class WeddingService {
  WeddingService({SupabaseClient? client})
      : _client = client ?? SupabaseInit.client;

  final SupabaseClient _client;
  static const _table = 'weddings';

  /// Kullanicinin dugun kaydini doner; yoksa olusturur.
  /// Oncer sahip oldugu dugunu arar; bulamazsa uye oldugu dugune bakar;
  /// hicbiri yoksa yeni olusturur. Sahip olunan dugunde budget null ise
  /// SharedPreferences'tan senkronize eder.
  Future<WeddingRecord> getOrCreateWedding(String userId) async {
    // 1. Kullanicinin sahip oldugu dugun
    var row = await _client
        .from(_table)
        .select('id, total_budget, title')
        .eq('owner_id', userId)
        .maybeSingle();

    if (row != null) {
      var record = WeddingRecord.fromJson(row);
      final updates = <String, dynamic>{};
      if (record.totalBudget == null) {
        final amount = _budgetFromString(await WeddingPrefs.getBudgetString());
        if (amount != null) updates['total_budget'] = amount;
      }
      if (record.title == null) {
        final t = await WeddingPrefs.getWeddingTitle();
        if (t != null) updates['title'] = t;
      }
      if (updates.isNotEmpty) {
        await _client.from(_table).update(updates).eq('owner_id', userId);
        record = WeddingRecord(
          id: record.id,
          totalBudget: updates['total_budget'] as double? ?? record.totalBudget,
          title: updates['title'] as String? ?? record.title,
        );
      }
      return record;
    }

    // 2. Uye oldugu baska bir dugun (viewer/editor)
    final membership = await _client
        .from('wedding_members')
        .select('wedding_id')
        .eq('user_id', userId)
        .limit(1)
        .maybeSingle();

    if (membership != null) {
      final weddingRow = await _client
          .from(_table)
          .select('id, total_budget, title')
          .eq('id', membership['wedding_id'] as String)
          .maybeSingle();
      if (weddingRow != null) return WeddingRecord.fromJson(weddingRow);
    }

    // 3. Hicbir dugun yoksa yeni olustur
    final insertData = <String, dynamic>{'owner_id': userId};
    final prefTitle = await WeddingPrefs.getWeddingTitle();
    if (prefTitle != null) insertData['title'] = prefTitle;
    final newRow = await _client
        .from(_table)
        .insert(insertData)
        .select('id, total_budget, title')
        .single();
    return WeddingRecord.fromJson(newRow);
  }

  Future<void> updateTotalBudget(String userId, double amount) async {
    await _client
        .from(_table)
        .update({'total_budget': amount})
        .eq('owner_id', userId);
  }

  /// Onboarding aralik string -> numeric donusumu.
  static double? _budgetFromString(String? s) {
    if (s == null) return null;
    if (s.startsWith('500.000 TL altı')) return 500000;
    if (s.startsWith('500.000 - 1.000.000')) return 1000000;
    if (s.startsWith('1.000.000 - 2.000.000')) return 2000000;
    if (s.startsWith('2.000.000 TL üzeri')) return 2000000;
    return null; // 'Henüz bilmiyorum'
  }
}
