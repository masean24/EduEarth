-- ============================================================================
-- Fase 3 (1/3): Skema Tabel learning_materials & bookmarks + Index + Trigger
-- ============================================================================

-- 1. Tabel learning_materials
create table if not exists public.learning_materials (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.energy_categories (id) on delete restrict,
  title text not null,
  slug text not null unique,
  summary text not null,
  content_md text not null,
  cover_image_url text,
  read_minutes integer not null default 5 check (read_minutes > 0),
  difficulty text not null default 'beginner'
    check (difficulty in ('beginner', 'intermediate', 'advanced')),
  sort_order integer not null default 0,
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_learning_materials_category_sort
  on public.learning_materials (category_id, sort_order);

create index if not exists idx_learning_materials_is_published
  on public.learning_materials (is_published);

drop trigger if exists trg_learning_materials_updated_at on public.learning_materials;
create trigger trg_learning_materials_updated_at
  before update on public.learning_materials
  for each row
  execute function public.set_updated_at();

-- 2. Tabel bookmarks
-- Setiap baris tepat merujuk ke 1 target (material_id ATAU plant_id) via num_nonnulls = 1
create table if not exists public.bookmarks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  material_id uuid references public.learning_materials (id) on delete cascade,
  plant_id uuid references public.power_plants (id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint chk_bookmarks_single_target check (num_nonnulls(material_id, plant_id) = 1)
);

-- Index dan partial unique index sesuai docs/04_DATABASE.md
create index if not exists idx_bookmarks_user_id
  on public.bookmarks (user_id);

create unique index if not exists uq_bookmarks_user_material
  on public.bookmarks (user_id, material_id)
  where material_id is not null;

create unique index if not exists uq_bookmarks_user_plant
  on public.bookmarks (user_id, plant_id)
  where plant_id is not null;

