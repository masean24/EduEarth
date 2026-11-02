-- ============================================================================
-- Fase 2 (2/4): Kebijakan Row Level Security (RLS) untuk power_plants
-- ============================================================================

alter table public.power_plants enable row level security;

-- Client (anon + authenticated) hanya boleh SELECT baris yang is_published = true.
-- Tidak ada policy INSERT/UPDATE/DELETE untuk client.
drop policy if exists "power_plants_select_published" on public.power_plants;
create policy "power_plants_select_published"
  on public.power_plants
  for select
  to anon, authenticated
  using (is_published = true);

