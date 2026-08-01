-- =============================================================
-- Migration: 20260801_rsvp_policy_hardening
-- 20260715_rsvp_public_access'teki iki gevşek anonim politikayı
-- daraltır. Eski politikalar drop edilerek yeniden oluşturulur.
-- =============================================================


-- -------------------------------------------------------------
-- 1) weddings: anon SELECT
--    Önceki: using (true)  →  tüm düğünler herkese açıktı
--    Yeni:   yalnızca join_code'u olan (RSVP'ye açık) düğünler
-- -------------------------------------------------------------
drop policy if exists "weddings_anon_rsvp_select" on public.weddings;

create policy "weddings_anon_rsvp_select"
    on public.weddings
    for select
    to anon
    using (join_code is not null);


-- -------------------------------------------------------------
-- 2) guests: anon INSERT
--    Önceki: with check (true)  →  herhangi bir wedding_id kabul ediliyordu
--    Yeni:   yalnızca join_code'u olan bir düğüne kayıt eklenebilir
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
              and w.join_code is not null
        )
    );
