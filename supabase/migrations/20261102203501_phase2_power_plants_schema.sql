-- ============================================================================
-- Fase 2 (1/4): Skema Tabel power_plants (PostGIS, geog generated, index, trigger)
-- ============================================================================

create table if not exists public.power_plants (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.energy_categories (id) on delete restrict,
  name text not null,
  description text not null,
  province text not null,
  city text,
  latitude double precision not null,
  longitude double precision not null,
  geog geography(Point, 4326) generated always as (
    ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
  ) stored,
  capacity_mw numeric,
  operational_status text not null default 'unknown'
    check (operational_status in ('operating', 'construction', 'planned', 'unknown')),
  operator_name text,
  image_url text,
  source_url text,
  verified_at timestamptz,
  is_demo boolean not null default false,
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Index minimal sesuai docs/04_DATABASE.md
create index if not exists idx_power_plants_category_id
  on public.power_plants (category_id);

create index if not exists idx_power_plants_geog
  on public.power_plants using gist (geog);

create index if not exists idx_power_plants_is_published
  on public.power_plants (is_published);

-- Trigger updated_at
drop trigger if exists trg_power_plants_updated_at on public.power_plants;
create trigger trg_power_plants_updated_at
  before update on public.power_plants
  for each row
  execute function public.set_updated_at();

