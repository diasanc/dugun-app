import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Supabase istemcisinin tek dogruluk kaynagi.
///
/// [init] uygulama acilisinda (main) bir kez cagrilir. Sonrasinda her yerden
/// [client] uzerinden erisilir. Servisler dogrudan Supabase.instance yerine
/// bu getter'i kullanir -> baglanti noktasi tek yerde (DRY), test edilebilir.
class SupabaseInit {
  const SupabaseInit._();

  /// Uygulama acilisinda bir kez cagrilir.
  static Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey, // ignore: deprecated_member_use
    );
  }

  /// Global Supabase istemcisi.
  static SupabaseClient get client => Supabase.instance.client;
}
