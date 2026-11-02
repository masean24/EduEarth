# Daftar Aset Visual EduEarth (`docs/design/ASSETS.md`)

Dokumen ini merinci seluruh slot gambar, ilustrasi, dan ekspresi maskot **Eco** berdasarkan referensi `docs/design/moodboard.png`.

> **Catatan Implementasi Saat Ini:**  
> Kode aplikasi menggunakan komponen `SoftImagePlaceholder` (`lib/core/widgets/common/soft_image_placeholder.dart`) yang otomatis mencoba memuat file aset lokal (jika sudah tersedia di folder `assets/images/`) atau menampilkan **placeholder berwarna lembut dengan ikon** jika file aset belum dimasukkan. Tidak ada gambar yang diunduh sembarangan dari internet.

---

## 1. Logo & Branding (`assets/images/branding/`)

| Nama File | Lokasi Pemakaian | Ukuran Disarankan | Format | Keterangan |
|---|---|---|---|---|
| `logo_eduearth.png` | Splash Screen, Onboarding, About Page | `512 × 512 px` (1:1) | PNG transparan | Logo bola bumi dengan daun hijau (`forestGreen` & `freshGreen`) |
| `splash_landscape.png` | Latar bawah Splash / Onboarding | `1080 × 720 px` (3:2) | PNG transparan | Ilustrasi bukit hijau dengan kincir angin dan maskot Eco |

---

## 2. Ekspresi Maskot "Eco" (`assets/images/mascot/`)

Digunakan pada Onboarding, Header Pusat Edukasi, Quiz Result, Empty State, dan Avatar Default Profil.

| Nama File | Ekspresi (Moodboard) | Pemakaian Utama | Ukuran Disarankan | Format |
|---|---|---|---|---|
| `eco_wave.png` | Halo / Melambai | Onboarding & Sapaan Home | `512 × 512 px` | PNG transparan |
| `eco_happy.png` | Happy (Senyum) | Avatar default profil, ulasan jawaban benar | `256 × 256 px` | PNG transparan |
| `eco_excited.png` | Excited (Semangat) | Banner rekomendasi / skor kuis tinggi | `256 × 256 px` | PNG transparan |
| `eco_thinking.png` | Thinking (Berpikir `?`) | Petunjuk kuis, pembahasan soal yang salah | `256 × 256 px` | PNG transparan |
| `eco_congrats.png` | Congrats! (Piala) | Halaman Hasil Kuis (lulus) & Achievement | `384 × 384 px` | PNG transparan |
| `eco_sad.png` | Sad (Sedih) | Error state / skor kuis perlu ditingkatkan | `256 × 256 px` | PNG transparan |
| `eco_sleepy.png` | Sleepy (`zZ`) | Empty state (belum ada bookmark / hasil pencarian kosong) | `256 × 256 px` | PNG transparan |
| `eco_reading.png` | Membaca Buku + Toga | Header "Pusat Edukasi" (Learning Dashboard) | `384 × 384 px` | PNG transparan |

---

## 3. Banner & Ilustrasi Kategori (`assets/images/illustrations/`)

| Nama File | Pemakaian | Ukuran Disarankan | Format | Keterangan |
|---|---|---|---|---|
| `banner_explore_energy.png` | Hero Banner Home Dashboard ("Explore Renewable Energy") | `800 × 400 px` (2:1) | PNG / WebP | Ilustrasi panel surya, kincir angin, dan langit cerah |
| `cat_solar.png` | Thumbnail materi / kategori Energi Surya (PLTS) | `256 × 256 px` (1:1) | PNG transparan | Ilustrasi matahari / panel surya |
| `cat_hydro.png` | Thumbnail materi / kategori Energi Air (PLTA) | `256 × 256 px` (1:1) | PNG transparan | Ilustrasi tetesan air / bendungan |
| `cat_wind.png` | Thumbnail materi / kategori Energi Angin (PLTB) | `256 × 256 px` (1:1) | PNG transparan | Ilustrasi turbin angin |
| `cat_geothermal.png` | Thumbnail materi / kategori Panas Bumi (PLTP) | `256 × 256 px` (1:1) | PNG transparan | Ilustrasi panas bumi |
| `cat_bioenergy.png` | Thumbnail materi / kategori Bioenergi | `256 × 256 px` (1:1) | PNG transparan | Ilustrasi daun & biomassa |

---

## 4. Cara Mengaktifkan Aset Setelah File Disiapkan

1. Buat folder `assets/images/branding/`, `assets/images/mascot/`, dan `assets/images/illustrations/` di root proyek.
2. Letakkan file PNG/WebP sesuai nama di tabel atas.
3. Pastikan bagian `flutter -> assets` di `pubspec.yaml` memuat:
   ```yaml
   flutter:
     uses-material-design: true
     assets:
       - assets/images/branding/
       - assets/images/mascot/
       - assets/images/illustrations/
   ```
4. Komponen `SoftImagePlaceholder` akan langsung menampilkan gambar tersebut tanpa perlu mengubah ulang kode layar.

