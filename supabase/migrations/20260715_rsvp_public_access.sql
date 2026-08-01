-- =============================================================
-- Migration: 20260715_rsvp_public_access
-- RSVP formu icin anonim (unauthenticated) kullanicilara:
--   - weddings: id/title/wedding_date okuma
--   - guests: davetli kaydı ekleme (RSVP gonderimi)
-- =============================================================

do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'weddings' and policyname = 'weddings_anon_rsvp_select'
  ) then
    create policy "weddings_anon_rsvp_select"
      on public.weddings for select to anon
      using (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'guests' and policyname = 'guests_anon_rsvp_insert'
  ) then
    create policy "guests_anon_rsvp_insert"
      on public.guests for insert to anon
      with check (true);
  end if;
end $$;
