-- ============================================================================
-- Fase 4 (3/5): RPC submit_quiz_attempt (Penilaian Kuis Aman di Sisi Server)
-- ============================================================================

create or replace function public.submit_quiz_attempt(
  p_quiz_id uuid,
  p_answers jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_is_published boolean;
  v_total_questions integer := 0;
  v_correct_count integer := 0;
  v_score integer := 0;
  v_attempt_id uuid;
  v_completed_at timestamptz := now();
  v_sanitized_answers jsonb := '{}'::jsonb;
  v_reviews jsonb := '[]'::jsonb;
  r_question record;
  v_selected_option text;
  v_is_correct boolean;
begin
  -- 1. Wajib pengguna terautentikasi
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Anda harus masuk (login) untuk mengirimkan jawaban kuis.'
      using errcode = '42501';
  end if;

  -- 2. Validasi p_quiz_id wajib ada dan kuis harus is_published = true
  if p_quiz_id is null then
    raise exception 'ID kuis tidak boleh kosong.'
      using errcode = '22023';
  end if;

  select q.is_published
    into v_is_published
  from public.quizzes q
  where q.id = p_quiz_id;

  if not found or v_is_published is not true then
    raise exception 'Kuis tidak ditemukan atau belum dipublikasikan.'
      using errcode = '22023';
  end if;

  -- 3. Validasi format p_answers:
  -- Mendukung format objek JSON: { "<question_id>": "<option_id>" }
  -- atau array JSON: [ { "question_id": "<uuid>", "option_id": "<id>" } ]
  if p_answers is null or jsonb_typeof(p_answers) not in ('object', 'array') then
    raise exception 'Format jawaban tidak valid. Gunakan objek atau array JSON.'
      using errcode = '22023';
  end if;

  -- 4. Iterasi HANYA soal milik kuis p_quiz_id (otomatis mengabaikan question_id asing
  -- dan menjamin tepat maksimal 1 jawaban per soal)
  for r_question in
    select
      qq.id as question_id,
      qq.question,
      qq.options,
      qq.explanation,
      qq.sort_order,
      ak.correct_option_id
    from public.quiz_questions qq
    join public.quiz_answer_keys ak on ak.question_id = qq.id
    where qq.quiz_id = p_quiz_id
    order by qq.sort_order asc, qq.id asc
  loop
    v_total_questions := v_total_questions + 1;
    v_selected_option := null;

    if jsonb_typeof(p_answers) = 'object' then
      if p_answers ? (r_question.question_id::text) then
        if jsonb_typeof(p_answers -> (r_question.question_id::text)) = 'string' then
          v_selected_option := trim(p_answers ->> (r_question.question_id::text));
        else
          raise exception 'Nilai jawaban untuk setiap soal harus berupa teks.'
            using errcode = '22023';
        end if;
      end if;
    elsif jsonb_typeof(p_answers) = 'array' then
      -- Ambil kemunculan pertama yang cocok untuk question_id ini (1 jawaban per soal)
      select trim(elem ->> 'option_id')
        into v_selected_option
      from jsonb_array_elements(p_answers) as elem
      where jsonb_typeof(elem) = 'object'
        and (elem ->> 'question_id') = (r_question.question_id::text)
        and jsonb_typeof(elem -> 'option_id') = 'string'
      limit 1;
    end if;

    if v_selected_option is not null and v_selected_option <> '' then
      v_sanitized_answers := v_sanitized_answers || jsonb_build_object(
        r_question.question_id::text,
        v_selected_option
      );
    end if;

    v_is_correct := (
      v_selected_option is not null
      and lower(v_selected_option) = lower(r_question.correct_option_id)
    );

    if v_is_correct then
      v_correct_count := v_correct_count + 1;
    end if;

    v_reviews := v_reviews || jsonb_build_array(
      jsonb_build_object(
        'question_id', r_question.question_id,
        'question', r_question.question,
        'options', r_question.options,
        'selected_option_id', v_selected_option,
        'correct_option_id', r_question.correct_option_id,
        'is_correct', v_is_correct,
        'explanation', r_question.explanation
      )
    );
  end loop;

  if v_total_questions = 0 then
    raise exception 'Kuis ini belum memiliki soal yang terkonfigurasi.'
      using errcode = '22023';
  end if;

  v_score := round((v_correct_count::numeric / v_total_questions::numeric) * 100)::integer;

  -- 5. Simpan hasil percobaan ke quiz_attempts
  insert into public.quiz_attempts (
    user_id,
    quiz_id,
    score,
    correct_count,
    total_questions,
    answers,
    started_at,
    completed_at
  )
  values (
    v_user_id,
    p_quiz_id,
    v_score,
    v_correct_count,
    v_total_questions,
    v_sanitized_answers,
    v_completed_at,
    v_completed_at
  )
  returning id into v_attempt_id;

  -- 6. Kembalikan skor, jumlah benar, dan ulasan lengkap per soal (SETELAH submit)
  return jsonb_build_object(
    'attempt_id', v_attempt_id,
    'quiz_id', p_quiz_id,
    'score', v_score,
    'correct_count', v_correct_count,
    'total_questions', v_total_questions,
    'completed_at', v_completed_at,
    'reviews', v_reviews
  );
end;
$$;

-- Keamanan hak eksekusi fungsi:
-- Cabut dari PUBLIC dan anon, berikan HANYA kepada authenticated.
revoke all on function public.submit_quiz_attempt(uuid, jsonb) from public, anon;
grant execute on function public.submit_quiz_attempt(uuid, jsonb) to authenticated;

