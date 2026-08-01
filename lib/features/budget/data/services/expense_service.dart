import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_init.dart';
import '../models/expense.dart';

/// public.expenses tablosu icin Supabase CRUD servisi.
///
/// RLS politikalari erisimi belirler (SELECT: tum uyeler; yazma: admin+editor).
/// [client] disaridan verilebilir -> test edilebilirlik (SOLID/DIP).
class ExpenseService {
  ExpenseService({SupabaseClient? client})
      : _client = client ?? SupabaseInit.client;

  final SupabaseClient _client;

  static const String _table = 'expenses';

  /// Bir dugune ait gider kalemlerini en yeni once olacak sekilde getirir.
  Future<List<Expense>> fetchByWedding(String weddingId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('wedding_id', weddingId)
        .order('created_at', ascending: false);

    return rows.map(Expense.fromJson).toList();
  }

  /// Gider listesini canli dinler (realtime).
  Stream<List<Expense>> watchByWedding(String weddingId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('wedding_id', weddingId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(Expense.fromJson).toList());
  }

  /// Yeni gider kalemi ekler ve eklenen satiri doner.
  Future<Expense> create(Expense expense) async {
    final row =
        await _client.from(_table).insert(expense.toInsert()).select().single();
    return Expense.fromJson(row);
  }

  /// Var olan gider kalemini gunceller ve guncel satiri doner.
  Future<Expense> update(Expense expense) async {
    final row = await _client
        .from(_table)
        .update(expense.toUpdate())
        .eq('id', expense.id)
        .select()
        .single();
    return Expense.fromJson(row);
  }

  /// Gider kalemini siler.
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
