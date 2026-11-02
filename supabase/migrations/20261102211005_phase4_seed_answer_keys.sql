-- ============================================================================
-- Fase 4 (5/5): Seed Kunci Jawaban Kuis (quiz_answer_keys — Khusus Server)
-- ============================================================================
-- PENTING: File ini terpisah dari seed soal. Tabel quiz_answer_keys dilindungi
-- RLS tanpa policy client dan REVOKE SELECT dari anon/authenticated, sehingga
-- hanya dapat dibaca oleh fungsi security definer submit_quiz_attempt().

insert into public.quiz_answer_keys (question_id, correct_option_id)
values
  -- Kunci jawaban Kuis 1 ([DRAF] Dasar-Dasar Energi Terbarukan)
  ('22222222-2222-4222-8222-222222222101', 'a'),
  ('22222222-2222-4222-8222-222222222102', 'b'),
  ('22222222-2222-4222-8222-222222222103', 'b'),
  ('22222222-2222-4222-8222-222222222104', 'b'),
  ('22222222-2222-4222-8222-222222222105', 'a'),

  -- Kunci jawaban Kuis 2 ([DRAF] Prinsip Kerja Surya & Panas Bumi)
  ('22222222-2222-4222-8222-222222222201', 'a'),
  ('22222222-2222-4222-8222-222222222202', 'a'),
  ('22222222-2222-4222-8222-222222222203', 'a'),
  ('22222222-2222-4222-8222-222222222204', 'a'),
  ('22222222-2222-4222-8222-222222222205', 'a')
on conflict (question_id) do update set
  correct_option_id = excluded.correct_option_id;

