# EduEarth

> **Explore Energy, Understand Earth.**  
> Aplikasi mobile edukasi energi terbarukan di Indonesia berbasis **Flutter** dan **Supabase**.

---

## Tentang EduEarth

**EduEarth** adalah aplikasi pembelajaran pendamping berbasis geospasial untuk **pelajar SMP–SMA/SMK dan masyarakat umum** dalam mempelajari lima jenis pembangkit energi terbarukan di Indonesia (**PLTS / Surya**, **PLTA / Air**, **PLTB / Angin**, **PLTP / Panas Bumi**, dan **Bioenergi**) melalui **4 pilar terintegrasi**:
1. **Explore** — Peta persebaran 128 pembangkit tercatat (`Beroperasi`, `Konstruksi`, `Rencana`), transparansi presisi lokasi (`exact` vs `Lokasi perkiraan`), dan konteks geografis wilayah.
2. **Learn** — 9 modul pembelajaran terstruktur (dilengkapi *persistent high-water-mark reading progress* dan contoh pembangkit nyata).
3. **Understand Impact** — Perbandingan karakteristik, variasi desain, manfaat dekarbonisasi, dan *trade-off* lingkungan berbasis literatur **IPCC AR6 WGIII (2022)**, **IRENA**, dan **Kementerian ESDM (Ditjen EBTKE)**.
4. **Evaluate** — 6 paket kuis berpenilaian *server-side* (`SmartQuizResolver`) lengkap dengan pembahasan ilmiah per soal dan rekomendasi remedial.

### Fitur Utama (Fase 0 – Fase 9 & Polish UI/UX)
- **Autentikasi, Onboarding, Mode Tamu, & Splash HD**:
  - Alur Splash → Onboarding 3 slide interaktif (`SharedPreferences`) → Login/Register atau **Mode Tamu persisten** (dapat diakses langsung dari slide akhir Onboarding, Login, maupun Register; bebas menjelajahi peta, materi, & perbandingan tanpa login dengan batasan jujur tanpa menyimpan progres/skor).
  - Pembuatan profil otomatis via trigger PostgreSQL, validasi akun aktif, dan penonaktifan *auto-retry* berkepanjangan (`ProviderScope(retry: null)`) agar `ErrorView` tampil cepat saat offline.
- **Peta Eksplorasi & Dataset 128 Pembangkit Nyata**:
  - Peta interaktif berbasis `flutter_map` + OpenStreetMap (ODbL) dengan *framing* awal kepulauan Indonesia utuh (`CameraFit.bounds`), tombol *Pusatkan ke lokasi saya*, serta penanganan ubin offline (`errorTileCallback`).
  - Dataset terkurasi **128 pembangkit energi terbarukan on-grid (>= 1 MW)** di Indonesia (`85 beroperasi`, `9 konstruksi`, `34 rencana`) dengan atribusi sumber per baris (`source_url`, `data_as_of`, `source_notes`, dan penanda `coordinate_precision`).
  - Strip filter 5 kategori energi (`HorizontalChipStrip`) dan **filter status operasional** (**Beroperasi**, **Konstruksi**, **Rencana** — default **HANYA Beroperasi**) dengan pembeda visual marker.
  - Halaman **Detail Pembangkit** dengan *footer* sticky terfokus (*Bandingkan EBT* + *Buka Maps*/*Cari Maps*), label **"Kapasitas terpasang (menurut sumber)"**, dukungan kedua mode Google Maps (`query=lat,lng` & pencarian nama untuk koordinat `approximate` / **"Lokasi perkiraan"**), serta catatan studi kasus & `source_notes`.
  - Pencarian pembangkit terdekat dari lokasi pengguna (`geolocator` + PostGIS RPC `nearby_plants`).
- **Pustaka Pembelajaran, Perbandingan Energi, & Bookmark**:
  - Materi edukasi per kategori energi yang dirender menggunakan Markdown (`flutter_markdown_plus`) lengkap dengan penanda status draf (`is_draft`).
  - **Perbandingan Energi (*Energy Comparison*)**: membandingkan 2 kategori energi secara berdampingan pada 8 dimensi kualitatif dari atribut JSONB `energy_categories.comparison`.
  - Simpan (*bookmark*) pembangkit maupun materi pembelajaran per akun pengguna.
- **Kuis Aman (*Server-Side Grading*)**:
  - Kunci jawaban disimpan di tabel terpisah (`quiz_answer_keys`) yang tertutup rapat dari client (RLS aktif tanpa policy client).
  - Penilaian skor, jumlah benar, dan pengembalian pembahasan dilakukan di server melalui RPC `submit_quiz_attempt` (`SECURITY DEFINER`).
- **Achievement, Notification Center, Profil, & Pencarian Global**:
  - **Achievement & Badge**: evaluasi lencana otomatis di server melalui RPC `check_and_award_achievements()` (`SECURITY DEFINER`) berdasarkan progres kuis dan bookmark.
  - **Notification Center (Pusat Informasi)**: pengumuman publik satu arah dari tabel `notifications` dengan pelacakan status baca lokal di `SharedPreferences`.
  - **Navigasi, Profil, Progres Belajar, Pengaturan, & Aksesibilitas**:
    - `GlassBottomNav` 5 tab berbahasa Indonesia (**Jelajah · Belajar · Beranda · Kuis · Profil**), token kontras aksi primer WCAG AA (`AppColors.actionGreen` `#15803D`), target sentuh header/kontrol `48dp`, serta maskot Eco kontekstual pada `EmptyView`.
    - **Progres Belajar (*My Learning*)**: pelacakan delta skor kuis (**Awal → Terbaru**), riwayat percobaan, dan daftar bookmark.
    - **Pengaturan (*Kurangi efek glass*) & Tentang EduEarth** dapat diakses penuh oleh pengguna login maupun Mode Tamu (lengkap dengan dokumentasi **Sumber Data dan Cakupan** dari `data/DATA_LOG.md`).
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
| CI / Build APK | GitHub Actions (`.github/workflows/build-apk.yml`) |

---

## Struktur Direktori

```text
lib/
├── main.dart
├── app.dart
├── core/               # Konfigurasi (--dart-define), tema, konstanta, error mapper, widget umum & glass
├── routes/             # Nama rute & konfigurasi GoRouter
├── services/           # Inisialisasi Supabase, layanan lokasi, & deep link Google Maps
├── models/             # Model data Dart (fromJson / toJson)
└── features/           # Modul fitur (splash, onboarding, auth, home, map, plants, learning,
                        #              quiz, bookmark, achievement, notification, profile, search, settings)
data/
├── CHECKSUMS.txt       # Hash SHA-256 kelima CSV pembangkit
├── DATA_LOG.md         # Log sumber data, cakupan, hasil audit, dan keterbatasan dataset
└── staging/            # 5 file CSV pembangkit terkurasi (geothermal, wind, hydro, solar, bioenergy)
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
5. **Fase 5 — Status Draf Konten**
   - `20261103014001_phase5_is_draft_column_and_clean_titles.sql`
6. **Fase 6 — Achievement, Perbandingan Energi, & Notification Center**
   - `20261103081001_phase6_achievements_and_comparison.sql`
   - `20261103082501_phase6_notifications.sql`
7. **Tahap 7 — Impor 128 Pembangkit Nyata & Pembersihan Baris Demo**
   - `20261104234501_phase7_import_real_power_plants.sql`
   - `20261104234502_phase7_delete_demo_power_plants.sql` *(jalankan setelah memverifikasi hasil impor 128 baris)*
8. **Fase 8 & 9 — Kurasi Materi, Kuis, Matriks Perbandingan, & Blueprint V2**
   - `20261105104501_phase8_curated_materials_and_quizzes.sql`
   - `20261110120001_phase9_final_blueprint_v2_refinements.sql`

---

## Build APK Otomatis di GitHub Actions (Tanpa Device Lokal)

Repositori ini telah dilengkapi workflow GitHub Actions di [`.github/workflows/build-apk.yml`](.github/workflows/build-apk.yml) sehingga Anda dapat mem-build file **`app-release.apk`** langsung di server GitHub tanpa membebani perangkat lokal:

1. **Tambahkan Repository Secrets di GitHub**:
   - Buka repositori GitHub Anda → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.
   - Tambahkan 2 secret berikut (gunakan `anon` key publik, **jangan pernah** gunakan `service_role` key):
     - `SUPABASE_URL`: URL proyek Supabase Anda (contoh: `https://xxxx.supabase.co`).
     - `SUPABASE_ANON_KEY`: Kunci `anon` publik proyek Supabase Anda.
2. **Jalankan Workflow Build APK**:
   - Workflow akan otomatis berjalan setiap kali Anda melakukan `git push` ke branch `main`, **atau**
   - Anda dapat memicunya kapan saja secara manual melalui tab **Actions** → pilih **Build EduEarth Android APK** di sisi kiri → klik tombol **Run workflow**.
3. **Unduh File APK**:
   - Setelah proses workflow berstatus centang hijau (selesai), buka detail run tersebut lalu gulir ke bagian bawah (**Artifacts**).
   - Klik **`EduEarth-release-apk`** untuk mengunduh file `.zip` yang berisi `app-release.apk` siap pasang di Android.

---

## Cara Menjalankan di Lokal (Opsional)

1. **Salin contoh konfigurasi environment**
   ```bash
   cp .env.example .env.local
   ```
   Isi `SUPABASE_URL` dan `SUPABASE_ANON_KEY` di `.env.local` (file `.env.*` di-gitignore agar kredensial aman).

2. **Unduh dependency & jalankan**
   ```bash
   flutter pub get
   flutter run --dart-define-from-file=.env.local
   ```
   *(Catatan: Jika dijalankan tanpa `--dart-define`, aplikasi otomatis berjalan dalam **Mode Pratinjau Lokal / Demo** menggunakan data contoh berlabel `[DEMO]`.)*

3. **Verifikasi analisis statis & pengujian**
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
- [Data Log & Cakupan Pembangkit](data/DATA_LOG.md)
- [Audit Produk & QA](docs/audit/05_ringkasan_eksekutif.md)
- [Audit UI/UX & Rencana Perbaikan](docs/audit/ui-ux/05_ringkasan.md)
