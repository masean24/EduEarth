-- ============================================================================
-- Migrasi Fase 6 (Bagian 2): Notification Center (`notifications`)
-- Skema pengumuman publik satu arah (tanpa user_id dan tanpa is_read di DB).
-- Status baca per pengguna disimpan lokal di perangkat (shared_preferences).
-- ============================================================================

begin;

-- 1. Tabel notifications (hanya pengumuman publik)
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  category text not null default 'info'
    check (category in ('info', 'content', 'update')),
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_published_created_at
  on public.notifications (is_published, created_at desc);

-- 2. RLS: SELECT publik jika is_published = true; tidak ada policy tulis client
alter table public.notifications enable row level security;

drop policy if exists "notifications_select_published" on public.notifications;
create policy "notifications_select_published"
  on public.notifications
  for select
  to anon, authenticated
  using (is_published = true);

-- Tidak ada policy INSERT, UPDATE, atau DELETE untuk client.

-- 3. Seed hanya 1 pengumuman contoh, jelas berlabel [CONTOH]
insert into public.notifications (id, title, body, category, is_published)
values (
  '00000000-0000-0000-0000-000000000601',
  '[CONTOH] Selamat Datang di Pusat Informasi EduEarth',
  'Ini adalah pengumuman contoh untuk menguji fitur Notification Center pada aplikasi EduEarth. Pengumuman resmi mengenai pembaruan materi dan peta pembangkit akan ditampilkan di halaman ini.',
  'info',
  true
)
on conflict (id) do update
set
  title = excluded.title,
  body = excluded.body,
  category = excluded.category,
  is_published = excluded.is_published;

commit;

