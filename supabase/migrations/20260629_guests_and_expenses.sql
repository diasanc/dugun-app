-- =============================================================
-- Migration: 20260629_guests_and_expenses
-- Sprint 1 / Adim 3: Davetliler + Butce (gider kalemleri) + RLS
--   - guest_side / rsvp_status / expense_category (enum'lar)
--   - guests
--   - expenses
--   - is_wedding_editor() : admin VEYA editor mi? (yazma yetkisi icin)
--   - RLS: SELECT -> tum uyeler (viewer dahil) ; INSERT/UPDATE/DELETE -> admin+editor
-- NOT: total_budget weddings kok tablosunda; burada kalem kalem giderler tutulur.
--      Masa/yerlesim (table_id) bu migration'a DAHIL DEGIL; ayri adimda gelecek.
-- =============================================================


-- -------------------------------------------------------------
-- 0) Yazma yetkisi yardimcisi: admin VEYA editor mi?
--    is_wedding_member (viewer dahil) salt-okur SELECT icin yeterli;
--    yazma politikalari icin editor seviyesini de kapsayan bu fonksiyonu
--    kullaniriz. SECURITY DEFINER -> wedding_members RLS dongusu kirilir.
-- -------------------------------------------------------------
create or replace function public.is_wedding_editor(p_wedding_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
    select exists (
        select 1
        from public.wedding_members wm
        where wm.wedding_id = p_wedding_id
          and wm.user_id = auth.uid()
          and wm.role in ('admin', 'editor')
    );
$$;

comment on function public.is_wedding_editor(uuid) is
    'auth.uid() verilen dugunde admin VEYA editor mi? Yazma RLS politikalarinda kullanilir.';


-- -------------------------------------------------------------
-- 1) Enum tipleri
-- -------------------------------------------------------------

-- Davetlinin hangi tarafa ait oldugu (gelin / damat / ikisi de).
create type public.guest_side as enum ('bride', 'groom', 'both');

-- Davetlinin katilim durumu (RSVP). Varsayilan: henuz yanit yok.
create type public.rsvp_status as enum ('pending', 'attending', 'declined', 'maybe');

-- Gider kalemi kategorisi. UI'da filtre/gruplama icin sabit kume.
create type public.expense_category as enum (
    'venue',        -- mekan
    'catering',     -- yemek / ikram
    'photo_video',  -- foto / video
    'attire',       -- kiyafet
    'music',        -- muzik / DJ
    'flowers',      -- cicek / dekor
    'invitation',   -- davetiye
    'transport',    -- ulasim
    'other'         -- diger
);


-- -------------------------------------------------------------
-- 2) guests : Bir dugune ait davetliler.
-- -------------------------------------------------------------
create table public.guests (
    id              uuid                primary key default gen_random_uuid(),

    -- Hangi dugun. Dugun silinirse davetliler de silinsin.
    wedding_id      uuid                not null references public.weddings (id) on delete cascade,

    full_name       text                not null,
    phone           text,
    email           text,

    -- Gelin/damat tarafi. Opsiyonel (girilmeyebilir).
    side            public.guest_side,

    -- Katilim durumu. Yeni eklenende varsayilan: pending.
    rsvp_status     public.rsvp_status  not null default 'pending',

    -- Yaninda getirecegi ek kisi sayisi (+1'ler). Negatif olamaz.
    companion_count integer             not null default 0
                        constraint chk_guests_companion_nonneg check (companion_count >= 0),

    -- Serbest etiket: "Aile", "Is", "Universite" gibi gruplama.
    group_label     text,

    notes           text,

    created_at      timestamptz         not null default now(),
    updated_at      timestamptz         not null default now()
);

comment on table public.guests is
    'Bir dugune ait davetliler. RSVP durumu ve +1 sayisi burada tutulur.';

-- FK uzerinden sik sorgular icin index.
create index idx_guests_wedding_id on public.guests (wedding_id);

-- updated_at otomatik guncelleme (cekirdek migration'daki ortak fonksiyon).
create trigger trg_guests_set_updated_at
    before update on public.guests
    for each row
    execute function public.set_updated_at();


-- -------------------------------------------------------------
-- 3) expenses : Bir dugune ait gider kalemleri (butce detayi).
--    weddings.total_budget toplam hedef; burada kalem kalem harcamalar.
-- -------------------------------------------------------------
create table public.expenses (
    id                uuid                    primary key default gen_random_uuid(),

    -- Hangi dugun. Dugun silinirse giderler de silinsin.
    wedding_id        uuid                    not null references public.weddings (id) on delete cascade,

    title             text                    not null,
    category          public.expense_category not null default 'other',

    -- Para alanlari daima numeric (float ASLA). Negatif olamaz.
    estimated_amount  numeric(12, 2)
                          constraint chk_expenses_estimated_nonneg check (estimated_amount >= 0),
    actual_amount     numeric(12, 2)
                          constraint chk_expenses_actual_nonneg check (actual_amount >= 0),

    -- Odendi mi? Varsayilan: hayir.
    is_paid           boolean                 not null default false,

    -- Opsiyonel son odeme tarihi.
    due_date          date,

    notes             text,

    created_at        timestamptz             not null default now(),
    updated_at        timestamptz             not null default now()
);

comment on table public.expenses is
    'Bir dugune ait gider kalemleri (tahmini/gerceklesen tutar, odeme durumu).';

create index idx_expenses_wedding_id on public.expenses (wedding_id);

create trigger trg_expenses_set_updated_at
    before update on public.expenses
    for each row
    execute function public.set_updated_at();


-- -------------------------------------------------------------
-- 4) RLS: iki tablo da ayni deseni izler.
--    SELECT -> tum uyeler (viewer dahil) : is_wedding_member
--    INSERT/UPDATE/DELETE -> admin + editor : is_wedding_editor
-- -------------------------------------------------------------
alter table public.guests   enable row level security;
alter table public.expenses enable row level security;


-- ---- guests politikalari ----
create policy "guests_select_members"
    on public.guests
    for select
    to authenticated
    using ( public.is_wedding_member(wedding_id) );

create policy "guests_insert_editor"
    on public.guests
    for insert
    to authenticated
    with check ( public.is_wedding_editor(wedding_id) );

create policy "guests_update_editor"
    on public.guests
    for update
    to authenticated
    using      ( public.is_wedding_editor(wedding_id) )
    with check ( public.is_wedding_editor(wedding_id) );

create policy "guests_delete_editor"
    on public.guests
    for delete
    to authenticated
    using ( public.is_wedding_editor(wedding_id) );


-- ---- expenses politikalari ----
create policy "expenses_select_members"
    on public.expenses
    for select
    to authenticated
    using ( public.is_wedding_member(wedding_id) );

create policy "expenses_insert_editor"
    on public.expenses
    for insert
    to authenticated
    with check ( public.is_wedding_editor(wedding_id) );

create policy "expenses_update_editor"
    on public.expenses
    for update
    to authenticated
    using      ( public.is_wedding_editor(wedding_id) )
    with check ( public.is_wedding_editor(wedding_id) );

create policy "expenses_delete_editor"
    on public.expenses
    for delete
    to authenticated
    using ( public.is_wedding_editor(wedding_id) );
