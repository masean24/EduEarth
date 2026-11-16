# Audit Konsistensi Desain & Usulan Token Bersama — EduEarth

> **Catatan aturan:** Apabila dokumen desain (`docs/03_DESIGN_SYSTEM.md`) berbeda dengan kode aktual, implementasi kode dicatat sebagai kondisi berjalan dan perbedaannya dicatat sebagai inkonsistensi. Seluruh temuan di bawah adalah **FAKTA** dari inspeksi kode & screenshot, sedangkan kolom usulan adalah rekomendasi perbaikan.

## 1. Daftar Inkonsistensi Lintas Layar

### 1.1 Warna & Kontras (`118` literal `Color(0x...)` di 15 file luar `app_colors.dart`)
| Aspek | Kondisi Saat Ini di Kode & Layar | Dampak / Pelanggaran |
|---|---|---|
| **Warna aksi primer hijau** | Terpecah 3: `0xFF15803D` (`primary_button.dart:57`), `AppColors.freshGreen` `#22C55E` (`app_theme.dart:92,140`, tombol kirim `quiz_gameplay_page.dart:635`, badge `ScreenHeaderAction`), dan `#14532D` (`_MapPlantPreviewCard:787`). | Kontras tombol `#22C55E` berteks putih hanya `2.28:1` (gagal WCAG AA `4.5:1`); tampilan tombol primer tak seragam. |
| **Token peringatan & kategori Surya** | Amber/kuning di-hardcode di banyak layar (`0xFFFEF3C7`, `0xFFFEF9C3`, `0xFFFFFBEB`, `0xFFD97706`, `0xFFB45309`, `0xFFF59E0B`, `0xFFFDE047`, `0xFF92400E`). | `#FACC15` di `#FEF9C3` kontras `1.43:1`, `#D97706` di `#FEF9C3` `2.97:1`; hanya `#B45309` di `#FEF3C7` yang lolos (`4.51:1`). |
| **Teks sekunder & nav nonaktif** | `AppColors.textMuted` `#6B8A76` di putih (`3.80:1`); nav nonaktif `0xFF7B8D9E` di kaca (`3.25:1`). | Caption kecil & label tab nonaktif kurang terbaca di luar ruang. |
| **Gradien & permukaan ad-hoc** | 5+ variasi gradien hijau (`0xFF1F7A46`, `0xFF3CA662`, `0xFF1E7E48`, `0xFF237A48`, `0xFF56B870`), biru `0xFFE0F2FE`, kartu `0xFFF3F6F3`. | Sulit mengubah tema secara terpusat karena tidak lewat `app_colors.dart`. |

### 1.2 Tipografi & Skala Ukuran
- `AppTextStyles` menyediakan `display` (28), `title` (20), `subtitle` (16), `body` (14), `caption` (12), `button` (15), namun kode memakai **80+ `fontSize` inline** termasuk di bawah skala: `8.5`, `9`, `9.5`, `10`, `10.5`, `11`, `11.5`, serta ukuran non-skala `12.5`–`34`.
- Terjadi pemotongan & tabrakan pada `390dp`: badge Slide 3 (`02_onboarding_3.png`), header `Daftar Lencana` (`21_achievements_guest.png`), tombol `"Perbanding-an"` (`05_home_top.png`), label `Panas Bumi` 2 baris (`05_home_scrolled.png`) dan `Panas Bu...` (`12_energy_comparison_top.png`), serta subtitle `ScreenHeaderBar` pada `Bookmarks`, `Notifications`, `Comparison`, dan `About`.

### 1.3 Glassmorphism Selektif, Radius, & Ikonografi
- **Search bar:** `HomeDashboardPage:195` membungkus dengan `GlassContainer(enableBlur: false)` (hanya semi-transparan), `ExploreMapPage` memakai kaca aktif, sedangkan `GlobalSearchPage` memakai `borderRadius: 16` bukan kapsul pill (`AppRadius`).
- **Chip kategori:** `CategoryChip(useGlass: true)` (`category_chip.dart:157-184`) tidak memakai `GlassContainer`/`BackdropFilter`, melainkan `surfaceWhite` opacity `0.90`.
- **Empty overlay peta:** `ExploreMapPage:235-285` memakai `GlassContainer` mem-blur satu layar penuh hingga serpihan chip tetap menyembul di pinggir (`06_explore_map_empty.png`).
- **Aset & ikon:** `EmptyView` (`empty_view.dart:37`) memaksa `eco_sleepy.png` di seluruh kondisi kosong/tamu/cari/izin GPS; tab Kuis memakai `help_outline_rounded` (`quiz_dashboard_page.dart:68`); sisa kode mati `categoryAssetForSlug` (`learning_detail_page.dart:356`, `category_chip.dart:28`, `soft_image_placeholder.dart:59`).

### 1.4 Komponen UI & Target Sentuh
- **Tombol sekunder:** `OutlinedButton.icon` ditulis ulang manual di 6 layar (`home_dashboard_page.dart:383,392`, `plant_detail_page.dart:982`, `energy_category_page.dart:230`, `learning_detail_page.dart:1288`, `energy_comparison_page.dart:249`, `quiz_result_page.dart:210,216`), tidak memakai `SecondaryButton`.
- **Header:** `QuizGameplayPage:175` (tampilan tamu) & `DesignSystemShowcasePage:42` memakai `AppBar` standar, tidak memakai `ScreenHeaderBar`.
- **Tap target `< 48dp`:** `ScreenHeaderAction` (`40×40dp`), tombol preview peta (`h=29dp` & `32×32dp`), kotak strip nomor soal kuis (`34×32dp`), edit avatar profil (`28×28dp`), dan tautan teks tanpa padding (`h=32dp`).

---

## 2. Usulan Design Token & Komponen Bersama

### 2.1 Penambahan / Penyelarasan Token (`lib/core/theme/`)
| Token Baru / Diubah | Nilai Usulan | Menggantikan |
|---|---|---|
| `AppColors.actionGreen` | `#15803D` (kontras putih `5.02:1`) | `#22C55E` pada tombol kirim kuis, `AppTheme.elevatedButtonTheme`, badge notif, dan link teks |
| `AppColors.textMutedAccessible` | Gelapkan hingga kontras `>= 4.5:1` di putih | `#6B8A76` (`3.80:1`) untuk caption dan subteks |
| `AppColors.navInactiveAccessible` | Slate gelap `>= 4.5:1` di kaca nav | `0xFF7B8D9E` (`3.25:1`) di `GlassBottomNav` |
| `AppColors.warningBg` / `warningFg` | `#FEF3C7` / `#B45309` (`4.51:1`) | Literal amber tersebar & `#FACC15` di atas `#FEF9C3` (`1.43:1`) |
| `AppColors.infoBg` & `heroGradient` | `#E0F2FE` & 1 pasang warna gradien hero | Literal `0xFFE0F2FE` & 5 kode gradien hijau ad-hoc |
| `AppTextStyles.micro` | Batas bawah **11–12sp** (hapus `< 11sp`) | 80+ `fontSize` inline `8.5–10.5sp` |

### 2.2 Konsolidasi Komponen Bersama (`lib/core/widgets/`)
1. **`SecondaryButton.outlined` / `compact`:** Menyeragamkan tinggi minimum, radius tombol (`16`), dan `maxLines: 1–2` + `TextAlign.center` di 6 layar agar kata tidak terbelah.
2. **`AppSearchBarButton`:** Satu widget kapsul pill bersama untuk Home (`push` ke `/search`), Peta, dan input `GlobalSearchPage`.
3. **`EnergyCategoryFilterStrip`:** Membungkus 5 chip kategori dengan indikator fade/panah kanan agar chip ke-5 (`Bioenergi`) tidak tersembunyi tanpa petunjuk.
4. **`EmptyView` kontekstual (`mood` / `assetPath`):** Memisahkan ilustrasi `eco_sleepy.png` (benar-benar kosong) dari Eco netral/siaga (mode tamu, awal pencarian, dan izin GPS).
5. **Pembungkus `MinTapTarget` (`48×48dp`):** Dipasang di `ScreenHeaderAction`, tombol aksi kartu preview peta, strip nomor soal kuis, edit avatar, serta link teks (`MaterialTapTargetSize.padded`).
