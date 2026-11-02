# EduEarth

> **Explore Energy, Understand Earth.**  
> Aplikasi mobile edukasi energi terbarukan di Indonesia berbasis **Flutter** dan **Supabase**.

---

## Tentang EduEarth

**EduEarth** adalah aplikasi edukasi interaktif untuk mempelajari lima jenis pembangkit energi terbarukan di Indonesia (**PLTS / Surya**, **PLTB / Bayu**, **PLTA / Air**, **PLTP / Panas Bumi**, dan **Bioenergi**) melalui peta pembangkit interaktif, materi pembelajaran terstruktur, kuis berpenilaian *server-side*, dan pelacakan progres belajar.

### Fitur Utama (Fase 0 – Fase 5)
- **Autentikasi & Onboarding**: Registrasi, masuk (*login*), keluar (*logout*), pembuatan profil otomatis via trigger PostgreSQL, serta sesi persisten.
- **Peta Eksplorasi & Pembangkit Terdekat**:
  - Peta interaktif berbasis `flutter_map` + OpenStreetMap (tanpa Google Maps SDK).
  - Filter chip per kategori energi berdesain *Nature Tech + Liquid Glass*.
  - Pratinjau pembangkit (*glass bottom sheet*), halaman detail pembangkit lengkap dengan atribusi sumber data, dan tombol **Buka di Google Maps** melalui `url_launcher`.
  - Pencarian pembangkit terdekat dari lokasi pengguna (`geolocator` + PostGIS RPC `nearby_plants`).
- **Pustaka Pembelajaran & Bookmark**:
  - Materi edukasi per kategori energi yang dirender menggunakan Markdown (`flutter_markdown_plus`).
  - Simpan (*bookmark*) pembangkit maupun materi pembelajaran per akun pengguna.
- **Kuis Aman (*Server-Side Grading*)**:
  - Kunci jawaban disimpan di tabel terpisah (`quiz_answer_keys`) yang tertutup rapat dari client (RLS aktif tanpa policy client).
  - Penilaian skor, jumlah benar, dan pengembalian pembahasan dilakukan di server melalui RPC `submit_quiz_attempt` (`SECURITY DEFINER`).
  - Dashboard kuis menampilkan status penyelesaian, skor terbaik, skor terakhir, dan jumlah percobaan.
- **Profil, Progres Belajar, Pengaturan & Pencarian Global**:
  - Edit nama tampilan (`display_name`) dan URL avatar opsional (`avatar_url`) pada `user_profiles`.
  - Halaman **My Learning** (statistik kuis, materi tersimpan, riwayat percobaan).
  - Opsi aksesibilitas/performa **"Kurangi efek glass"** yang tersimpan di `SharedPreferences`.
  - **Pencarian Global** lintas pembangkit dan materi pembelajaran dengan *debounce* 350 ms dan sanitasi filter PostgREST.

---

## Tech Stack

| Bagian | Teknologi |
|---|---|
| Framework | Flutter (Dart) — Android & iOS |
| Backend | Supabase (Auth, PostgreSQL, PostGIS, RLS, RPC) |
| State Management | Riverpod (`flutter_riverpod`) |
| Navigasi | `go_router` (`StatefulShellRoute` 5 tab) |
| Peta & Geospasial | `flutter_map` + OpenStreetMap + `latlong2` + `geolocator` |
| Deep Link Peta | `url_launcher` (URL resmi Google Maps) |
| Render Materi | `flutter_markdown_plus` |
| Tipografi & Tema | `google_fonts` (*Plus Jakarta Sans*), *Nature Tech + Liquid Glass* |

---

## Struktur Direktori

```text
lib/
├── main.dart
├── app.dart
├── core/               # Konfigurasi (--dart-define), tema, konstanta, error mapper, widget umum & glass
├── routes/             # Nama rute & konfigurasi GoRouter
├── services/           # Inisialisasi Supabase & layanan lokasi
├── models/             # Model data Dart (fromJson / toJson)
└── features/           # Modul fitur (splash, onboarding, auth, home, map, plants, learning, quiz, bookmark, profile, search, settings)
supabase/
└── migrations/         # File migrasi SQL berurutan (skema, trigger, RLS, RPC, dan seed)
docs/                   # Dokumentasi arsitektur, desain, database, roadmap, dan standar kode
```

---

## Persiapan Database (Supabase)

Jalankan file migrasi di folder `supabase/migrations/` secara berurutan di **Supabase SQL Editor**:

1. **Fase 1 — Kategori & Profil Pengguna**
   - `20261102201501_phase1_schema.sql`
   - `20261102201502_phase1_triggers.sql`
   - `20261102201503_phase1_rls.sql`
   - `20261102201504_phase1_seed_categories.sql`
2. **Fase 2 — Pembangkit & PostGIS**
   - `20261102203501_phase2_power_plants_schema.sql`
   - `20261102203502_phase2_power_plants_rls.sql`
   - `20261102203503_phase2_rpc_nearby_plants.sql`
   - `20261102203504_phase2_seed_demo_plants.sql` *(opsional, khusus data berlabel `[DEMO]`)*
3. **Fase 3 — Materi Pembelajaran & Bookmark**
   - `20261102205501_phase3_learning_bookmarks_schema.sql`
   - `20261102205502_phase3_learning_bookmarks_rls.sql`
   - `20261102205503_phase3_seed_draft_materials.sql`
4. **Fase 4 — Kuis & Server-Side Grading**
   - `20261102211001_phase4_quiz_schema.sql`
   - `20261102211002_phase4_quiz_rls.sql`
   - `20261102211003_phase4_rpc_submit_quiz.sql`
   - `20261102211004_phase4_seed_quizzes_questions.sql`
   - `20261102211005_phase4_seed_answer_keys.sql`

---

## Cara Menjalankan Aplikasi

1. **Salin contoh konfigurasi environment**
   ```bash
   cp .env.example .env.local
   ```
   Isi `SUPABASE_URL` dan `SUPABASE_ANON_KEY` di `.env.local` (file `.env.*` di-gitignore agar kredensial aman). **Jangan pernah** memasukkan `service_role` key ke aplikasi client.

2. **Unduh dependency**
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi dengan `--dart-define-from-file`**
   ```bash
   flutter run --dart-define-from-file=.env.local
   ```
   *(Catatan: Jika dijalankan tanpa `--dart-define`, aplikasi otomatis berjalan dalam **Mode Pratinjau Lokal / Demo** menggunakan data contoh berlabel `[DEMO]`.)*

4. **Verifikasi analisis statis & pengujian**
   ```bash
   flutter analyze
   flutter test
   ```

---

## Dokumentasi Lengkap

- [01 — Project Overview](docs/01_PROJECT_OVERVIEW.md)
- [02 — Architecture](docs/02_ARCHITECTURE.md)
- [03 — Design System](docs/03_DESIGN_SYSTEM.md)
- [04 — Database & Security](docs/04_DATABASE.md)
- [05 — Roadmap](docs/05_ROADMAP.md)
- [06 — Coding Standards](docs/06_CODING_STANDARDS.md)
