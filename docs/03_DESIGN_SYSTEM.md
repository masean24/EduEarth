# 03 — Design System

**Konsep:** Nature Tech + iOS Liquid Glass / Glassmorphism.
**Karakter:** modern, clean, premium, minimalis, responsif, konsisten di Android dan iOS.
**Prioritas:** keterbacaan dan performa di atas efek visual.

## Palet warna (sumber kebenaran — semua di `app_colors.dart`)

| Token | Hex | Pemakaian |
|---|---|---|
| `forestGreen` | `#14532D` | Teks utama gelap, header, elemen brand kuat |
| `freshGreen` | `#22C55E` | Aksi utama (primary button), indikator aktif |
| `sageGreen` | `#A7C4AD` | Border halus, elemen sekunder, ikon nonaktif |
| `mintGreen` | `#DCFCE7` | Latar kartu/chip terpilih, highlight lembut |
| `offWhite` | `#F8FAF7` | Latar utama layar |
| `skyBlue` | `#38A6C8` | Aksen informasi, kategori air/hydro, link |
| `warmYellow` | `#FACC15` | Aksen penghargaan/bintang, kategori solar, peringatan ringan |

Aturan:
- Jangan memakai hex langsung di widget; selalu lewat `AppColors` / `Theme`.
- Pastikan kontras teks memenuhi keterbacaan (teks gelap `forestGreen` di atas `offWhite`/`mintGreen`).
- Warna kategori energi (untuk marker dan chip) didefinisikan satu kali di `app_colors.dart` dan dipetakan dari `slug` kategori.

## Tipografi
- Satu keluarga font bersih (mis. via `google_fonts`: Plus Jakarta Sans atau Inter). Pilih satu dan konsisten.
- Skala: Display, Title, Subtitle, Body, Caption — didefinisikan di `app_text_styles.dart`.
- Jangan membuat `TextStyle` ad-hoc yang berulang; pakai skala yang ada.

## Spacing, radius, elevation
- Skala spacing berkelipatan 4: 4, 8, 12, 16, 20, 24, 32.
- Radius: kartu 20, chip 999 (pill), bottom sheet 28 di sudut atas, tombol 16.
- Bayangan lembut dan tipis; hindari bayangan tebal.

## Glass effect — dipakai SELEKTIF

**Boleh** memakai glass pada:
- Search bar
- Filter chips (di atas peta)
- Bottom navigation
- Modal / dialog
- Bottom sheet (Plant Preview, filter)

**Jangan** memakai glass pada:
- Setiap kartu di dalam list yang discroll
- Latar layar penuh
- Teks panjang tanpa latar solid yang cukup

Implementasi `GlassContainer` (`core/widgets/glass/glass_container.dart`):
- `ClipRRect` + `BackdropFilter(ImageFilter.blur(sigmaX, sigmaY))` dengan sigma sedang (sekitar 12–20).
- Isi semi-transparan: putih ±55–70% opacity + border putih tipis ±30–40% opacity.
- Parameter: `borderRadius`, `blur`, `tintOpacity`, `padding`.
- **Wajib ada fallback** tanpa blur (warna semi-solid) lewat flag, agar bisa dipakai di perangkat lemah atau saat setting "Kurangi efek" aktif.
- Bungkus dengan `RepaintBoundary` bila berada di atas konten yang bergerak (mis. di atas peta).

## Komponen inti (dibuat sekali, dipakai ulang)
- `GlassContainer`, `GlassBottomNav`, `GlassSearchBar`, `GlassFilterChip`, `GlassBottomSheet`
- `PrimaryButton`, `SecondaryButton`
- `CategoryChip`, `EnergyCategoryCard`, `PlantCard`, `MaterialCard`
- `LoadingView`, `ErrorView` (dengan tombol coba lagi), `EmptyView` (ikon + pesan + aksi opsional)
- `SectionHeader`, `AppNetworkImage` (cache + placeholder + error fallback)

## Gaya UI
- Banyak ruang kosong, hierarki jelas, satu aksi utama per layar.
- Ilustrasi/ikon sederhana dan konsisten (satu set ikon).
- Animasi halus dan singkat (150–300 ms); jangan berlebihan.
- Responsif: gunakan `LayoutBuilder`/`MediaQuery` dan hindari ukuran piksel kaku; uji di layar kecil (±360 dp) dan besar.
- Dukungan area aman (`SafeArea`) di iOS dan Android.
- Aksesibilitas: ukuran sentuh minimal 48 dp, label semantik pada ikon penting.
