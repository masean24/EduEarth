# Rencana Perbaikan Prioritas UI/UX — EduEarth

> **Prinsip prioritas:** Fokus pada polesan berdampak besar dengan usaha kecil/sedang untuk mempertajam *Core Loop* dan kesiapan demo; **tanpa redesain total** dan **tanpa fitur baru**. ID merujuk pada `02_temuan.md`.

## 1. Wajib Sebelum Demo (Dampak Tinggi, Risiko Rendah)

### 1.1 Perbaiki Cacat Tata Letak & Overflow di Layar `390dp` (Usaha: S)
- **[G-02] Onboarding 3 & Achievements:** Bungkus baris badge `onboarding_page.dart` (`Umpan Balik Ins...`) dan header `achievements_page.dart` (`Daftar Lencana` + `Ketuk badge terbuka...`) dengan `Expanded`/`Flexible` + `Wrap` agar tidak bertabrakan atau terpotong di tepi kanan.
- **[G-02] Home Dashboard & Comparison:** Beri ruang label `Perbandingan & Dampak` di `home_dashboard_page.dart` agar kata tidak patah (`Perbanding-an`), sejajarkan tinggi baris `Panas Bumi` pada kartu kategori, dan beri ruang 2 baris atau label singkat agar `Panas Bu...` tidak terpotong di `energy_comparison_page.dart`.
- **[G-02] PlantDetail, Chip 5 Kategori, & Header:** Izinkan `maxLines: 2` untuk nama operator pada `plant_detail_page.dart` dan subtitle di `ScreenHeaderBar` (`screen_header.dart`), serta tambahkan indikator scroll (gradasi/ikon panah) pada strip 5 chip kategori di `ExploreMap`, `LearningDashboard`, dan `EnergyComparison` agar `Bioenergi` terlihat ada.

### 1.2 Perbaiki Kontras WCAG AA & Keterbacaan Aksi Utama (Usaha: S)
- **[D-01, B-01] Hijau Aksi Terpadu (`#15803D`):** Ganti warna tombol kirim di `quiz_gameplay_page.dart` (`#22C55E`, `2.28:1`), badge `ScreenHeaderAction`, `AppTheme.elevatedButtonTheme` (`app_theme.dart`), dan tautan hijau (`Lupa Kata Sandi`, `Buka Tautan Sumber`, `Tentang EduEarth`) menjadi `0xFF15803D` (`5.02:1`).
- **[D-01] Ikon Surya, Nav Nonaktif, & Teks Sekunder:** Ganti ikon/teks surya di latar kuning muda dari `#FACC15`/`#D97706` ke `#B45309` (`4.51:1`), gelap-kan `AppColors.textMuted` (`3.80:1`) dan warna nav nonaktif `0xFF7B8D9E` (`3.25:1`) hingga `>= 4.5:1`.

### 1.3 Bebaskan Jebakan Offline >30 Detik & Poles Pintu Masuk Demo (Usaha: S–M)
- **[G-01] Retry Riverpod Saat Offline:** Matikan/batasi `retry` otomatis Riverpod pada `ProviderScope` (inisialisasi aplikasi) agar `ErrorView` dengan tombol *Coba Lagi* langsung tampil <3 detik saat internet mati, bukan terjebak spinner >30 detik.
- **[E-01, E-02] Framing Awal Peta:** Atur kamera awal `ExploreMapPage` ke bounds Indonesia (`~zoom 3.8` / `CameraFit.bounds`) agar Sumatra–Papua tampak utuh di layar `390dp`, dan ganti auto-preview acak (`East Bali` lokasi perkiraan) dengan titik `exact` unggulan (mis. `PLTS Terapung Cirata`) atau kartu ringkasan jumlah lokasi.
- **[A-03] Ringkas Footer `PlantDetailPage`:** Ganti dua tombol Maps besar (`~145dp`) di footer sticky menjadi 1 CTA Core Loop (*Pelajari & Bandingkan EBT*) + 1 tombol sekunder *Buka Maps* (dengan opsi cari sebagai aksi ringkas), agar alur belajar tak terputus ke luar aplikasi.
- **[C-01, C-02, B-04] Bahasa & Maskot Kontekstual:** Terjemahkan 5 tab `GlassBottomNav` ke Indonesia (`Jelajah`, `Belajar`, `Beranda`, `Kuis`, `Profil`), samakan istilah status (`Aktif` → `Beroperasi`), perbaiki subjudul Onboarding 1 (`Sumber Tercatat`), dan tambah `assetPath` netral pada `EmptyView` (`empty_view.dart`) agar Eco tidur tidak muncul saat pencarian aktif atau Mode Tamu.
- **[A-02, A-05] Mode Tamu Jujur & Aman:** Tambahkan tautan `/settings` pada `ProfilePage` Mode Tamu agar tamu di HP kelas bawah dapat mengurangi efek glass, dan ubah teks progres di `LearningDetailPage` dari `Mode Tamu (79%)` menjadi label pratinjau agar tidak memberi harapan palsu.

---

## 2. Boleh Ditunda (Pasca-Demo / Sprint Berikutnya)

- **[E-01] Clustering Marker Peta (M):** Tambahkan pengelompokan marker (`flutter_map_marker_cluster` atau klaster per wilayah) saat `zoom < 6` di `explore_map_page.dart` agar 85+ titik di Jawa/Sumatra tidak bertumpuk.
- **[D-02] Naikkan Seluruh Tap Target `< 48dp` (M):** Bungkus `ScreenHeaderAction` (`40dp`), tombol kartu preview peta (`29–32dp`), kotak nomor soal kuis (`34×32dp`), edit avatar (`28dp`), dan tautan teks (`32dp`) agar memenuhi minimum `48×48dp`.
- **[B-01, B-02, B-03] Konsolidasi Design Token & Komponen Bersama (M):** Migrasikan sisa 118 `Color(0x...)` dan 80+ `fontSize < 12` inline ke `app_colors.dart` & `app_text_styles.dart`, satukan `OutlinedButton.icon` di 6 layar menjadi `SecondaryButton`, seragamkan kapsul `GlobalSearchPage` ke `AppRadius.pill`, dan bersihkan helper aset `cat_*` mati.
- **[A-01, A-04, A-05, F-01] Penajaman Core Loop & Kuis (M):** Tambah tombol *Jelajahi sebagai Tamu* di akhir `OnboardingPage` & samakan tombol tamu di `RegisterPage`; tampilkan kartu pembangkit lebih atas di `HomeDashboardPage`; ubah tombol melayang kanan bawah `ExploreMap` menjadi *Pusatkan ke Lokasi Saya*; tambah banner peringatan 30 detik terakhir & penanda `Pre-Check`/`Evaluasi` di kuis; naikkan pintasan *Bandingkan 5 EBT* di `LearningDetailPage`.
- **[D-03, H-01, E-02] Aksesibilitas & Efisiensi Render (M):** Tambah `Semantics` bermakna di seluruh kartu/navigasi interaktif, jeda ticker animasi `PlantDetailPage` saat offscreen (`TickerMode`), serta tambah `TileLayer.errorTileCallback` + banner ubin offline di peta.
- **Verifikasi Visual Pasca-Login (S):** Ambil screenshot dan inspeksi langsung layar `QuizGameplayPage`, `QuizResultPage`, `EditProfileBottomSheet`, dan `BookmarksPage`/`MyLearningPage` mode login pada emulator/perangkat Android fisik.

---

## 3. Jangan Disentuh (Sudah Baik / Risiko Regresi Tinggi)

- **Arsitektur & Routing Utama:** Struktur 5-branch `StatefulShellRoute` di `GoRouter` (`lib/routes/app_router.dart`), urutan fitur Riverpod, dan keamanan penilaian kuis via RPC server (`submit_quiz_attempt` + RLS tertutup pada `quiz_answer_keys`) sudah tepat — jangan diubah atau dipindah ke client.
- **Siluet Bottom Nav & Konsep Visual Nature Tech:** Komposisi melayang `Home` di tengah pada `GlassBottomNav` selaras dengan `docs/design/moodboard.png` — cukup poles label & warna, jangan rombak layout bar atau mengganti palet hijau utama.
- **Atribut Kejujuran Data:** Penanda `Lokasi perkiraan`, tanggal `data_as_of`, tautan `source_url`, dan halaman `AboutPage` sudah kuat secara konsep edukasi dan etika data — pertahankan utuh.
- **Skeleton Loader Total & Freezed/Code-Gen:** Jangan mengganti seluruh `LoadingView` menjadi skeleton per-layar sebelum demo atau menambah `freezed`/`build_runner` (melanggar batas arsitektur ringan `AGENTS.md`).
