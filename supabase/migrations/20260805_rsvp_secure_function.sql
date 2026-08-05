-- =============================================================
-- Migration: 20260805_rsvp_secure_function
-- RSVP akışını güvenli bir RPC fonksiyonu üzerinden yürütür.
--
-- Sorun: weddings_anon_rsvp_select politikası join_code IS NOT NULL
-- koşuluna bağlıydı; join_code henüz üretilmemiş düğünlerde RSVP
-- linki "düğün bulunamadı" hatası veriyordu.
--
-- Çözüm:
--   1) Anon'un weddings tablosuna doğrudan SELECT erişimini kapat.
--   2) SECURITY DEFINER fonksiyonla yalnızca id/title/wedding_date
--      dönen güvenli bir RPC uç noktası sun.
--   3) guests_anon_rsvp_insert politikasını join_code koşulundan
--      arındır; düğünün var olması yeterli olsun.
-- =============================================================


-- -------------------------------------------------------------
-- 1) Anon'un weddings tablosuna doğrudan erişimini tamamen kapat
-- -------------------------------------------------------------
drop policy if exists "weddings_anon_rsvp_select" on public.weddings;


-- -------------------------------------------------------------
-- 2) Güvenli RSVP sorgulama fonksiyonu
--    SECURITY DEFINER: RLS'i atlar, sadece gerekli alanları döner.
--    search_path sabitleniyor: schema injection saldırılarına karşı.
-- -------------------------------------------------------------
create or replace function public.get_wedding_for_rsvp(p_wedding_id uuid)
returns table (id uuid, title text, wedding_date date)
language sql
security definer
set search_path = public, pg_temp
stable
as $$
    select w.id, w.title, w.wedding_date
    from public.weddings w
    where w.id = p_wedding_id;
$$;

-- Sadece anon ve authenticated çağırabilir; diğer roller erişemez
revoke all on function public.get_wedding_for_rsvp(uuid) from public;
grant execute on function public.get_wedding_for_rsvp(uuid) to anon, authenticated;


-- -------------------------------------------------------------
-- 3) guests_anon_rsvp_insert: join_code koşulunu kaldır
--    Düğünün var olması yeterli; join_code artık şart değil.
-- -------------------------------------------------------------
drop policy if exists "guests_anon_rsvp_insert" on public.guests;

create policy "guests_anon_rsvp_insert"
    on public.guests
    for insert
    to anon
    with check (
        exists (
            select 1
            from public.weddings w
            where w.id = wedding_id
        )
    );
