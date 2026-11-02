-- =============================================================================
-- Migrasi Polish UI #2 (Nomor 5):
-- 1. Menambahkan kolom `is_draft boolean not null default false` pada
--    `public.learning_materials` dan `public.quizzes`.
-- 2. Menandai baris seed awal (`is_draft = true`) dan menghapus awalan "[DRAF] "
--    dari `title` serta catatan "[DRAF REVIEW] " dari `summary`/`description`.
-- =============================================================================

alter table public.learning_materials
  add column if not exists is_draft boolean not null default false;

alter table public.quizzes
  add column if not exists is_draft boolean not null default false;

-- Tandai materi seed awal sebagai draf dan bersihkan awalan [DRAF] pada judul & ringkasan
update public.learning_materials
set
  is_draft = true,
  title = regexp_replace(title, '^\[DRAF\]\s*', '', 'i'),
  summary = regexp_replace(summary, '^\[DRAF\s*REVIEW\]\s*', '', 'i')
where
  title ilike '[DRAF]%'
  or summary ilike '[DRAF%'
  or slug in (
    'konsep-dasar-plts-fotovoltaik',
    'konsep-dasar-pltb-turbin-angin',
    'konsep-dasar-plta-energi-air',
    'konsep-dasar-pltp-panas-bumi',
    'konsep-dasar-bioenergi-biomassa-biogas'
  );

-- Tandai kuis seed awal sebagai draf dan bersihkan awalan [DRAF] pada judul & deskripsi
update public.quizzes
set
  is_draft = true,
  title = regexp_replace(title, '^\[DRAF\]\s*', '', 'i'),
  description = regexp_replace(description, '^\[DRAF\s*REVIEW\]\s*', '', 'i')
where
  title ilike '[DRAF]%'
  or description ilike '[DRAF%'
  or id in (
    '30000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000002'
  );

