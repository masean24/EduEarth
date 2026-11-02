-- ============================================================================
-- Fase 3 (2/3): Kebijakan Row Level Security (RLS) untuk learning_materials & bookmarks
-- ============================================================================

alter table public.learning_materials enable row level security;
alter table public.bookmarks enable row level security;

-- 1. Policy learning_materials:
-- Publik (anon + authenticated) hanya boleh SELECT baris yang is_published = true.
-- Tidak ada policy INSERT/UPDATE/DELETE untuk client.
drop policy if exists "learning_materials_select_published" on public.learning_materials;
create policy "learning_materials_select_published"
  on public.learning_materials
  for select
  to anon, authenticated
  using (is_published = true);

-- 2. Policy bookmarks:
-- Hanya pengguna terautentikasi yang dapat SELECT, INSERT, dan DELETE bookmark miliknya sendiri.
-- Memakai (select auth.uid()) demi performa.
drop policy if exists "bookmarks_select_own" on public.bookmarks;
create policy "bookmarks_select_own"
  on public.bookmarks
  for select
  to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "bookmarks_insert_own" on public.bookmarks;
create policy "bookmarks_insert_own"
  on public.bookmarks
  for insert
  to authenticated
  with check (user_id = (select auth.uid()));

drop policy if exists "bookmarks_delete_own" on public.bookmarks;
create policy "bookmarks_delete_own"
  on public.bookmarks
  for delete
  to authenticated
  using (user_id = (select auth.uid()));

