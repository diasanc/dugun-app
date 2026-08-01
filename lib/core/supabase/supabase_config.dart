/// Supabase bulut projesi baglanti bilgileri.
///
/// Publishable (anon) key gizli DEGILDIR; istemcide kullanilmak uzere
/// tasarlanmistir. Asil guvenlik RLS politikalari ile saglanir
/// (bkz. supabase/migrations/*). Service_role key ve DB sifresi BURADA YOKTUR.
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = 'https://vwcochhjzdgiiczdvico.supabase.co';

  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3Y29jaGhqemRnaWljemR2aWNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI2NjU4NzMsImV4cCI6MjA5ODI0MTg3M30.yRMbjY6fU4GheyysEoZATyVItKZhc-1sbGozH7MHLGE';
}
