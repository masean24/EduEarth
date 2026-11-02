-- ============================================================================
-- Fase 1 (2/4): Fungsi Trigger (set_updated_at & handle_new_user)
-- ============================================================================

-- 1. Trigger generik set_updated_at()
create or replace function public.set_updated_at()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_energy_categories_updated_at on public.energy_categories;
create trigger trg_energy_categories_updated_at
  before update on public.energy_categories
  for each row
  execute function public.set_updated_at();

drop trigger if exists trg_user_profiles_updated_at on public.user_profiles;
create trigger trg_user_profiles_updated_at
  before update on public.user_profiles
  for each row
  execute function public.set_updated_at();

-- 2. Trigger handle_new_user() untuk membuat baris user_profiles otomatis saat signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_display_name text;
begin
  v_display_name := coalesce(
    nullif(trim(new.raw_user_meta_data->>'display_name'), ''),
    split_part(new.email, '@', 1)
  );

  insert into public.user_profiles (id, display_name, avatar_url)
  values (
    new.id,
    v_display_name,
    nullif(trim(new.raw_user_meta_data->>'avatar_url'), '')
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

