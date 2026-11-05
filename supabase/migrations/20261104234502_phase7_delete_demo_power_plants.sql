-- ============================================================================
-- Migrasi Tahap 7 (2/2): Hapus Baris Pembangkit Demo (`is_demo = true`)
-- PENTING: Jangan dijalankan otomatis sebelum memverifikasi hasil impor 128
-- pembangkit nyata pada 20261104234501_phase7_import_real_power_plants.sql.
-- ============================================================================

begin;

delete from public.power_plants
where is_demo = true;

commit;

-- Verifikasi bahwa tidak ada lagi baris is_demo = true dan tersisa 128 baris nyata:
select
  count(*) filter (where is_demo = true)::int as remaining_demo_rows,
  count(*) filter (where is_demo = false)::int as real_plant_rows
from public.power_plants;

