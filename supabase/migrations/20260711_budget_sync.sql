-- =============================================================
-- Migration: 20260711_budget_sync
-- total_budget sutunu weddings tablosunda init migration'dan beri mevcut.
-- Bu migration sutun yorumunu guncelliyor ve butce senkronizasyonunu belgeliyor.
-- =============================================================

comment on column public.weddings.total_budget is
  'Kullanicinin dugunu icin belirledigi toplam butce tavani (TRY). '
  'Onboarding seciminden veya profil ayarlarindan guncellenir. '
  'Onboarding aralik stringleri: 500.000 TL alti -> 500000, '
  '500.000-1.000.000 -> 1000000, 1.000.000-2.000.000 -> 2000000, '
  '2.000.000 uzeri -> 2000000, Henuz bilmiyorum -> null.';
