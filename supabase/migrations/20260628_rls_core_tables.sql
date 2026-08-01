-- =============================================================
-- Migration: 20260628_rls_core_tables
-- Sprint 1 / Adim 2: weddings ve wedding_members icin RLS
--   - RLS aktif edilir (varsayilan: her sey reddedilir)
--   - is_wedding_member() / is_wedding_admin() yardimci fonksiyonlari
--     (SECURITY DEFINER -> wedding_members uzerindeki sonsuz dongu kirilir)
--   - 8 politika (her tablo icin SELECT/INSERT/UPDATE/DELETE)
-- NOT: Freemium limitleri (Excel/PDF export, ortak erisim daveti) RLS'te
--      DEGIL; ileride ayri ele alinacak. Davetli sayisi limiti YOK.
-- =============================================================


-- -------------------------------------------------------------
-- 0) RLS'i aktif et. Politika tanimlanana kadar her sey reddedilir.
-- -------------------------------------------------------------
alter table public.weddings        enable row level security;
alter table public.wedding_members enable row level security;


-- -------------------------------------------------------------
-- 1) Yardimci fonksiyonlar (SECURITY DEFINER)
--    Politikalar wedding_members'i sorgularken kendi tablosuna donen
--    sonsuz dongu olusur. Bu fonksiyonlar RLS'i baypas ederek donguyu
--    kirar ve mantigi tek yerde toplar (DRY).
--    stable: ayni transaction icinde sonuc degismez -> planner optimizasyonu.
-- -------------------------------------------------------------

-- Giris yapan kullanici bu dugunun uyesi mi? (herhangi bir rol)
create or replace function public.is_wedding_member(p_wedding_id uuid)
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
    );
$$;

comment on function public.is_wedding_member(uuid) is
    'auth.uid() verilen dugunun uyesi mi? RLS politikalarinda kullanilir (dongu kirar).';

-- Giris yapan kullanici bu dugunun admini mi?
create or replace function public.is_wedding_admin(p_wedding_id uuid)
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
          and wm.role = 'admin'
    );
$$;

comment on function public.is_wedding_admin(uuid) is
    'auth.uid() verilen dugunun admini mi? RLS politikalarinda kullanilir (dongu kirar).';


-- -------------------------------------------------------------
-- 2) weddings politikalari
-- -------------------------------------------------------------

-- SELECT: dugunun herhangi bir uyesi (admin/editor/viewer) gorebilir.
create policy "weddings_select_members"
    on public.weddings
    for select
    to authenticated
    using ( public.is_wedding_member(id) );

-- INSERT: giris yapan kullanici ancak KENDISINI owner yaparak dugun olusturabilir.
-- (Owner trigger ile otomatik admin uye olur; o insert security definer ile RLS'i baypas eder.)
create policy "weddings_insert_self_owner"
    on public.weddings
    for insert
    to authenticated
    with check ( owner_id = auth.uid() );

-- UPDATE: sadece admin kok ayarlari (baslik/tarih/butce/join_code) degistirebilir.
create policy "weddings_update_admin"
    on public.weddings
    for update
    to authenticated
    using      ( public.is_wedding_admin(id) )
    with check ( public.is_wedding_admin(id) );

-- DELETE: sadece admin dugunu silebilir.
create policy "weddings_delete_admin"
    on public.weddings
    for delete
    to authenticated
    using ( public.is_wedding_admin(id) );


-- -------------------------------------------------------------
-- 3) wedding_members politikalari
-- -------------------------------------------------------------

-- SELECT: ayni dugunun uyeleri birbirini (ortak calisanlari) gorebilir.
create policy "wedding_members_select_members"
    on public.wedding_members
    for select
    to authenticated
    using ( public.is_wedding_member(wedding_id) );

-- INSERT: sadece admin yeni uye (editor/viewer) davet/ekleyebilir.
create policy "wedding_members_insert_admin"
    on public.wedding_members
    for insert
    to authenticated
    with check ( public.is_wedding_admin(wedding_id) );

-- UPDATE: sadece admin rol degistirebilir.
create policy "wedding_members_update_admin"
    on public.wedding_members
    for update
    to authenticated
    using      ( public.is_wedding_admin(wedding_id) )
    with check ( public.is_wedding_admin(wedding_id) );

-- DELETE: sadece admin uye cikarabilir.
create policy "wedding_members_delete_admin"
    on public.wedding_members
    for delete
    to authenticated
    using ( public.is_wedding_admin(wedding_id) );
