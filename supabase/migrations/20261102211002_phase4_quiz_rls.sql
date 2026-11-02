-- ============================================================================
-- Fase 4 (2/5): Kebijakan Row Level Security (RLS) & Hak Akses Tabel Kuis
-- ============================================================================

alter table public.quizzes enable row level security;
alter table public.quiz_questions enable row level security;
alter table public.quiz_answer_keys enable row level security;
alter table public.quiz_attempts enable row level security;

-- 1. Policy quizzes:
-- Publik (anon + authenticated) hanya boleh SELECT kuis yang is_published = true.
drop policy if exists "quizzes_select_published" on public.quizzes;
create policy "quizzes_select_published"
  on public.quizzes
  for select
  to anon, authenticated
  using (is_published = true);

-- 2. Policy quiz_questions:
-- Publik (anon + authenticated) hanya boleh SELECT soal dari kuis yang is_published = true.
drop policy if exists "quiz_questions_select_published" on public.quiz_questions;
create policy "quiz_questions_select_published"
  on public.quiz_questions
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.quizzes q
      where q.id = quiz_questions.quiz_id
        and q.is_published = true
    )
  );

-- 3. Policy quiz_answer_keys:
-- TIDAK ADA POLICY SAMA SEKALI untuk anon maupun authenticated!
-- Cabut juga hak SELECT tabel langsung dari anon dan authenticated sebagai lapis pertahanan kedua.
drop policy if exists "quiz_answer_keys_none" on public.quiz_answer_keys;
revoke all on table public.quiz_answer_keys from public, anon, authenticated;

-- 4. Policy quiz_attempts:
-- Client hanya boleh SELECT riwayat milik sendiri: user_id = (select auth.uid()).
-- TIDAK ADA policy INSERT / UPDATE / DELETE untuk client (wajib lewat RPC security definer).
drop policy if exists "quiz_attempts_select_own" on public.quiz_attempts;
create policy "quiz_attempts_select_own"
  on public.quiz_attempts
  for select
  to authenticated
  using (user_id = (select auth.uid()));

revoke insert, update, delete on table public.quiz_attempts from public, anon, authenticated;

