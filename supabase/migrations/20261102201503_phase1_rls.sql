-- ============================================================================
-- Fase 1 (3/4): Kebijakan Row Level Security (RLS)
-- ============================================================================

-- Aktifkan RLS di semua tabel
alter table public.energy_categories enable row level security;
alter table public.user_profiles enable row level security;

-- 1. Policy untuk energy_categories:
-- SELECT publik (anon + authenticated), TIDAK ADA policy INSERT/UPDATE/DELETE untuk client.
drop policy if exists "energy_categories_select_public" on public.energy_categories;
create policy "energy_categories_select_public"
  on public.energy_categories
  for select
  to anon, authenticated
  using (true);

-- 2. Policy untuk user_profiles:
-- SELECT & UPDATE hanya milik sendiri Menggunakan (select auth.uid()) demi performa.
-- INSERT dilakukan oleh trigger handle_new_user (security definer).
drop policy if exists "user_profiles_select_own" on public.user_profiles;
create policy "user_profiles_select_own"
  on public.user_profiles
  for select
  to authenticated
  using (id = (select auth.uid()));

drop policy if exists "user_profiles_update_own" on public.user_profiles;
create policy "user_profiles_update_own"
  on public.user_profiles
  for update
  to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

