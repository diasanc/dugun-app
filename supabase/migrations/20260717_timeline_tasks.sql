-- =============================================================
-- Migration: 20260717_timeline_tasks
-- Sprint 5: Planlama Takvimi modülü
--   - timeline_tasks tablosu
--   - RLS: SELECT -> tüm üyeler | INSERT/UPDATE/DELETE -> admin+editor
-- =============================================================

create table public.timeline_tasks (
    id           uuid        primary key default gen_random_uuid(),
    wedding_id   uuid        not null references public.weddings(id) on delete cascade,
    title        text        not null,
    category     text        not null default 'diger',
    due_date     date,
    is_completed boolean     not null default false,
    is_template  boolean     not null default false,
    created_at   timestamptz not null default now(),
    updated_at   timestamptz not null default now()
);

create index idx_timeline_tasks_wedding_id on public.timeline_tasks (wedding_id);

create trigger trg_timeline_tasks_set_updated_at
    before update on public.timeline_tasks
    for each row
    execute function public.set_updated_at();

alter table public.timeline_tasks enable row level security;

create policy "timeline_select_members"
    on public.timeline_tasks
    for select
    to authenticated
    using ( public.is_wedding_member(wedding_id) );

create policy "timeline_insert_editor"
    on public.timeline_tasks
    for insert
    to authenticated
    with check ( public.is_wedding_editor(wedding_id) );

create policy "timeline_update_editor"
    on public.timeline_tasks
    for update
    to authenticated
    using      ( public.is_wedding_editor(wedding_id) )
    with check ( public.is_wedding_editor(wedding_id) );

create policy "timeline_delete_editor"
    on public.timeline_tasks
    for delete
    to authenticated
    using ( public.is_wedding_editor(wedding_id) );
