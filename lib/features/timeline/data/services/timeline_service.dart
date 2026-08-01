import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_init.dart';
import '../models/timeline_task.dart';

typedef SampleItem = ({
  String title,
  String category,
  String period,
  int daysBefore
});

class TimelineService {
  TimelineService({SupabaseClient? client})
      : _client = client ?? SupabaseInit.client;

  final SupabaseClient _client;
  static const String _table = 'timeline_tasks';

  static const List<SampleItem> sampleItems = [
    // 12 Ay Önce
    (title: 'Düğün mekanı araştır ve rezervasyon yap', category: 'mekan', period: '12 Ay Önce', daysBefore: 365),
    (title: 'Fotoğrafçı ve kameraman araştır', category: 'fotografci', period: '12 Ay Önce', daysBefore: 365),
    (title: 'Düğün bütçesini planla', category: 'organizasyon', period: '12 Ay Önce', daysBefore: 365),
    (title: 'Davet listesini oluşturmaya başla', category: 'davetli', period: '12 Ay Önce', daysBefore: 365),
    // 9 Ay Önce
    (title: 'Gelinlik denemelerine başla', category: 'gelinlik', period: '9 Ay Önce', daysBefore: 270),
    (title: 'Catering firmaları araştır ve tadım yap', category: 'catering', period: '9 Ay Önce', daysBefore: 270),
    (title: 'Düğün müziği / DJ araştır', category: 'muzik', period: '9 Ay Önce', daysBefore: 270),
    (title: 'Balayı destinasyonu araştır', category: 'organizasyon', period: '9 Ay Önce', daysBefore: 270),
    // 6 Ay Önce
    (title: 'Gelinlik siparişini ver', category: 'gelinlik', period: '6 Ay Önce', daysBefore: 180),
    (title: 'Davetiye tasarımını hazırla', category: 'davetli', period: '6 Ay Önce', daysBefore: 180),
    (title: 'Çiçekçi ve dekorasyon firmalarını belirle', category: 'mekan', period: '6 Ay Önce', daysBefore: 180),
    (title: 'Catering ile menüyü kesinleştir', category: 'catering', period: '6 Ay Önce', daysBefore: 180),
    // 3 Ay Önce
    (title: 'Davetiyeleri gönder', category: 'davetli', period: '3 Ay Önce', daysBefore: 90),
    (title: 'Gelinlik provası yaptır', category: 'gelinlik', period: '3 Ay Önce', daysBefore: 90),
    (title: 'Düğün töreninin akışını planla', category: 'organizasyon', period: '3 Ay Önce', daysBefore: 90),
    (title: 'Oturma düzeni taslağını oluştur', category: 'davetli', period: '3 Ay Önce', daysBefore: 90),
    // 1 Ay Önce
    (title: 'RSVP yanıtlarını kontrol et', category: 'davetli', period: '1 Ay Önce', daysBefore: 30),
    (title: 'Gelinlik son provası ve teslimatı', category: 'gelinlik', period: '1 Ay Önce', daysBefore: 30),
    (title: 'Tedarikçilerle son detayları onayla', category: 'organizasyon', period: '1 Ay Önce', daysBefore: 30),
    (title: 'Nikah / düğün belgelerini hazırla', category: 'organizasyon', period: '1 Ay Önce', daysBefore: 30),
    // 1 Hafta Önce
    (title: 'Tüm hazırlıkları son kez kontrol et', category: 'organizasyon', period: '1 Hafta Önce', daysBefore: 7),
    (title: 'Saç ve makyaj randevusunu onayla', category: 'gelinlik', period: '1 Hafta Önce', daysBefore: 7),
    (title: 'Misafirlere hatırlatma mesajı gönder', category: 'davetli', period: '1 Hafta Önce', daysBefore: 7),
    (title: 'Ödenecek son faturaları öde', category: 'organizasyon', period: '1 Hafta Önce', daysBefore: 7),
  ];

  Future<List<TimelineTask>> fetchByWedding(String weddingId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('wedding_id', weddingId)
        .order('due_date', ascending: true, nullsFirst: false);
    return rows.map(TimelineTask.fromJson).toList();
  }

  Future<TimelineTask> create(TimelineTask task) async {
    final row =
        await _client.from(_table).insert(task.toInsert()).select().single();
    return TimelineTask.fromJson(row);
  }

  /// Yalnızca null olmayan parametreler Supabase'e gönderilir.
  /// toggle için: update(id, isCompleted: true)
  /// tam düzenleme için: update(id, title: ..., category: ..., ...)
  Future<TimelineTask> update(
    String id, {
    bool? isCompleted,
    String? title,
    TaskCategory? category,
    // null → alan dokunulmaz; '' → DB'de null yap (temizle)
    String? notes,
    DateTime? dueDate,
    bool removeDueDate = false,
  }) async {
    final payload = <String, dynamic>{};
    if (isCompleted != null) payload['is_completed'] = isCompleted;
    if (title != null) payload['title'] = title;
    if (category != null) payload['category'] = category.wire;
    if (notes != null) payload['notes'] = notes.isEmpty ? null : notes;
    if (removeDueDate) {
      payload['due_date'] = null;
    } else if (dueDate != null) {
      payload['due_date'] = dueDate.toIso8601String().split('T').first;
    }
    final row = await _client
        .from(_table)
        .update(payload)
        .eq('id', id)
        .select()
        .single();
    return TimelineTask.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
