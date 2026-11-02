-- ============================================================================
-- Fase 1 (1/4): Ekstensi & Skema Tabel Dasar (energy_categories, user_profiles)
-- ============================================================================

-- Aktifkan ekstensi wajib sesuai docs/04_DATABASE.md
create extension if not exists "pgcrypto";
create extension if not exists "postgis";

-- 1. Tabel energy_categories
create table if not exists public.energy_categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug in ('solar', 'hydro', 'wind', 'geothermal', 'bioenergy')),
  name text not null,
  short_code text not null,
  description text not null,
  icon text not null,
  color_hex text not null,
  comparison jsonb not null default '{}'::jsonb,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_energy_categories_sort_order
  on public.energy_categories (sort_order);

-- 2. Tabel user_profiles
create table if not exists public.user_profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

