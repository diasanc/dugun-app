-- =============================================================
-- Migration: 20260626_init_core_tables
-- Sprint 1 / Adim 1: Cekirdek tablolar + tekrar kullanilabilir trigger'lar
--   - wedding_role (enum)
--   - weddings
--   - wedding_members
--   - set_updated_at() : updated_at otomatik guncelleme (tekrar kullanilabilir)
--   - handle_new_wedding() : owner'i otomatik admin uyesi yapar
-- NOT: RLS politikalari bir sonraki adimda eklenecek.
-- =============================================================


-- -------------------------------------------------------------
-- 0) Tekrar kullanilabilir trigger fonksiyonu: updated_at
--    Her tabloda BEFORE UPDATE olarak baglanir; satir guncellenince
--    updated_at alanini otomatik now() yapar. Tek dogruluk kaynagi.
-- -------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

comment on function public.set_updated_at() is
    'BEFORE UPDATE trigger fonksiyonu: updated_at alanini otomatik now() yapar.';


-- -------------------------------------------------------------
-- 1) Rol tipi: bir kullanicinin belirli bir dugundeki yetki seviyesi
-- -------------------------------------------------------------
create type public.wedding_role as enum ('admin', 'editor', 'viewer');


-- -------------------------------------------------------------
-- 2) weddings : Her satir tek bir dugun etkinligini temsil eder.
--    Tum verinin (butce, davetli, masa...) baglanacagi kok tablo.
-- -------------------------------------------------------------
create table public.weddings (
    id              uuid        primary key default gen_random_uuid(),

    -- Dugunu olusturan/sahibi olan kullanici (Admin).
    -- Kullanici silinirse dugun de silinsin.
    owner_id        uuid        not null references auth.users (id) on delete cascade,

    -- Onboarding'de girilen baslik (or. "Ayse & Mehmet"). Opsiyonel.
    title           text,

    -- Dugun tarihi opsiyonel ("Atla" denebilir). Saat onemli degil -> date.
    wedding_date    date,

    -- Toplam butce. TL bazli; para icin daima numeric (float ASLA).
    total_budget    numeric(12, 2),
    currency        text        not null default 'TRY',

    -- Ortak Erisim icin "Dugun Kodu". Sistemde benzersiz olmali.
    join_code       text        unique,

    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now()
);

comment on table public.weddings is
    'Her satir tek bir dugun etkinligini temsil eder (MVP: ciftin tek dugunu).';

-- updated_at otomatik guncelleme
create trigger trg_weddings_set_updated_at
    before update on public.weddings
    for each row
    execute function public.set_updated_at();


-- -------------------------------------------------------------
-- 3) wedding_members : Kullanici-dugun uyelik koprusu (M:N).
--    Rol (admin/editor/viewer) burada tutulur. Admin de burada bir satirdir.
-- -------------------------------------------------------------
create table public.wedding_members (
    id              uuid                primary key default gen_random_uuid(),

    -- Hangi dugun. Dugun silinirse uyelikler de silinsin.
    wedding_id      uuid                not null references public.weddings (id) on delete cascade,

    -- Hangi kullanici. Kullanici silinirse uyeligi de silinsin.
    user_id         uuid                not null references auth.users (id) on delete cascade,

    -- Yetki seviyesi. Davet edilen biri icin varsayilan en kisitli rol: viewer.
    role            public.wedding_role not null default 'viewer',

    created_at      timestamptz         not null default now(),

    -- Ayni kullanici ayni dugunde yalnizca BIR kez yer alabilir.
    constraint uq_wedding_members_wedding_user unique (wedding_id, user_id)
);

comment on table public.wedding_members is
    'Kullanici-dugun uyelik koprusu. Rol (admin/editor/viewer) burada tutulur.';

-- FK uzerinden sik sorgular icin index'ler.
create index idx_wedding_members_wedding_id on public.wedding_members (wedding_id);
create index idx_wedding_members_user_id    on public.wedding_members (user_id);


-- -------------------------------------------------------------
-- 4) handle_new_wedding : Bir dugun olusturulunca owner'i otomatik
--    olarak wedding_members tablosuna 'admin' roluyle ekler.
--    Boylece "owner = admin uye" kurali tek dogruluk kaynaginda (DB) kalir.
-- -------------------------------------------------------------
create or replace function public.handle_new_wedding()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.wedding_members (wedding_id, user_id, role)
    values (new.id, new.owner_id, 'admin')
    on conflict (wedding_id, user_id) do nothing;
    return new;
end;
$$;

comment on function public.handle_new_wedding() is
    'AFTER INSERT trigger fonksiyonu: yeni dugunun owner_id''sini admin uye olarak ekler.';

create trigger trg_weddings_add_owner_as_admin
    after insert on public.weddings
    for each row
    execute function public.handle_new_wedding();
