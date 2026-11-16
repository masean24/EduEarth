# Audit 24 Fitur EduEarth — Pemangkasan & Fokus Core Loop (Tahap 1)

> Daftar fitur mengacu persis pada urutan **1–24** di `docs/01_PROJECT_OVERVIEW.md:24-52`. Penilaian didasarkan pada dukungan terhadap **Core Loop 4 Pilar** (*Explore → Learn → Understand Impact → Evaluate*) untuk proyek UTS solo.

## 1. Tabel Audit 24 Fitur Resmi

| No | Fitur (`01_PROJECT_OVERVIEW.md`) | Mendukung Tujuan? | Alasan Berbasis Kondisi Kode & Konsep | Rekomendasi |
|---|---|---|---|---|
| 1 | **Splash Screen** (`splash_page.dart`) | **Pendukung** | Menjaga transisi awal cek sesi & onboarding (`SharedPreferences`), ringan & singkat. | **Pertahankan** |
| 2 | **Onboarding** (`onboarding_page.dart`) | **Inti** | Gerbang pembentuk ekspektasi pengguna, namun 3 slide saat ini masih memakai kerangka lama 3 pilar tanpa menyebut konteks SMA/SMK & *Understand Impact*. | **Sederhanakan** (selaraskan teks ke 4 pilar & target SMA/SMK) |
| 3 | **Login dan Register** (`login_page.dart`, `register_page.dart`) | **Pendukung** | Dibutuhkan oleh Supabase Auth agar `quiz_attempts` & `bookmarks` terikat akun (`app_router.dart` memaksa login bila Supabase aktif), tetapi menutup akses eksplorasi cepat saat demo bila gagal login. | **Sederhanakan** (pertahankan email+password; pertimbangkan mode *Lihat Peta Tanpa Login* hanya untuk eksplorasi baca) |
| 4 | **Home Dashboard** (`home_dashboard_page.dart`) | **Inti** | Sudah memuat kartu *Alur Belajar 4 Pilar*, 5 kategori dengan rincian jujur status pembangkit (`operating/construction/planned`), dan rekomendasi pembangkit. | **Pertahankan** |
| 5 | **Explore Map** (`explore_map_page.dart`) | **Inti** | Pilar 1 (*Explore*): memvisualisasikan sebaran 128 pembangkit di Indonesia memakai OSM tanpa mengandalkan API berbayar. | **Pertahankan** |
| 6 | **Map Filter** (`explore_map_page.dart`) | **Inti** | Krusial untuk literasi geospasial (`LO-1`): memisahkan 5 kategori EBT serta membedakan pembangkit `Beroperasi`, `Konstruksi`, dan `Rencana`. | **Pertahankan** |
| 7 | **Plant Preview (bottom sheet)** (`plant_preview_sheet.dart`) | **Pendukung** | **Temuan kode:** widget `PlantPreviewSheet` di `plant_preview_sheet.dart` **tidak pernah dipanggil**; `explore_map_page.dart` memakai kartu pratinjau inline `_MapPlantPreviewCard`. Duplikasi konsep. | **Hapus** file `PlantPreviewSheet` yatim, pertahankan preview ringkas inline di peta |
| 8 | **Plant Detail (+ Buka Google Maps)** (`plant_detail_page.dart`) | **Inti** | Jembatan utama *Explore → Learn → Understand Impact* (kapasitas, status, presisi koordinat, sumber, materi/perbandingan terkait), walau konten geografis masih template per kategori. | **Sederhanakan** (perbaiki broken route perbandingan & pertegas bahwa penjelasan bersifat karakteristik kategori + tautan sumber) |
| 9 | **Nearby Plants** (`nearby_plants_page.dart`) | **Tidak perlu** | Untuk siswa belajar geografi energi nasional, mencari pembangkit dalam radius GPS justru sering menghasilkan hasil kosong/tidak representatif (banyak daerah tanpa pembangkit `>= 1 MW`), dan menambah kompleksitas izin GPS. | **Tunda** (sembunyikan dari menu utama MVP agar fokus ke peta Nusantara) |
| 10 | **Learning Dashboard** (`learning_dashboard_page.dart`) | **Inti** | Pilar 2 (*Learn*): pusat akses 9 modul terkurasi dengan filter kategori dan fitur lanjut baca (*Terakhir Dibaca*). | **Pertahankan** |
| 11 | **Energy Category** (`energy_category_page.dart`) | **Pendukung** | Menampilkan statistik kategori (`exact` vs `approximate`, 3 provinsi teratas) + modul per kategori, tapi agak tumpang tindih dengan filter di Learning Dashboard & Explore Map. | **Sederhanakan** (perbaiki route perbandingan; jadikan ringkas sebagai halaman topik) |
| 12 | **Learning Detail** (`learning_detail_page.dart`) | **Inti** | Inti bacaan materi, *Flashcard*, tautan ke 3 contoh pembangkit nyata, dan rekomendasi kuis (`SmartQuizResolver`). Mengandung aset gambar yang belum ada (`eco_map.png`, `categories/*.png`). | **Pertahankan** (rapikan aset hilang, sinkronkan progres baca bila memungkinkan) |
| 13 | **Bookmark** (`bookmarks_page.dart`) | **Pendukung** | Berguna untuk menyimpan materi/pembangkit tugas sekolah, meski tidak sepenting progres penguasaan materi dan kuis. | **Pertahankan** (secara ringkas, jangan jadikan syarat utama gamifikasi) |
| 14 | **Quiz Dashboard** (`quiz_dashboard_page.dart`) | **Inti** | Pilar 4 (*Evaluate*): menampilkan 6 topik kuis dan riwayat skor pengguna sebagai pusat evaluasi. | **Pertahankan** |
| 15 | **Quiz Gameplay** (`quiz_gameplay_page.dart`) | **Inti** | Eksekusi kuis 1–6 terintegrasi penilaian *server-side* (`submit_quiz_attempt` RPC); kunci jawaban aman di server. | **Pertahankan** |
| 16 | **Quiz Result** (`quiz_result_page.dart`) | **Inti** | Menyajikan skor, **pembahasan ilmiah per soal**, serta tombol lanjutan/remedial kembali ke modul materi & perbandingan energi. | **Pertahankan** (perbaiki broken route `/learning/comparison`) |
| 17 | **Profile** (`profile_page.dart`) | **Pendukung** | Cukup sebagai identitas akun + tombol keluar + ringkasan belajar. Saat ini dibebani hero rank berbasis lencana, etalase badge, dan akses ke banyak menu utilitas. | **Sederhanakan** (gabungkan fokus ke ringkasan capaian belajar & akun) |
| 18 | **My Learning** (`my_learning_page.dart`) | **Inti** | Satu-satunya layar tempat melihat *output akhir* pengguna (riwayat kuis, progres 4 pilar, materi selesai). Namun progres baca masih lokal & belum ada pembandingan skor awal vs akhir. | **Pertahankan** & tingkatkan menjadi ringkasan metrik hasil belajar |
| 19 | **Settings** (`settings_page.dart`) | **Tidak perlu** | Cuma berisi 1 toggle `"Kurangi efek glass"` yang tidak memengaruhi tujuan edukasi maupun nilai ujian siswa; `DesignSystemShowcase` sudah disembunyikan. | **Hapus** atau lebur menjadi satu baris kecil di `Profile` |
| 20 | **About EduEarth** (`about_page.dart`) | **Pendukung** | Sangat penting secara **integritas akademik**: memuat atribusi GEM/ESDM/OSM, cakupan `>= 1 MW`, dan keterbatasan 22 titik bioenergi `approximate`. | **Pertahankan** (bisa diakses ringkas dari Profile) |
| 21 | **Global Search** (`global_search_page.dart`) | **Pendukung** | Memudahkan siswa/guru mencari cepat nama pembangkit tertentu (mis. *Cirata*, *Kamojang*) atau materi tanpa menyisir peta/daftar. | **Pertahankan** |
| 22 | **Achievement** (`achievements_page.dart`) | **Tidak perlu** | Implementasi saat ini (`phase8:967-1060`) berat ke jumlah bookmark (6 dari 12 badge) & percobaan berulang, berisiko memicu "klik demi badge" bukan pemahaman EBT. | **Tunda** atau **Sederhanakan** ke maksimal 4 pencapaian berbasis ketuntasan 4 pilar |
| 23 | **Notification Center** (`notifications_page.dart`) | **Tidak perlu** | Hanya berisi 3 catatan panduan statis di tabel `notifications` (`phase9:210-242`) dengan status terbaca lokal; tidak ada notifikasi personal/pengingat belajar. | **Hapus** (pindahkan panduan 4 pilar ke dialog bantuan / *About*) |
| 24 | **Energy Comparison** (`energy_comparison_page.dart`) | **Inti** | Wujud langsung **Pilar 3 (*Understand Impact*)**: membandingkan 5 EBT pada 11 atribut teknis & *trade-off* lingkungan berbasis IPCC/IRENA/ESDM. | **Pertahankan** (dan perbaiki 4 broken route menuju halaman ini) |

## 2. Fitur Tambahan di Kode (Di Luar Nomor 1–24)

- **Alur Belajar 4 Pilar & `SmartQuizResolver`** (`home_dashboard_page.dart`, `learning_integration_helper.dart`): **Inti — Pertahankan**, karena justru inilah perekat konsep yang membedakan EduEarth dari kumpulan artikel & peta biasa.
- **`ReadingProgressNotifier`** (`reading_progress_provider.dart`) & **`_understoodChapters`** (`learning_detail_page.dart`): **Pendukung — Sederhanakan**; `_understoodChapters` cuma state memori sementara (hilang saat tutup halaman) dan progres scroll cuma lokal.
- **`DesignSystemShowcasePage`** (`design_system_showcase_page.dart`, `/design-showcase`): **Tidak perlu — Hapus** dari build/router rilis (hanya artefak bantu Fase 0 yang kini sudah tidak punya tombol navigasi dan melewati redirect login di `app_router.dart:57`).

## 3. Rekap Pemangkasan Scope MVP Kuliah

| Keputusan | Jumlah (dari 24 fitur) | Daftar Nomor Fitur |
|---|---|---|
| **Pertahankan** (Inti / Atribusi) | **14 fitur** | `#1, #4, #5, #6, #10, #12, #13, #14, #15, #16, #18, #20, #21, #24` |
| **Sederhanakan** | **5 fitur** | `#2 Onboarding, #3 Login/Register, #8 Plant Detail, #11 Energy Category, #17 Profile` |
| **Tunda (Pasca-UTS / Uji Sekolah)** | **2 fitur** | `#9 Nearby Plants, #22 Achievement (atau ringkas ke 4 badge kompetensi)` |
| **Hapus / Lebur dari MVP** | **3 fitur** | `#7 PlantPreviewSheet (kode yatim), #19 Settings (lebur ke Profile), #23 Notification Center` |

> **Catatan cakupan ekstra di kode:** `Alur Belajar 4 Pilar` & `SmartQuizResolver` wajib dipertahankan; `ReadingProgressNotifier` perlu disederhanakan/disinkronkan (tanpa `_understoodChapters` semu); `DesignSystemShowcasePage` disarankan dihapus dari router rilis. Total audit resmi: `14 + 5 + 2 + 3 = 24 fitur`.
