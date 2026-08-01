-- RSVP HTML formunu serve etmek icin public storage bucket
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'rsvp-pages',
    'rsvp-pages',
    true,
    524288,  -- 512 KB
    array['text/html']
)
on conflict (id) do nothing;
