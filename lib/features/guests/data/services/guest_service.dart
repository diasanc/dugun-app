import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_init.dart';
import '../models/guest.dart';

/// public.guests tablosu icin Supabase CRUD servisi.
///
/// RLS politikalari erisimi belirler (SELECT: tum uyeler; yazma: admin+editor),
/// bu yuzden servis ekstra yetki kontrolu yapmaz; yetkisiz islem DB'de reddedilir.
/// [client] disaridan verilebilir -> test edilebilirlik (SOLID/DIP).
class GuestService {
  GuestService({SupabaseClient? client})
      : _client = client ?? SupabaseInit.client;

  final SupabaseClient _client;

  static const String _table = 'guests';

  /// Bir dugune ait davetlileri isim sirasiyla getirir.
  Future<List<Guest>> fetchByWedding(String weddingId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('wedding_id', weddingId)
        .order('full_name');

    return rows.map(Guest.fromJson).toList();
  }

  /// Davetli listesini canli dinler (realtime). UI stream'e abone olur.
  Stream<List<Guest>> watchByWedding(String weddingId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('wedding_id', weddingId)
        .order('full_name', ascending: true)
        .map((rows) => rows.map(Guest.fromJson).toList());
  }

  /// Yeni davetli ekler ve eklenen satiri (sunucu alanlariyla) doner.
  Future<Guest> create(Guest guest) async {
    final row =
        await _client.from(_table).insert(guest.toInsert()).select().single();
    return Guest.fromJson(row);
  }

  /// Var olan davetliyi gunceller ve guncel satiri doner.
  Future<Guest> update(Guest guest) async {
    final row = await _client
        .from(_table)
        .update(guest.toUpdate())
        .eq('id', guest.id)
        .select()
        .single();
    return Guest.fromJson(row);
  }

  /// Davetliyi siler.
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
