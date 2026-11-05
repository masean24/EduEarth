-- ============================================================================
-- Migrasi Fase 6 (Bagian 1):
-- 1. Tabel `achievements` dan `user_achievements` beserta RLS ketat.
-- 2. RPC `check_and_award_achievements()` (security definer) untuk mengevaluasi
--    syarat lencana di sisi server (client tidak bisa INSERT langsung).
-- 3. Seed 6 achievement edukatif & pengisian atribut `energy_categories.comparison`
--    untuk fitur Energy Comparison.
-- ============================================================================

begin;

-- 1. Tabel master achievements
create table if not exists public.achievements (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  title text not null,
  description text not null,
  icon text not null default 'emoji_events_rounded',
  points integer not null default 10 check (points >= 0),
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

-- 2. Tabel user_achievements (progres per pengguna)
create table if not exists public.user_achievements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  achievement_id uuid not null references public.achievements(id) on delete cascade,
  unlocked_at timestamptz not null default now(),
  constraint user_achievements_user_achievement_unique unique (user_id, achievement_id)
);

create index if not exists idx_user_achievements_user_id
  on public.user_achievements (user_id);

create index if not exists idx_user_achievements_achievement_id
  on public.user_achievements (achievement_id);

-- 3. RLS untuk achievements & user_achievements
alter table public.achievements enable row level security;
alter table public.user_achievements enable row level security;

drop policy if exists "achievements_select_public" on public.achievements;
create policy "achievements_select_public"
  on public.achievements
  for select
  to anon, authenticated
  using (true);

drop policy if exists "user_achievements_select_own" on public.user_achievements;
create policy "user_achievements_select_own"
  on public.user_achievements
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

-- Tidak ada policy INSERT/UPDATE/DELETE untuk client pada achievements maupun user_achievements.

-- 4. Seed 6 Achievement EduEarth
insert into public.achievements (code, title, description, icon, points, sort_order)
values
  (
    'first_bookmark',
    'Penjelajah Ingin Tahu',
    'Menyimpan materi pembelajaran atau pembangkit pertama ke Daftar Tersimpan.',
    'bookmark_added_rounded',
    10,
    1
  ),
  (
    'avid_learner',
    'Pembelajar Energi Bersih',
    'Menyimpan minimal 2 materi pembelajaran energi terbarukan untuk dipelajari.',
    'menu_book_rounded',
    20,
    2
  ),
  (
    'plant_collector',
    'Pemeta Nusantara',
    'Menyimpan minimal 2 lokasi pembangkit energi terbarukan di Indonesia.',
    'map_rounded',
    20,
    3
  ),
  (
    'first_quiz',
    'Langkah Pertama Kuis',
    'Menyelesaikan percobaan kuis energi terbarukan pertama hingga tuntas.',
    'quiz_rounded',
    15,
    4
  ),
  (
    'quiz_master',
    'Juara Energi Terbarukan',
    'Meraih skor minimal 80 pada salah satu kuis evaluasi EduEarth.',
    'workspace_premium_rounded',
    30,
    5
  ),
  (
    'perfect_score',
    'Skor Sempurna 100',
    'Menjawab seluruh pertanyaan dengan benar (skor 100) pada kuis EduEarth.',
    'emoji_events_rounded',
    50,
    6
  )
on conflict (code) do update
set
  title = excluded.title,
  description = excluded.description,
  icon = excluded.icon,
  points = excluded.points,
  sort_order = excluded.sort_order;

-- 5. RPC Server-Side: check_and_award_achievements()
create or replace function public.check_and_award_achievements()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_bookmark_count integer := 0;
  v_material_bookmark_count integer := 0;
  v_plant_bookmark_count integer := 0;
  v_quiz_count integer := 0;
  v_max_score integer := 0;
  v_newly_awarded jsonb := '[]'::jsonb;
  v_total_unlocked integer := 0;
begin
  if v_user_id is null then
    raise exception 'Pengguna harus masuk (login) untuk mengevaluasi pencapaian.';
  end if;

  select
    count(*)::integer,
    count(*) filter (where material_id is not null)::integer,
    count(*) filter (where plant_id is not null)::integer
  into
    v_bookmark_count,
    v_material_bookmark_count,
    v_plant_bookmark_count
  from public.bookmarks
  where user_id = v_user_id;

  select
    count(*)::integer,
    coalesce(max(score), 0)::integer
  into
    v_quiz_count,
    v_max_score
  from public.quiz_attempts
  where user_id = v_user_id;

  with eligible_codes as (
    select code
    from (
      values
        ('first_bookmark', v_bookmark_count >= 1),
        ('avid_learner', v_material_bookmark_count >= 2),
        ('plant_collector', v_plant_bookmark_count >= 2),
        ('first_quiz', v_quiz_count >= 1),
        ('quiz_master', v_max_score >= 80),
        ('perfect_score', v_max_score >= 100)
    ) as t(code, is_met)
    where t.is_met = true
  ),
  inserted as (
    insert into public.user_achievements (user_id, achievement_id)
    select v_user_id, a.id
    from public.achievements a
    inner join eligible_codes e on e.code = a.code
    on conflict (user_id, achievement_id) do nothing
    returning achievement_id
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', a.id,
        'code', a.code,
        'title', a.title,
        'points', a.points
      )
    ),
    '[]'::jsonb
  )
  into v_newly_awarded
  from inserted i
  inner join public.achievements a on a.id = i.achievement_id;

  select count(*)::integer
  into v_total_unlocked
  from public.user_achievements
  where user_id = v_user_id;

  return jsonb_build_object(
    'newly_awarded', v_newly_awarded,
    'total_unlocked', v_total_unlocked
  );
end;
$$;

revoke all on function public.check_and_award_achievements() from public;
grant execute on function public.check_and_award_achievements() to authenticated;

-- 6. Pengisian atribut perbandingan (`comparison` JSONB — draf kualitatif konseptual) pada `energy_categories`
update public.energy_categories
set comparison = jsonb_build_object(
  'sumber_energi', 'Radiasi cahaya matahari yang dikonversi melalui efek fotovoltaik pada sel surya',
  'karakter_pasokan', 'Intermiten; berproduksi optimal pada siang hari dan bergantung pada cuaca serta tutupan awan',
  'faktor_kapasitas', 'Relatif rendah hingga menengah karena siklus penyinaran harian matahari',
  'emisi_siklus_hidup', 'Sangat rendah saat beroperasi; jejak emisi terutama berasal dari proses manufaktur modul surya',
  'kebutuhan_lahan', 'Fleksibel; dapat memanfaatkan atap bangunan, lahan terbuka, maupun permukaan waduk (PLTS terapung)',
  'keunggulan_utama', 'Bersifat modular, waktu pemasangan relatif cepat, serta pemeliharaan harian sederhana',
  'tantangan_utama', 'Memerlukan penyimpan energi (baterai) atau penyeimbang jaringan saat malam dan cuaca mendung',
  'karakter_lokasi', 'Daerah terbuka dengan paparan radiasi matahari konsisten dan minim bayangan penghalang'
)
where slug = 'solar';

update public.energy_categories
set comparison = jsonb_build_object(
  'sumber_energi', 'Energi potensial dan kinetik dari aliran sungai atau terjunan air waduk',
  'karakter_pasokan', 'Stabil dan fleksibel; dapat dioperasikan untuk memikul beban dasar maupun beban puncak',
  'faktor_kapasitas', 'Menengah hingga tinggi, mengikuti ketersediaan debit air sepanjang musim',
  'emisi_siklus_hidup', 'Sangat rendah selama masa operasi pembangkitan listrik',
  'kebutuhan_lahan', 'Luas untuk sistem bendungan berwaduk; relatif ringkas untuk sistem aliran sungai langsung (run-of-river)',
  'keunggulan_utama', 'Umur teknis infrastruktur panjang dan mampu merespons perubahan beban jaringan dengan cepat',
  'tantangan_utama', 'Kebutuhan investasi konstruksi sipil awal besar serta sensitif terhadap musim kemarau',
  'karakter_lokasi', 'Wilayah dengan daerah aliran sungai berdebit stabil dan topografi berlembah atau berbukit'
)
where slug = 'hydro';

update public.energy_categories
set comparison = jsonb_build_object(
  'sumber_energi', 'Energi kinetik hembusan massa udara yang memutar bilah rotor turbin angin',
  'karakter_pasokan', 'Variabel / intermiten; mengikuti fluktuasi kecepatan angin harian dan musiman',
  'faktor_kapasitas', 'Menengah pada koridor angin yang memiliki hembusan konsisten',
  'emisi_siklus_hidup', 'Sangat rendah; tidak menghasilkan emisi pembakaran selama turbin beroperasi',
  'kebutuhan_lahan', 'Area di sekitar menara turbin masih dapat dimanfaatkan bersama untuk pertanian atau penggembalaan',
  'keunggulan_utama', 'Tidak memerlukan air pendingin dan dapat membangkitkan listrik baik siang maupun malam hari',
  'tantangan_utama', 'Terbatas pada wilayah dengan profil kecepatan angin yang memadai serta membutuhkan manajemen kestabilan frekuensi',
  'karakter_lokasi', 'Kawasan pesisir, perbukitan terbuka, atau celah pegunungan dengan hembusan angin terarah'
)
where slug = 'wind';

update public.energy_categories
set comparison = jsonb_build_object(
  'sumber_energi', 'Panas alami dan uap dari reservoar hidrotermal di dalam kerak bumi',
  'karakter_pasokan', 'Beban dasar (baseload) yang beroperasi kontinu tanpa bergantung pada cuaca atau pergantian musim',
  'faktor_kapasitas', 'Sangat tinggi dibandingkan pembangkit energi terbarukan berbasis cuaca',
  'emisi_siklus_hidup', 'Rendah, terlebih dengan penerapan sistem reinjeksi fluida kembali ke dalam reservoar',
  'kebutuhan_lahan', 'Kompak per satuan kapasitas pembangkitan dibandingkan energi surya atau bendungan air',
  'keunggulan_utama', 'Keluaran daya sangat stabil sepanjang tahun sehingga andal sebagai penopang utama jaringan listrik',
  'tantangan_utama', 'Risiko geologi pada tahap eksplorasi sumur awal serta waktu pengembangan proyek yang bertahap',
  'karakter_lokasi', 'Kawasan sabuk vulkanik aktif yang memiliki manifestasi dan reservoar panas bumi'
)
where slug = 'geothermal';

update public.energy_categories
set comparison = jsonb_build_object(
  'sumber_energi', 'Bahan organik terbarukan seperti residu pertanian, perkebunan, limbah cair organik, atau biogas',
  'karakter_pasokan', 'Dapat dikendalikan (dispatchable) selama rantai pasok bahan baku organik terjaga',
  'faktor_kapasitas', 'Menengah hingga tinggi, bergantung pada kontinuitas suplai bahan baku biomassa atau biogas',
  'emisi_siklus_hidup', 'Rendah dalam siklus karbon tertutup apabila memanfaatkan limbah organik secara berkelanjutan',
  'kebutuhan_lahan', 'Umumnya terintegrasi dengan fasilitas pengolahan agroindustri atau instalasi pengolah limbah',
  'keunggulan_utama', 'Membantu mengelola limbah organik dan mengurangi pelepasan gas metana sekaligus menghasilkan energi',
  'tantangan_utama', 'Memerlukan pengelolaan logistik pengumpulan, penyimpanan, dan pengendalian kadar air bahan baku',
  'karakter_lokasi', 'Sentra perkebunan, pertanian, atau fasilitas pengolahan produk agroindustri'
)
where slug = 'bioenergy';

commit;
