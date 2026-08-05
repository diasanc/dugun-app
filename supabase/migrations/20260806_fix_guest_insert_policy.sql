-- =============================================================
-- Migration: 20260805_fix_guest_insert_policy
-- Sorun: guests_anon_rsvp_insert politikasının WITH CHECK alt sorgusu
--   weddings tablosunu sorguluyordu; anon'un weddings'e doğrudan
--   erişimi kapalı olduğu için alt sorgu boş dönüyor, insert
--   reddediliyordu.
-- Çözüm: SECURITY DEFINER fonksiyon RLS'i atlayarak varlık kontrolü
--   yapar; politika bu fonksiyonu çağırır.
-- =============================================================

create or replace function public.wedding_exists(p_wedding_id uuid)
returns boolean
language sql
security definer
set search_path = public, pg_temp
stable
as $$
    select exists (select 1 from public.weddings where id = p_wedding_id);
$$;

revoke all on function public.wedding_exists(uuid) from public;
grant execute on function public.wedding_exists(uuid) to anon, authenticated;

drop policy if exists "guests_anon_rsvp_insert" on public.guests;

create policy "guests_anon_rsvp_insert"
    on public.guests
    for insert
    to anon
    with check ( public.wedding_exists(wedding_id) );
