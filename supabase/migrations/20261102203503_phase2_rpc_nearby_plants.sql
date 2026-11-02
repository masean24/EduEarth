-- ============================================================================
-- Fase 2 (3/4): RPC nearby_plants (Pencarian Pembangkit Terdekat dengan PostGIS)
-- ============================================================================

create or replace function public.nearby_plants(
  lat double precision,
  lng double precision,
  radius_m integer,
  category_slug text default null
)
returns table (
  id uuid,
  category_id uuid,
  category_slug text,
  category_name text,
  category_short_code text,
  name text,
  description text,
  province text,
  city text,
  latitude double precision,
  longitude double precision,
  capacity_mw numeric,
  operational_status text,
  operator_name text,
  image_url text,
  source_url text,
  verified_at timestamptz,
  is_demo boolean,
  is_published boolean,
  created_at timestamptz,
  updated_at timestamptz,
  distance_meters double precision
)
language sql
stable
set search_path = public, extensions
as $$
  select
    p.id,
    p.category_id,
    c.slug as category_slug,
    c.name as category_name,
    c.short_code as category_short_code,
    p.name,
    p.description,
    p.province,
    p.city,
    p.latitude,
    p.longitude,
    p.capacity_mw,
    p.operational_status,
    p.operator_name,
    p.image_url,
    p.source_url,
    p.verified_at,
    p.is_demo,
    p.is_published,
    p.created_at,
    p.updated_at,
    ST_Distance(
      p.geog,
      ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
    ) as distance_meters
  from public.power_plants p
  join public.energy_categories c on c.id = p.category_id
  where p.is_published = true
    and ST_DWithin(
      p.geog,
      ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography,
      radius_m
    )
    and (
      nearby_plants.category_slug is null
      or c.slug = nearby_plants.category_slug
    )
  order by distance_meters asc;
$$;

