# 04 — Database (Supabase / PostgreSQL)

Dokumen ini adalah **rencana skema**. SQL final dibuat per fase sebagai file migrasi di `supabase/migrations/` (format `YYYYMMDDHHMMSS_nama.sql`). Jangan mengubah skema tanpa memperbarui dokumen ini.

## Aturan umum
- Primary key: `uuid` dengan `default gen_random_uuid()`.
- Waktu: `timestamptz` dengan `default now()`; tabel yang bisa diubah punya `created_at` dan `updated_at` (trigger `set_updated_at`).
- Foreign key eksplisit dengan `on delete` yang disengaja.
- Index pada setiap FK dan kolom yang sering difilter/diurutkan.
- **RLS aktif di semua tabel.**
- Konten (kategori, pembangkit, materi, kuis) **dikelola lewat Supabase dashboard / service role di luar app**. Client hanya boleh membaca konten yang `is_published = true`.
- Aktifkan ekstensi: `postgis`.

## Tabel

### `energy_categories`
`id`, `slug` (unique: solar, hydro, wind, geothermal, bioenergy), `name`, `short_code` (PLTS, PLTA, PLTB, PLTP, PLTBm/PLTBg), `description`, `icon`, `color_hex`, `comparison` (jsonb — atribut untuk fitur Energy Comparison), `sort_order`, timestamps.

### `power_plants`
`id`, `category_id` → `energy_categories`, `name`, `description` (nullable), `province`, `city`,
`latitude` (double precision, not null), `longitude` (double precision, not null),
`coordinate_precision` (check: `exact | approximate`, default `exact`),
`geog` (`geography(Point,4326)`, **generated** dari longitude/latitude, GIST index),
`capacity_mw` (numeric, **nullable**), `operational_status` (check: `operating | construction | planned | unknown`, default `unknown`), `operator_name` (nullable),
`image_url`, **`source_url`**, `source_notes` (nullable), `external_ref` (nullable), `data_as_of` (nullable), **`verified_at`** (nullable), `is_demo` (boolean default false), `is_published`, timestamps.
Unique constraint: `(category_id, name)` + partial unique index `(external_ref) where external_ref is not null`.

Aturan data: kolom yang tidak diketahui dibiarkan `null`/`unknown`, **tidak diisi tebakan**. Baris contoh untuk pengembangan wajib `is_demo = true`.

### `learning_materials`
`id`, `category_id`, `title`, `slug` (unique), `summary`, `content_md` (Markdown), `cover_image_url`, `read_minutes`, `difficulty` (check: beginner/intermediate/advanced), `sort_order`, `is_published`, `is_draft` (boolean default false), timestamps.

### `quizzes`
`id`, `category_id` (nullable), `title`, `description`, `difficulty`, `time_limit_seconds` (nullable), `is_published`, `is_draft` (boolean default false), timestamps.

### `quiz_questions`
`id`, `quiz_id`, `question`, `options` (jsonb array `[{ "id": "a", "text": "..." }]`), `explanation`, `sort_order`.
**Tidak boleh ada kolom jawaban benar di tabel ini.**

### `quiz_answer_keys`
`question_id` (PK, FK → `quiz_questions`), `correct_option_id` (text).
RLS aktif **tanpa policy untuk client** → tidak terbaca dari app. Hanya dibaca oleh fungsi `security definer`.

### `quiz_attempts`
`id`, `user_id` → `auth.users`, `quiz_id`, `score` (int), `correct_count`, `total_questions`, `answers` (jsonb), `started_at`, `completed_at`.
Client **tidak boleh INSERT langsung**; hanya lewat RPC.

### `user_profiles`
`id` (PK = `auth.users.id`, `on delete cascade`), `display_name`, `avatar_url`, timestamps.
Dibuat otomatis oleh trigger `handle_new_user` saat user mendaftar.

### `bookmarks`
`id`, `user_id`, `material_id` (nullable, FK), `plant_id` (nullable, FK), `created_at`.
- `check (num_nonnulls(material_id, plant_id) = 1)`
- Unique parsial: `(user_id, material_id) where material_id is not null` dan `(user_id, plant_id) where plant_id is not null`.

### `achievements`
`id`, `code` (unique), `title`, `description`, `icon`, `points`, `sort_order`.

### `user_achievements`
`id`, `user_id`, `achievement_id`, `unlocked_at`, `unique (user_id, achievement_id)`.
Pemberian achievement dilakukan server-side (RPC/trigger), bukan insert bebas dari client.

### `notifications` (Fase 6 — disetujui pemilik)
`id` (uuid PK), `title`, `body`, `category` (check: `info | content | update`), `is_published` (boolean default false), `created_at` (timestamptz).
Tanpa `user_id` dan tanpa `is_read` di database (hanya pengumuman publik satu arah; status baca per pengguna disimpan lokal di `shared_preferences`).

## RLS — ringkasan kebijakan

| Tabel | SELECT | INSERT / UPDATE / DELETE |
|---|---|---|
| `energy_categories` | publik (anon + authenticated) | tidak ada policy client |
| `power_plants` | publik jika `is_published` | tidak ada policy client |
| `learning_materials` | publik jika `is_published` | tidak ada policy client |
| `quizzes`, `quiz_questions` | publik jika `is_published` | tidak ada policy client |
| `quiz_answer_keys` | **tidak ada** | **tidak ada** |
| `quiz_attempts` | hanya milik sendiri (`user_id = auth.uid()`) | **hanya lewat RPC** |
| `user_profiles` | milik sendiri | UPDATE milik sendiri |
| `bookmarks` | milik sendiri | INSERT/DELETE milik sendiri |
| `achievements` | publik | tidak ada policy client |
| `user_achievements` | milik sendiri | **hanya lewat RPC/trigger** |
| `notifications` | publik jika `is_published` | tidak ada policy client |

Gunakan `(select auth.uid())` pada policy demi performa.

## Fungsi / RPC

- `handle_new_user()` — trigger pada `auth.users`, membuat baris `user_profiles`.
- `set_updated_at()` — trigger generik.
- `nearby_plants(lat double precision, lng double precision, radius_m integer, category_slug text default null)` — mengembalikan pembangkit terpublikasi dalam radius, terurut jarak, memakai `ST_DWithin` pada `geog`.
- `submit_quiz_attempt(p_quiz_id uuid, p_answers jsonb)` — `security definer`; membandingkan jawaban dengan `quiz_answer_keys`, menghitung skor, menyimpan ke `quiz_attempts`, mengembalikan skor + jawaban benar + penjelasan per soal. Set `search_path` secara eksplisit.
- (Fase 6) `check_and_award_achievements()` — mengevaluasi syarat dan mengisi `user_achievements`.

## Index minimal
- `power_plants (category_id)`, `power_plants using gist (geog)`, `power_plants (is_published)`
- `learning_materials (category_id, sort_order)`
- `quiz_questions (quiz_id, sort_order)`
- `quiz_attempts (user_id, quiz_id)`
- `bookmarks (user_id)`

## Storage (bila dipakai)
Bucket publik untuk gambar konten (`plant-images`, `material-covers`) dan bucket `avatars` dengan policy per-user. Tidak ada upload konten dari client.
