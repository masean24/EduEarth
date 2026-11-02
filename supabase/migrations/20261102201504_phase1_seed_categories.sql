-- ============================================================================
-- Fase 1 (4/4): Seed 5 Kategori Energi Terbarukan (Tanpa Data Pembangkit)
-- ============================================================================

insert into public.energy_categories (
  slug,
  name,
  short_code,
  description,
  icon,
  color_hex,
  comparison,
  sort_order
)
values
  (
    'solar',
    'Solar Energy',
    'PLTS',
    'Energi surya memanfaatkan radiasi matahari melalui sel fotovoltaik untuk menghasilkan listrik bersih di wilayah tropis Indonesia.',
    'wb_sunny_rounded',
    '#FACC15',
    '{
      "source": "Sinar Matahari",
      "emission_level": "Sangat Rendah",
      "intermittency": "Bergantung cuaca & siang hari",
      "indonesia_potential": "Sangat Tinggi (khatulistiwa)"
    }'::jsonb,
    1
  ),
  (
    'hydro',
    'Hydropower',
    'PLTA',
    'Energi air memanfaatkan aliran sungai atau terjunan air waduk untuk memutar turbin pembangkit listrik secara berkelanjutan.',
    'water_drop_rounded',
    '#38A6C8',
    '{
      "source": "Aliran & Terjunan Air",
      "emission_level": "Rendah",
      "intermittency": "Stabil (dipengaruhi musim hujan/kemarau)",
      "indonesia_potential": "Tinggi (sungai besar di Sumatera, Jawa, Kalimantan, Sulawesi, Papua)"
    }'::jsonb,
    2
  ),
  (
    'wind',
    'Wind Energy',
    'PLTB',
    'Energi angin mengubah energi kinetik hembusan angin menjadi energi mekanik pada bilah turbin untuk menghasilkan tenaga listrik.',
    'air_rounded',
    '#0EA5E9',
    '{
      "source": "Hembusan Angin",
      "emission_level": "Sangat Rendah",
      "intermittency": "Fluktuatif sesuai kecepatan angin musiman",
      "indonesia_potential": "Menengah-Tinggi (pesisir selatan, Sulawesi Selatan, NTT)"
    }'::jsonb,
    3
  ),
  (
    'geothermal',
    'Geothermal Energy',
    'PLTP',
    'Energi panas bumi memanfaatkan uap dan panas alami dari perut bumi di jalur cincin api (Ring of Fire) Indonesia sebagai pembangkit beban dasar.',
    'thermostat_rounded',
    '#F97316',
    '{
      "source": "Panas Perut Bumi",
      "emission_level": "Rendah",
      "intermittency": "Sangat Stabil (Baseload 24/7)",
      "indonesia_potential": "Sangat Tinggi (salah satu cadangan terbesar di dunia)"
    }'::jsonb,
    4
  ),
  (
    'bioenergy',
    'Bioenergy',
    'PLTBm / PLTBg',
    'Bioenergi mengolah biomassa organik dan biogas dari limbah pertanian, perkebunan, atau organik menjadi energi listrik maupun bahan bakar.',
    'eco_rounded',
    '#22C55E',
    '{
      "source": "Biomassa & Biogas Organik",
      "emission_level": "Netral Karbon Terkelola",
      "intermittency": "Stabil selama pasokan bahan baku terjaga",
      "indonesia_potential": "Tinggi (limbah agroindustri sawit, tebu, sekam padi)"
    }'::jsonb,
    5
  )
on conflict (slug) do update set
  name = excluded.name,
  short_code = excluded.short_code,
  description = excluded.description,
  icon = excluded.icon,
  color_hex = excluded.color_hex,
  comparison = excluded.comparison,
  sort_order = excluded.sort_order,
  updated_at = now();

