import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_init.dart';
import '../models/moodboard_item.dart';

class MoodboardService {
  MoodboardService({SupabaseClient? client})
      : _client = client ?? SupabaseInit.client;

  final SupabaseClient _client;

  static const String _table = 'moodboard_items';
  static const String _bucket = 'moodboard-photos';

  Future<List<MoodboardItem>> fetchByWedding(String weddingId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('wedding_id', weddingId)
        .order('sort_order', ascending: true);
    return rows.map(MoodboardItem.fromJson).toList();
  }

  Future<MoodboardItem> create(MoodboardItem item) async {
    final row =
        await _client.from(_table).insert(item.toInsert()).select().single();
    return MoodboardItem.fromJson(row);
  }

  Future<MoodboardItem> update(MoodboardItem item) async {
    final row = await _client
        .from(_table)
        .update(item.toUpdate())
        .eq('id', item.id)
        .select()
        .single();
    return MoodboardItem.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  Future<void> updateOrders(List<MoodboardItem> items) async {
    await Future.wait([
      for (var i = 0; i < items.length; i++)
        _client.from(_table).update({'sort_order': i}).eq('id', items[i].id),
    ]);
  }

  /// Fotoğrafı Supabase Storage'a yükler, public URL döner.
  Future<String> uploadPhoto(String weddingId, File file) async {
    final ext = file.path.split('.').last;
    final path =
        '$weddingId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage.from(_bucket).upload(path, file);
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  /// Storage'daki fotoğrafı siler.
  Future<void> deletePhoto(String publicUrl) async {
    final uri = Uri.parse(publicUrl);
    final segments = uri.pathSegments;
    final bucketIndex = segments.indexOf(_bucket);
    if (bucketIndex == -1) return;
    final path = segments.sublist(bucketIndex + 1).join('/');
    await _client.storage.from(_bucket).remove([path]);
  }
}
