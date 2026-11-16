# Rencana Perbaikan Terurut — EduEarth

> Disusun berdasarkan temuan **Tahap 1 & Tahap 2** serta **5 keputusan pemilik proyek** (`2026-11-16`): (1) target **pelajar SMP–SMA & masyarakat umum**, (2) **seluruh 24 fitur fungsional dipertahankan dengan penataan hierarki**, (3) **Pre/Post-Test delta ringan di app**, (4) **Mode Guest eksplorasi tanpa simpan progres**, dan (5) **catatan khusus pembangkit unggulan**.

## 1. HARUS Beres Sebelum Demo / Sidang (Wajib — Urutan Eksekusi)

Kerjakan berurutan dari langkah 1 ke 8 untuk menghilangkan seluruh blocker P0 dan temuan kredibilitas P1:

1. **Perbaiki 4 Broken Routes Perbandingan (`QA-03` — P0, S):**
   - Ganti `/learning/comparison?category=...` menjadi `'${RouteNames.energyComparisonPath}?category=...'` di `plant_detail_page.dart:905`, `energy_category_page.dart:232`, `learning_detail_page.dart:1362`, dan `quiz_result_page.dart:217`. Pasang `errorBuilder` di `GoRouter` (`app_router.dart`).
2. **Perbaiki Slug Modul Yatim & Pemetaan Kuis (`QA-04` + `QA-09` — P0, S):**
   - Ubah `remedialInfoForQuiz(quizMasterArchipelagoId)` di `learning_integration_helper.dart:608` ke `'smart-grid-dan-elektrifikasi-kepulauan'` (atau `'transisi-energi-dan-dampak-lingkungan'`), dan ubah `'penyimpanan-energi-bess-pumped-storage'` menjadi `'teknologi-penyimpanan-energi-bess-pumped-storage'` di `learning_integration_helper.dart` & `material_card.dart`. Petakan `'baseload-vs-intermiten-vre'` ke Kuis 5/6, lalu perbarui unit test agar cocok persis dengan slug SQL `phase8`.
3. **Aktifkan Mode Guest Eksplorasi Baca + Filter `is_draft` (`QA-13` & `QA-05` — P0/P1, S):**
   - Kendurkan redirect paksa `Login` di `app_router.dart:82-87` agar Guest bisa membuka `Home`, `ExploreMap`, `PlantDetail`, `Learning`, `EnergyComparison`, `QuizDashboard` (tetap kunci submit kuis, bookmark, profil, dan **nonaktifkan penyimpanan persisten `ReadingProgressNotifier`** saat `!isAuthenticated`). Tambah tombol *"Jelajahi sebagai Tamu"* di `LoginPage`/`OnboardingPage`.
   - Tambahkan `.eq('is_draft', false)` di `LearningRepository`, `QuizRepository`, dan `SearchRepository`.
4. **Amankan `.env.example` & Batasi Route Developer (`QA-10` — P1, S):**
   - Hapus URL & JWT anon key asli dari `.env.example:6-7`, ganti ke placeholder; rotasi anon key di dashboard Supabase bila repo pernah dipublikasikan.
   - Bungkus route `/design-showcase` (`app_router.dart:57,119`) agar aktif hanya saat `kDebugMode`, dan validasi skema `http/https` di `ExternalMapService.openExternalUrl`.
5. **Tambahkan Pre/Post-Test Delta Ringan di App (Keputusan #3 — P1/Konsep, S–M):**
   - Tanpa mengubah arsitektur besar: gunakan `quiz_attempts` per `(user_id, quiz_id)` di `MyLearningPage` untuk menampilkan **"Skor Awal vs Skor Terbaru (+Delta)"** beserta status pencapaian target kenaikan pemahaman, sehingga output belajar terlihat langsung di UI saat demo.
6. **Berikan Catatan Khusus 5–6 Pembangkit Ikon (Keputusan #5 — Opsi Hemat S, ~1–2 jam):**
   - Jangan menambah kolom DB untuk 128 baris. Di `PlantDetailPage` & `LearningIntegrationHelper`, tambahkan blok sorotan studi kasus ringkas untuk 5–6 pembangkit ikon (*PLTS Terapung Cirata, PLTA Saguling/Cirata, PLTP Kamojang, PLTB Sidrap, 1 PLTBg*) yang **100% dirangkum dari `description`/`source_notes`/`source_url` terverifikasi**, sambil memperjelas label kartu di bawahnya menjadi *"Karakteristik Umum Kategori & Wilayah"*.
7. **Selaraskan Narasi Target SMP–SMA/Umum & Hierarki 24 Fitur (`QA-01` & `QA-02` — P1, S–M):**
   - Samakan narasi `OnboardingPage`, `HomeDashboardPage`, `AboutPage:72`, dan `docs/01_PROJECT_OVERVIEW.md` untuk **SMP–SMA & masyarakat umum** dengan badge level `Pemula/Menengah/Lanjut` (`difficulty`).
   - Tata ulang hierarki tanpa menghapus fitur: posisikan `Nearby Plants` di sub-tombol Peta, fokuskan deskripsi `Notification Center` sebagai papan panduan belajar, dan alihkan fokus tampilan lencana di `ProfilePage` ke penguasaan modul/kuis (bukan sekadar jumlah bookmark).
8. **Sinkronkan Dokumen & Uji Checklist Demo 5 Menit (`QA-08` & `QA-13` — P1, S):**
   - Perbarui `data/DATA_LOG.md:3` (CHECKSUMS sudah ada), `EDUEARTH_IMPLEMENTATION_REPORT.md:78` (Kuis 6 sudah ada di `phase9`), dan `EDUEARTH_DEMO_CHECKLIST.md:62` (sumber aktual GEM.wiki + EBTKE 2023). Jalankan `flutter analyze`, `flutter test` (tambah test route & slug), lalu uji langsung APK di HP.

## 2. Boleh Ditunda (Pasca-Sidang / Iterasi Sekolah)

- **Kontras Tombol & Tap Target Aksesibilitas (`QA-11` — P2, M):** Gelapkan warna latar `PrimaryButton` (`#15803D`/`#14532D`) agar kontras teks putih `>= 4.5:1`, perbesar tombol tutup preview peta (`explore_map_page.dart:696`) ke `48x48dp`, dan naikkan teks `< 11px`. *(Bisa diperbaiki sebagian jika waktu mepet, penuh pasca-sidang).*
- **Glosarium Istilah SMP & Sinkronisasi Progres Baca ke Server (`QA-06`, `QA-09` — P2, M):** Buat tabel/kolom `user_reading_progress` di Supabase dan tambahkan modal glosarium istilah (`LCA`, `baseload`, `intermiten`, `brine`) untuk pembelajar SMP/pemula.
- **Performa Query & Clustering Peta (`QA-07`, `QA-12` — P2, M):** Tambah `.limit(...)` pada riwayat kuis/bookmark, klasterisasi marker saat zoom jauh, indikator offline tile OSM, serta melengkapi `DemoData` offline (9 modul & soal preview non-kunci).
- **Validasi Lapangan & Verifikasi Data Lanjut (`DATA_LOG.md:45-61`):** Verifikasi 19 `source_url` bermasalah, isi `verified_at` dari audit manual, dan konfirmasi angka total bauran nasional ESDM primer.

## 3. Sebaiknya Dihapus / Dibersihkan (Tanpa Membuang 24 Fitur Inti)

Meski seluruh 24 fitur pengguna dipertahankan, **4 artefak teknis semu/yatim ini sebaiknya tetap dihapus atau dibersihkan** karena tidak memberi nilai tambah dan berisiko memicu bug:
1. **`lib/features/plants/presentation/widgets/plant_preview_sheet.dart`:** File widget yatim yang tidak pernah dipanggil sama sekali di seluruh aplikasi (`ExploreMapPage` sudah memakai `_MapPlantPreviewCard`).
2. **Referensi path aset hilang (`learning_detail_page.dart:320,328,336,353-361`) & `assetForCategorySlug` kosong (`category_chip.dart:28`):** Hapus pemanggilan `'assets/images/categories/*.png'` dan `'assets/images/mascot/eco_map.png'` yang filenya tidak ada agar tidak mengandalkan `errorBuilder` diam-diam.
3. **Checklist `_understoodChapters` non-persisten (`learning_detail_page.dart:52`):** Bila belum disinkronkan ke `SharedPreferences`/DB, hapus UI checklist semu per bab agar progres siswa tidak hilang tiap membuka ulang materi.
4. **Bypass `/design-showcase` di build rilis (`app_router.dart:57,119`):** Hapus dari router produksi atau batasi ketat dengan `if (kDebugMode)`.
