# Audit Konsep EduEarth — Perspektif Dosen Penguji (Tahap 1)

> Audit bersifat kritis dan berbasis bukti kode/dokumen terkini (per `2026-11-16`). Bila dokumen berbeda dengan implementasi, **kode/migrasi diperlakukan sebagai kebenaran**.

## 1. Evaluasi Masukan Dosen (Poin a–g)

| Poin | Status | Bukti Terverifikasi | Kelemahan Kritis | Saran Perbaikan Konkret |
|---|---|---|---|---|
| **a. Tujuan utama** | **SAMAR** | `docs/01_PROJECT_OVERVIEW.md:4` menyebut *"pelajar dan masyarakat Indonesia"* (3 pilar). `about_page.dart:72-76` & `EDUEARTH_IMPLEMENTATION_REPORT.md:9` mengubahnya menjadi *"siswa SMA/SMK kelas X–XII"* (4 pilar). `onboarding_page.dart:56-90` masih 3 pilar umum. | Identitas ganda: produk umum vs media ajar SMA/SMK. Copywriting ditambal di Home/About, tetapi Onboarding/Register/Profile belum selaras. | Kunci satu definisi tujuan di semua layar (`OnboardingPage`, `HomeDashboardPage`, `AboutPage`) & `docs/01`: media literasi EBT berbasis peta untuk **siswa SMA/SMK**. |
| **b. Masalah yang diselesaikan** | **SAMAR** | Tidak ada bagian *Problem Statement* di `docs/01_PROJECT_OVERVIEW.md`. Rumusan masalah baru muncul di Q&A `EDUEARTH_DEMO_CHECKLIST.md:60` ("belajar abstrak di buku teks"). | Di UI, pengguna tidak langsung melihat "masalah belajar" apa yang dijawab; alur terasa seperti katalog peta + artikel + kuis lepas. | Tambahkan *Problem Statement* resmi di `docs/01` & arahkan alur belajar ke pembandingan kasus nyata (mis. mengapa PLTS vs PLTP berbeda di wilayah tertentu). |
| **c. Alasan pengguna memakai** | **SAMAR** | `EDUEARTH_DEMO_CHECKLIST.md:61` mengklaim integrasi 4 pilar unggul dari Google Maps/artikel. Namun `learning_integration_helper.dart:415-562` mengisi konteks geografis & *trade-off* tiap pembangkit dengan **template statis per kategori** (`${plant.province}` saja). 4 tombol lintas-pilar ke `/learning/comparison?category=...` juga salah path (`route_names.dart:80` adalah `/energy-comparison`). | Keunggulan dibanding Google/Wikipedia rapuh: narasi per pembangkit repetitif di 5 kategori, dan jalur menuju pilar *Understand Impact* putus di 4 layar. | Perbaiki route ke `/energy-comparison`, dan ganti narasi generik dengan studi kasus spesifik pada pembangkit unggulan (atau jelaskan jelas sebagai karakter kategori). |
| **d. Fitur yang dibutuhkan** | **SAMAR** | `docs/01_PROJECT_OVERVIEW.md:24-52` mencantumkan **24 fitur**, ditambah widget ekstra di kode (`DesignSystemShowcasePage`, kartu 4 pilar, simulator lokal, `PlantPreviewSheet` yatim). | Terjadi *feature bloat* untuk proyek UTS solo: fitur pinggiran (Nearby GPS, Notification Center, 12 badge bookmark, Settings) menyedot kompleksitas tanpa memperkuat belajar. | Pangkas/tunda fitur di luar Core Loop (lihat [02_feature_audit.md](02_feature_audit.md)). Fokus pada ~12 fitur inti yang benar-benar terhubung. |
| **e. Tujuan awal pengembangan** | **SAMAR** | `docs/05_ROADMAP.md:6,77-78` mencatat ini proyek UTS solo target Android (iOS tidak diuji, tanpa Play Store). Namun `docs/01` & `AGENTS.md` awalnya menargetkan Android+iOS multilanguage dengan 24 fitur komersial. | Ambisi dokumen produk tidak seimbang dengan kapasitas 1 pengembang & tenggat kuliah, memicu banyak kompromi (64 koordinat perkiraan, demo fallback tidak lengkap). | Nyatakan tegas di dokumen utama: **Tahap sekarang = Academic MVP (Android, solo UTS)**, bukan produk rilis publik nasional. |
| **f. Output / hasil akhir** | **SAMAR** | `EDUEARTH_LEARNING_EVALUATION.md:31-100` merancang Pre/Post-Test (6 soal, target *N-Gain* `>= 0.45`), tetapi **TIDAK ADA di kode aplikasi**. Server hanya mencatat skor acak di `quiz_attempts`; progres baca (`reading_progress_provider.dart`) cuma lokal (`SharedPreferences`). | Klaim peningkatan pemahaman siswa tidak bisa diukur dari aplikasi sendiri. Enam dari 12 badge (`phase8:967-1060`) malah menghadiahi jumlah bookmark, bukan penguasaan materi. | Sediakan mode Pre-Check & Post-Test terukur di app (atau tandai baseline vs evaluasi per topik), simpan progres baca ke DB, dan ubah kriteria badge ke kelulusan topik. |
| **g. Rencana ke depan** | **TIDAK ADA** | `docs/05_ROADMAP.md` berhenti setelah Fase 0–6 dicentang `[x]`. Hanya ada 3 poin keterbatasan singkat di `EDUEARTH_IMPLEMENTATION_REPORT.md:73-81` (tanpa jadwal atau prioritas pasca-UTS). | Tidak ada pemisahan jelas antara cakupan UTS saat ini, iterasi uji sekolah, dan visi jangka panjang. **Kontradiksi data**: `IMPLEMENTATION_REPORT.md:78` menyebut belum ada Kuis 6 Modul 9, padahal migrasi `phase9` L253-386 & `DemoData` L336 sudah membuatnya. | Tetapkan roadmap 3 tahap (bagian 5 di bawah) dan selaraskan laporan dengan migrasi `phase9` yang sudah ada. |

## 2. Target Pengguna, Problem Statement, Tujuan, & Value Proposition

- **Target Pengguna (Maks. 2 Persona)**:
  1. **Persona Primer — Siswa SMA/SMK Kelas X–XII (Geografi, Fisika, IPAS, SMK Teknik EBT):** *Masalah:* memahami EBT hanya sebagai definisi hafalan tanpa tahu peta sebaran riil di Indonesia, arti kapasitas MW vs pasokan nyata, dan konsekuensi lingkungan tiap teknologi. *Alasan pakai EduEarth:* Google Maps tidak memilah status/kategori EBT & konteks geologi; YouTube/Wikipedia tercerai-berai, sering berbahasa Inggris, dan tidak menguji pemahaman lokal Indonesia per topik.
  2. **Persona Sekunder (Pendukung pasca-MVP) — Guru Mapel Geografi/Fisika/IPAS:** *Masalah:* butuh bahan ajar geospasial yang jujur soal keterbatasan data (`Lokasi perkiraan`). *Catatan FAKTA:* di kode saat ini **belum ada** peran/tampilan guru (`user_profiles` hanya punya `display_name`, `avatar_url`), sehingga MVP harus fokus 100% melayani Persona 1.
- **Problem Statement:** Siswa SMA/SMK mempelajari energi terbarukan secara terpisah dari kondisi geografis pembangkit nyata di Indonesia, perbedaan karakter operasi (*baseload* vs *intermiten*), serta *trade-off* ekologisnya, sedangkan sumber populer (Google Maps/Wikipedia/YouTube) tidak mengintegrasikan data pembangkit lokal, komparasi ilmiah, dan evaluasi dalam satu alur belajar.
- **Tujuan Umum:** Membangun aplikasi pembelajaran geospasial terstruktur bagi siswa SMA/SMK untuk memahami persebaran pembangkit, prinsip kerja, dan *trade-off* lingkungan energi terbarukan di Indonesia secara terukur.
- **Tujuan Khusus (SMART):**
  1. Menyediakan eksplorasi geospasial 128 pembangkit EBT Indonesia beserta pelabelan jujur status (`Beroperasi/Konstruksi/Rencana`) dan presisi koordinat (`Lokasi perkiraan`) yang dapat difilter dalam `<= 2` ketukan selama demo.
  2. Menyajikan 9 modul terkurasi dan matriks perbandingan 5 kategori EBT berbasis referensi `IPCC AR6 WGIII/IRENA/ESDM` tanpa dead-end navigasi sebelum sidang UTS.
  3. Menyediakan 6 paket kuis berpenilaian *server-side* (`submit_quiz_attempt`) dengan pembahasan ilmiah yang memetakan 100% modul ke kuis relevan.
  4. Mengukur capaian belajar siswa di dalam aplikasi melalui selisih skor awal vs skor akhir per topik (target kenaikan rata-rata `>= 20` poin / *N-Gain* `>= 0.45` saat uji coba 5–10 siswa).
- **Value Proposition (1 Kalimat):** *EduEarth membantu siswa SMA/SMK memahami energi terbarukan Indonesia dari titik pembangkit nyata di peta hingga perbandingan dampak lingkungan dan kuis evaluasi dalam satu alur belajar yang jujur terhadap akurasi data.*

## 3. Core Loop & Fitur di Luar Loop

**Core Loop (4 Langkah Tertutup):**
`Explore (Peta & Filter Kategori/Status -> Detail Pembangkit + Konteks Geografis)` → `Learn (Baca 1 dari 9 Modul terkait + Lihat Contoh Nyata)` → `Understand Impact (Bandingkan Karakteristik, Variasi Desain, & Trade-off 5 EBT)` → `Evaluate (Kerjakan Kuis Topik -> Baca Pembahasan -> Lihat Penguasaan LO-1 s.d. LO-4 di My Learning)`.

- **Fitur yang TIDAK mendukung Core Loop (kandidat pangkas/tunda):**
  1. **Nearby Plants (`nearby_plants_page.dart`):** Kurang relevan bagi siswa belajar sebaran nasional (mayoritas siswa perkotaan jauh dari PLTP/PLTB, butuh izin GPS ekstra).
  2. **Notification Center (`notifications_page.dart`):** Hanya papan pengumuman statis 3 item tanpa push/interaksi belajar (`20261110120001_phase9:210-242`).
  3. **Achievement berbasis bookmark (`phase8:967-1015`):** 6 dari 12 lencana memicu *hoarding* bookmark, bukan pemahaman konsep.
  4. **Settings (toggle glass), Edit Avatar bebas (`profile_page.dart`), & `DesignSystemShowcasePage`:** Utilitas kosmetik/developer yang tidak memengaruhi hasil belajar.
  5. **`PlantPreviewSheet` (`plant_preview_sheet.dart`):** Kode yatim—tidak pernah dipanggil karena `explore_map_page.dart` memakai `_MapPlantPreviewCard` inline.

## 4. Metrik Keberhasilan & Cara Pengukuran di Aplikasi

- **Kondisi Terukur Sekarang (FAKTA):** Hanya `quiz_attempts` (`score`, `correct_count`, `answers`, `completed_at`) yang tersimpan per pengguna di Supabase. `reading_progress_provider.dart` menyimpan progres scroll hanya di `SharedPreferences` lokal (hilang saat ganti perangkat/hapus app), dan Pre/Post-Test `EDUEARTH_LEARNING_EVALUATION.md` masih berupa soal di dokumen Markdown.
- **Rancangan Pengukuran Konkret di App:**
  1. **Kenaikan Skor (Baseline vs Evaluasi):** Tandai percobaan pertama pada kuis diagnostik awal sebagai `pre` dan percobaan pasca-membaca modul terkait sebagai `post` pada `quiz_attempts`, lalu tampilkan delta skor di `MyLearningPage`.
  2. **Ketuntasan Pilar Belajar per Pengguna:** Sinkronkan progres baca materi (`>= 85%`) dan akses modul perbandingan ke tabel progres server agar `MyLearningPage` menampilkan rasio nyata: *Pembangkit Dieksplorasi + Modul Tuntas + Kuis Lulus (`>= 75`)*.
  3. **Indikator Penguasaan LO-1 s.d. LO-4:** Kelompokkan hasil soal kuis & modul menjadi 4 indikator kompetensi di `MyLearningPage` menggantikan statistik sekadar jumlah bookmark.

## 5. Roadmap Pengembangan 3 Tahap

| Tahap | Cakupan Masuk (*In-Scope*) | Di Luar Cakupan (*Out-of-Scope*) |
|---|---|---|
| **Tahap 1: MVP Tugas Kuliah (Sekarang)** | Perbaikan 4 broken routes perbandingan & aset hilang, penyelarasan narasi SMA/SMK di Onboarding/Home/About, Core Loop 4 pilar, 128 data berlabel jujur, 9 modul + 6 kuis terverifikasi, penyederhanaan fitur pinggiran. | Fitur sosial/komentar, panel admin in-app, Nearby GPS sebagai menu utama, Notification Center, mode offline tile peta penuh, iOS build, dual-language. |
| **Tahap 2: Pengembangan Lanjutan (Uji Sekolah 1–3 Bulan)** | Validasi silabus bersama guru Geografi/Fisika/SMK; fitur Pre/Post-Test in-app; sinkronisasi progres baca ke Supabase; verifikasi angka bauran nasional ESDM & penajaman koordinat 64 pembangkit perkiraan. | LMS komersial, pembayaran, gamifikasi leaderboard publik, API real-time SCADA pembangkit. |
| **Tahap 3: Visi Jangka Panjang** | Mode Guru & Kelas (pantau skor/N-Gain siswa), pembaruan berkala data RUPTL/ESDM, dukungan iOS & Bahasa Inggris. | Prediksi kelistrikan real-time tingkat rumah tangga. |

## 6. Antisipasi 6 Pertanyaan Sulit Dosen Saat Sidang/Demo

1. **T: "Kenapa fiturnya sampai 24 macam? Apa fokusnya?"**
   **J:** *Jujur: 24 fitur itu warisan rencana awal yang terlalu lebar. Kini aplikasi dipusatkan ke Core Loop 4 pilar (Explore–Learn–Understand Impact–Evaluate), dan pada rencana perbaikan fitur pinggiran (notifikasi statis, badge bookmark, nearby GPS) akan disederhanakan agar fokus ke pembelajaran siswa SMA/SMK.*
2. **T: "Di mana bukti aplikasi ini benar-benar untuk siswa SMA/SMK, bukan app umum?"**
   **J:** *Secara konsep & konten 9 modul + perbandingan LCA memang selaras dengan materi Fisika/Geografi/IPAS SMA-SMK (`EDUEARTH_LEARNING_EVALUATION.md:20-27`). Namun kami akui layar Onboarding dan Register (`onboarding_page.dart`, `register_page.dart`) masih bernarasi umum—itu masuk daftar perbaikan prioritas.*
3. **T: "Apakah penjelasan geografis di detail pembangkit spesifik per lokasi atau template?"**
   **J:** *Fakta kode (`learning_integration_helper.dart:400-562`): penjelasan masih berupa template per kategori energi dengan nama provinsi dinamis, bukan studi kasus unik per 128 pembangkit. Aplikasi memakai bahasa kualitatif berhati-hati ("umumnya") dan menautkan `source_url` tiap pembangkit agar tidak mengarang klaim lokal.*
4. **T: "Separuh data (64/128) berlabel 'Lokasi perkiraan' dan total nasional belum diverifikasi. Layak pakai?"**
   **J:** *Justru ketransparanan itulah bagian literasi data (`LO-1`): 22 bioenergi dan sebagian proyek Rencana memang hanya punya data wilayah administratif di sumber resmi (`DATA_LOG.md:31-34,61`), sehingga diberi badge `Lokasi perkiraan` dan diurutkan di bawah titik `operating + exact` pada contoh belajar.*
5. **T: "Laporan menyebut ada Pre/Post-Test & N-Gain, mana fiturnya di aplikasi?"**
   **J:** *Saat ini Pre/Post-Test masih berbentuk instrumen tertulis eksternal (`EDUEARTH_LEARNING_EVALUATION.md`), sedangkan di app baru tersedia 6 kuis evaluasi server-side (`submit_quiz_attempt`). Ini celah konsep yang akan dijembatani dengan penanda percobaan awal vs pasca-belajar.*
6. **T: "Mengapa tidak pakai Google Maps SDK & penilaian kuis lokal di Flutter?"**
   **J:** *OpenStreetMap (`flutter_map`) bebas biaya API key dan Google Maps tetap dibuka lewat deep link untuk navigasi eksternal. Penilaian kuis ditaruh di PostgreSQL RPC (`quiz_answer_keys` tanpa policy RLS client) agar kunci jawaban tidak pernah terbaca atau dimanipulasi dari APK.*
