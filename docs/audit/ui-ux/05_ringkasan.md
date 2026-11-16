# Ringkasan Eksekutif Audit UI/UX — EduEarth

> **Lingkup:** Audit *read-only* terhadap kode & 44 screenshot (`390×844` DPR `2` pada `flutter build web`; tanpa emulator/perangkat Android fisik). Alur gameplay kuis & pasca-login diaudit dari kode.

## 1. Lima Masalah Terbesar
1. **Jebakan offline >30 detik (`G-01` | P1):** Retry otomatis Riverpod 3 menahan layar di `LoadingView` >30 detik saat Supabase gagal/offline (21 request gagal tercatat) tanpa memunculkan `ErrorView` & tombol *Coba Lagi*.
2. **Kegagalan kontras WCAG AA (`D-01` | P1):** `#FFFFFF` di `#22C55E` (`2.28:1` pada tombol kirim kuis & badge notif), tautan `#22C55E` (`2.11–2.28:1`), ikon surya `#FACC15` di `#FEF9C3` (`1.43:1`), `textMuted` (`3.80:1`), dan nav nonaktif (`3.25:1`).
3. **Overflow & pemotongan teks di viewport HP `390dp` (`G-02` | P1):** Badge Onboarding 3 (`Umpan Balik Ins...`), tabrakan header & klip `✨` di `Achievements`, `"Perbanding-an"` terbelah di Home, chip `Bioenergi` tersembunyi tanpa petunjuk, serta `Panas Bu...` dan subtitle header terpotong.
4. **Friksi Core Loop & Mode Tamu (`A-03`, `A-05`, `A-02` | P1–P2):** Footer sticky dua tombol Google Maps (`~145dp`) di `PlantDetailPage` mendorong pengguna keluar aplikasi; Mode Tamu diblokir ke `/login` setelah 6 tap ke Kuis meski progres bar materi terus naik (`79%`), dan tak punya rute ke `/settings`.
5. **Peta Nusantara terpotong & tanpa clustering (`E-01`, `E-02` | P1–P2):** `zoom 4.6` memotong Sumatra/Jawa Barat & Papua; 85+ marker bertumpuk di Jawa; kartu pratinjau otomatis memilih `East Bali Solar Farm` (`Lokasi perkiraan`).

## 2. Lima Quick Win (Usaha `S`, Dampak Langsung)
1. Matikan/batasi auto-retry Riverpod di `ProviderScope` agar `ErrorView` tampil <3 detik saat offline (`G-01`).
2. Bungkus `Row` dengan `Expanded`/`Wrap` serta beri `maxLines: 2` & penanda scroll di 6 titik cacat `390dp` (`G-02`).
3. Terapkan `#15803D` (`5.02:1`) untuk seluruh tombol/tautan/badge hijau, `#B45309` (`4.51:1`) untuk surya, dan gelapkan `textMuted`/nav nonaktif ke `>= 4.5:1` (`D-01`).
4. Terjemahkan 5 tab `GlassBottomNav` ke Indonesia (`Jelajah`, `Belajar`, `Beranda`, `Kuis`, `Profil`) & seragamkan status `Beroperasi` (`C-01`, `C-02`).
5. Tambah rute `/settings` di `ProfilePage` Mode Tamu, ubah label progres Tamu menjadi pratinjau jujur, dan ganti auto-preview peta ke titik `exact` unggulan atau ringkasan jumlah titik (`A-02`, `A-05`, `E-02`).

## 3. Penilaian Skor (`/10`) *(OPINI berbasis bukti `01_`–`04_`)*
| Dimensi | Skor | Alasan Singkat |
|---|---|---|
| **Konsistensi** | **5.5 / 10** | Konsep Nature Tech & siluet `GlassBottomNav` selaras `moodboard.png`, tetapi terpecah oleh 118 literal warna, 3 hijau primer berbeda, 80+ ukuran `<12px`, `OutlinedButton` manual di 6 layar, `EmptyView` selalu tidur, dan istilah campuran ID–EN. |
| **Kemudahan** | **6.5 / 10** | Core Loop 4 pilar terhubung dan materi belajar kaya simulator/flashcard serta kejujuran sumber, namun terhambat footer Maps `~145dp` di `PlantDetail`, 7 blok bertumpuk di Home, peta tanpa klaster, dan kebuntuan Mode Tamu di Kuis. |
| **Aksesibilitas** | **4.0 / 10** | Banyak kontrol penting di bawah WCAG AA (`1.43:1`–`3.80:1`), target sentuh `<48dp` (`ScreenHeaderAction`, tombol preview peta, strip soal kuis, edit avatar, tautan teks), hanya 3 `Semantics`, dan teks sering terpotong di `390dp`. |
| **Kesiapan Demo** | **6.5 / 10** | Konten & keamanan kuis server solid saat dijalankan dalam status login; perbaikan `G-01`, `G-02`, `D-01`, dan framing peta wajib dilakukan dulu agar aplikasi tampak matang di layar ponsel presentasi. |

## 4. Urutan Layar Demo Terbaik (~5 Menit, Akun Sudah Login)
`Home` (tunjukkan 4 Pilar & 5 EBT) → `ExploreMap` (filter Surya/Beroperasi, ketuk `PLTS Terapung Cirata`) → `PlantDetail` (kapasitas, dampak, sumber data) → `EnergyComparison` (Surya vs Panas Bumi) → `LearningDetail` (simulator 3 tahap + Flashcard) → `QuizGameplay` & `QuizResult` (penilaian RPC server) → `MyLearning` / `Achievements`.

## 5. Keputusan yang Perlu Diambil Pemilik Proyek (Maks. 5)
1. **Kuis di Mode Tamu (`A-05`):** Tetap mewajibkan login penuh sebelum membuka kuis, atau mengizinkan 1 kuis contoh/pre-check lokal tanpa simpan skor ke Supabase?
2. **Persistensi Mode Tamu (`A-01`):** Apakah pilihan *Jelajahi sebagai Tamu* disimpan secara lokal agar tidak mengulang layar `/login` setiap buka ulang aplikasi?
3. **Prioritas Footer `PlantDetailPage` (`A-03`):** Setuju meringkas dua tombol Google Maps menjadi 1 CTA Core Loop (*Pelajari & Bandingkan EBT*) + 1 tombol Maps?
4. **Bahasa `GlassBottomNav` (`C-01`):** Setuju menerjemahkan 5 label tab ke Indonesia (`Jelajah`, `Belajar`, `Beranda`, `Kuis`, `Profil`)?
5. **Penyeragaman Warna Aksi Primer (`B-01`, `D-01`):** Setuju menjadikan `#15803D` warna primer utama di `AppTheme` menggantikan `#22C55E` untuk seluruh tombol teks putih dan tautan demi memenuhi WCAG AA?
