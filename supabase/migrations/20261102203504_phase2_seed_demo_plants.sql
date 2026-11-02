-- ============================================================================
-- Fase 2 (4/4): Seed Pembangkit DEMO (is_demo = true, nama [DEMO], koordinat fiktif)
-- ============================================================================
-- PENTING: Seluruh baris di file ini adalah DATA DEMO FIKTIF untuk pengujian UI.
-- Kapasitas dan operator dikosongkan (null), status = 'unknown', is_demo = true,
-- dan koordinat menggunakan angka bulat fiktif (bukan lokasi pembangkit nyata).

-- Bersihkan data demo lama bila file seed dijalankan ulang
delete from public.power_plants where is_demo = true;

insert into public.power_plants (
  category_id,
  name,
  description,
  province,
  city,
  latitude,
  longitude,
  capacity_mw,
  operational_status,
  operator_name,
  image_url,
  source_url,
  verified_at,
  is_demo,
  is_published
)
values
  (
    (select id from public.energy_categories where slug = 'solar'),
    '[DEMO] Titik Simulasi Energi Surya A',
    'Data simulasi fiktif untuk menguji tampilan marker dan kartu kategori Solar Energy (PLTS) pada peta pengembangan EduEarth.',
    'Wilayah Simulasi Barat',
    'Zona Uji 01',
    -2.0000,
    105.0000,
    null,
    'unknown',
    null,
    null,
    null,
    null,
    true,
    true
  ),
  (
    (select id from public.energy_categories where slug = 'hydro'),
    '[DEMO] Titik Simulasi Energi Air B',
    'Data simulasi fiktif untuk menguji tampilan marker dan kartu kategori Hydropower (PLTA) pada peta pengembangan EduEarth.',
    'Wilayah Simulasi Tengah',
    'Zona Uji 02',
    -3.0000,
    112.0000,
    null,
    'unknown',
    null,
    null,
    null,
    null,
    true,
    true
  ),
  (
    (select id from public.energy_categories where slug = 'wind'),
    '[DEMO] Titik Simulasi Energi Angin C',
    'Data simulasi fiktif untuk menguji tampilan marker dan kartu kategori Wind Energy (PLTB) pada peta pengembangan EduEarth.',
    'Wilayah Simulasi Selatan',
    'Zona Uji 03',
    -5.0000,
    118.0000,
    null,
    'unknown',
    null,
    null,
    null,
    null,
    true,
    true
  ),
  (
    (select id from public.energy_categories where slug = 'geothermal'),
    '[DEMO] Titik Simulasi Panas Bumi D',
    'Data simulasi fiktif untuk menguji tampilan marker dan kartu kategori Geothermal Energy (PLTP) pada peta pengembangan EduEarth.',
    'Wilayah Simulasi Tengah',
    'Zona Uji 04',
    -7.0000,
    110.0000,
    null,
    'unknown',
    null,
    null,
    null,
    null,
    true,
    true
  ),
  (
    (select id from public.energy_categories where slug = 'bioenergy'),
    '[DEMO] Titik Simulasi Bioenergi E',
    'Data simulasi fiktif untuk menguji tampilan marker dan kartu kategori Bioenergy (PLTBm/PLTBg) pada peta pengembangan EduEarth.',
    'Wilayah Simulasi Timur',
    'Zona Uji 05',
    -4.0000,
    125.0000,
    null,
    'unknown',
    null,
    null,
    null,
    null,
    true,
    true
  );

