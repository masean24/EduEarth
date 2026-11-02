-- ============================================================================
-- Fase 4 (1/5): Skema Tabel Kuis (quizzes, quiz_questions, quiz_answer_keys, quiz_attempts)
-- ============================================================================

-- 1. Tabel quizzes
create table if not exists public.quizzes (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references public.energy_categories (id) on delete set null,
  title text not null,
  description text not null,
  difficulty text not null default 'beginner'
    check (difficulty in ('beginner', 'intermediate', 'advanced')),
  time_limit_seconds integer check (time_limit_seconds is null or time_limit_seconds > 0),
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_quizzes_category_id
  on public.quizzes (category_id);

create index if not exists idx_quizzes_is_published
  on public.quizzes (is_published);

drop trigger if exists trg_quizzes_updated_at on public.quizzes;
create trigger trg_quizzes_updated_at
  before update on public.quizzes
  for each row
  execute function public.set_updated_at();

-- 2. Tabel quiz_questions
-- DILARANG menaruh kolom jawaban benar di tabel ini.
create table if not exists public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes (id) on delete cascade,
  question text not null,
  options jsonb not null default '[]'::jsonb
    check (jsonb_typeof(options) = 'array'),
  explanation text not null,
  sort_order integer not null default 0
);

create index if not exists idx_quiz_questions_quiz_sort
  on public.quiz_questions (quiz_id, sort_order);

-- 3. Tabel quiz_answer_keys
-- Dipisahkan dari quiz_questions. RLS aktif TANPA policy untuk client.
create table if not exists public.quiz_answer_keys (
  question_id uuid primary key references public.quiz_questions (id) on delete cascade,
  correct_option_id text not null check (length(trim(correct_option_id)) > 0)
);

-- 4. Tabel quiz_attempts
-- Client TIDAK BOLEH INSERT/UPDATE/DELETE langsung; hanya dibuat via RPC submit_quiz_attempt.
create table if not exists public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  quiz_id uuid not null references public.quizzes (id) on delete cascade,
  score integer not null check (score >= 0 and score <= 100),
  correct_count integer not null check (correct_count >= 0),
  total_questions integer not null check (total_questions > 0),
  answers jsonb not null default '{}'::jsonb,
  started_at timestamptz not null default now(),
  completed_at timestamptz not null default now()
);

create index if not exists idx_quiz_attempts_user_quiz
  on public.quiz_attempts (user_id, quiz_id);

