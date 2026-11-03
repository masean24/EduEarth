# Daftar Aset Visual EduEarth (`docs/design/ASSETS.md`)

Dokumen ini merinci seluruh slot gambar, ilustrasi, dan ekspresi maskot **Eco** berdasarkan referensi `docs/design/moodboard.png` yang telah dikelompokkan ke dalam **Prioritas A, B, dan C**.

> **Status Implementasi:**  
> Seluruh aset pada Prioritas A, B, dan C telah diekstrak dari *Brand & Mascot Asset Sheet* resolusi tinggi (`assets/design/asset_sheet_hd.jpg`) ke dalam folder `assets/images/` dan dimuat melalui komponen `SoftImagePlaceholder` (`lib/core/widgets/common/soft_image_placeholder.dart`). Jika suatu file aset belum tersedia, `SoftImagePlaceholder` otomatis menampilkan *fallback* placeholder berwarna lembut dengan ikon vektor tanpa error.

---

## Prioritas A — Identitas Brand, Splash, Onboarding & Auth

Aset utama yang tampil pertama kali saat pengguna membuka aplikasi, melewati pengenalan (*Onboarding*), masuk/daftar akun (*Login/Register*), dan halaman *Tentang EduEarth*.

| Nama File | Direktori | Lokasi Pemakaian | Ukuran / Rasio | Format | Keterangan |
|---|---|---|---|---|---|
| `logo_eduearth.png` | `assets/images/branding/` | Splash Screen, Onboarding, Login, Register, About Page | `512 × 512 px` (1:1) | PNG transparan | Logo bola bumi dengan daun hijau (`forestGreen` & `freshGreen`) |
| `eco_wave.png` | `assets/images/mascot/` | Hero Banner Login & Register, Onboarding | `512 × 512 px` (1:1) | PNG transparan | Maskot Eco melambai ramah dengan helai daun |
| `splash_landscape.png` | `assets/images/branding/` | Latar bawah Splash Screen & Slide 1 Onboarding | `900 × 304 px` (~3:1) | PNG | Ilustrasi lanskap bukit hijau, kincir angin, dan maskot Eco |

---

## Prioritas B — State UI Utama (Empty, Error & Hasil Kuis)

Aset maskot untuk umpan balik kondisi layar (*Empty State*, *Error State*) serta apresiasi kelulusan kuis.

| Nama File | Direktori | Lokasi Pemakaian | Ukuran / Rasio | Format | Keterangan |
|---|---|---|---|---|---|
| `eco_sleepy.png` | `assets/images/mascot/` | `EmptyView` (daftar tersimpan kosong, hasil pencarian kosong, dll.) | `384 × 384 px` (1:1) | PNG transparan | Ekspresi Eco tertidur (`zZ`) |
| `eco_sad.png` | `assets/images/mascot/` | `ErrorView` (kendala jaringan / gagal memuat data) | `384 × 384 px` (1:1) | PNG transparan | Ekspresi Eco sedih / berkaca-kaca |
| `eco_congrats.png` | `assets/images/mascot/` | `QuizResultPage` (skor kelulusan tinggi) & Slide 3 Onboarding | `384 × 384 px` (1:1) | PNG transparan | Ekspresi Eco memegang piala & mahkota |

---

## Prioritas C — Ekspresi Tambahan & Ilustrasi Pendukung

Aset pelengkap untuk memperkaya header pembelajaran, variasi skor hasil kuis, profil, dan hero banner beranda.

| Nama File | Direktori | Lokasi Pemakaian | Ukuran / Rasio | Format | Keterangan |
|---|---|---|---|---|---|
| `eco_reading.png` | `assets/images/mascot/` | Header "Pusat Edukasi" (`LearningDashboardPage`) & Slide 2 Onboarding | `384 × 384 px` (1:1) | PNG transparan | Ekspresi Eco memakai toga & membaca buku |
| `eco_excited.png` | `assets/images/mascot/` | `QuizResultPage` (skor menengah-baik) | `384 × 384 px` (1:1) | PNG transparan | Ekspresi Eco bersemangat dengan mata bintang |
| `eco_thinking.png` | `assets/images/mascot/` | `QuizResultPage` (skor perlu latihan ulang) & petunjuk pembahasan | `384 × 384 px` (1:1) | PNG transparan | Ekspresi Eco berpikir (`?`) |
| `eco_happy.png` | `assets/images/mascot/` | Avatar default profil & ulasan positif | `384 × 384 px` (1:1) | PNG transparan | Ekspresi Eco tersenyum ceria |
| `banner_explore_energy.png` | `assets/images/illustrations/` | Hero Banner Home Dashboard ("Explore Renewable Energy") & aksen Auth | `345 × 288 px` | PNG transparan | Ilustrasi panel surya, kincir angin, dan bukit hijau dengan *alpha fade* di sisi kiri |

---

## Aset yang Dibatalkan (`cat_*`)

> **Keputusan Desain (Polish UI Putaran 2):**  
> Slot ilustrasi kategori `cat_solar.png`, `cat_hydro.png`, `cat_wind.png`, `cat_geothermal.png`, dan `cat_bioenergy.png` **dibatalkan**.  
> Seluruh tampilan kategori energi pada barisan kategori Home, chip filter, kartu pembangkit (`PlantCard`), kartu materi (`MaterialCard`), serta peta interaktif menggunakan **ikon vektor Material berwarna** (`iconForCategorySlug` + `AppColors.colorForCategorySlug` & `softBackgroundForCategorySlug`) agar selalu tajam (HD) di semua resolusi layar dan menjaga performa *scroll* tetap ringan tanpa beban *decode* tekstur di dalam daftar.

---

## Konfigurasi `pubspec.yaml`

Pastikan bagian `flutter -> assets` di `pubspec.yaml` memuat ketiga folder berikut:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/branding/
    - assets/images/mascot/
    - assets/images/illustrations/
```
