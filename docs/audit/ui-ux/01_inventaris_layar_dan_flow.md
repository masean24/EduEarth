# Inventaris Layar, Route, & Verifikasi Visual — EduEarth

> **Lingkup Langkah 1–2:** Inventarisasi dari `lib/routes/app_router.dart` & `lib/routes/route_names.dart`, disertai verifikasi visual pada `flutter build web` (viewport mobile `390×844` DPR `2` di Chrome headless) ke `docs/audit/ui-ux/screens/`. **Catatan:** Tidak ada emulator Android / perangkat fisik tersambung; status autentikasi penuh (login) & `kDebugMode` diaudit dari kode.

## 1. Daftar Layar, Route GoRouter, & Cakupan Screenshot

| No | Layar / Widget | Route (`RouteNames`) | Akses | Screenshot (`docs/audit/ui-ux/screens/`) |
|---|---|---|---|---|
| 1 | `SplashPage` | `/splash` | Publik / awal | `01_splash.png` |
| 2 | `OnboardingPage` | `/onboarding` | Pra-onboarding | `02_onboarding_1.png`, `_2`, `_3` |
| 3 | `LoginPage` | `/login` | Belum login | `03_login.png`, `03_login_validation.png` |
| 4 | `RegisterPage` | `/register` | Belum login | `04_register.png` |
| 5 | `HomeDashboardPage` (Tab Tengah) | `/home` (Branch 0) | Auth / Tamu | `05_home_top.png`, `_scrolled`, `23_state_loading_home.png`, `24_state_offline_stuck_loading_home.png` |
| 6 | `ExploreMapPage` (Tab 1) | `/explore` (Branch 1) | Auth / Tamu | `06_explore_map.png`, `_filtered`, `_empty` |
| 7 | `LearningDashboardPage` (Tab 2) | `/learning` (Branch 2) | Auth / Tamu | `09_learning_dashboard.png`, `_filtered` |
| 8 | `QuizDashboardPage` (Tab 4) | `/quiz` (Branch 3) | Auth / Tamu | `13_quiz_dashboard.png`, `_scrolled` |
| 9 | `ProfilePage` (Tab 5) | `/profile` (Branch 4) | Auth / Tamu | `14_profile_guest.png` *(mode auth: dari kode)* |
| 10 | `PlantDetailPage` | `/plants/:id` | Auth / Tamu | `07_plant_detail_top/mid/bottom.png`, `_cirata_top/impact/bottom.png` |
| 11 | `NearbyPlantsPage` | `/nearby-plants` | Auth / Tamu | `08_nearby_plants.png` *(izin GPS ditolak browser)* |
| 12 | `EnergyCategoryPage` | `/learning/category/:slug` | Auth / Tamu | `10_energy_category.png` |
| 13 | `LearningDetailPage` | `/learning/material/:slug` | Auth / Tamu | `11_learning_detail_top/mid/flashcard/bottom.png` |
| 14 | `EnergyComparisonPage` | `/energy-comparison` (`?category=`) | Auth / Tamu | `12_energy_comparison_top.png`, `_scrolled` |
| 15 | `BookmarksPage` | `/bookmarks` | Tamu: lock; Auth: list | `16_bookmarks_guest.png` *(mode auth: dari kode)* |
| 16 | `QuizGameplayPage` | `/quiz/:id/play` | Wajib Auth | *Diaudit dari kode (butuh sesi login)* |
| 17 | `QuizResultPage` | `/quiz/:id/result` | Wajib Auth | *Diaudit dari kode (butuh sesi login)* |
| 18 | `MyLearningPage` | `/my-learning` | Tamu: lock; Auth: data | `15_my_learning_guest.png` *(mode auth: dari kode)* |
| 19 | `SettingsPage` | `/settings` | Auth *(Tamu via URL)* | `20_settings.png` |
| 20 | `AboutPage` | `/about` | Auth / Tamu | `19_about_top.png`, `_scrolled` |
| 21 | `GlobalSearchPage` | `/search` | Auth / Tamu | `18_search_initial.png`, `_results`, `_empty` |
| 22 | `AchievementsPage` | `/achievements` | Auth / Tamu *(via URL)* | `21_achievements_guest.png` |
| 23 | `NotificationsPage` | `/notifications` | Auth / Tamu | `17_notifications.png` |
| 24 | `DesignSystemShowcasePage` | `/design-showcase` | `kDebugMode` saja | *Diaudit dari kode (build rilis tidak aktif)* |
| 25 | `GoRouter.errorBuilder` | *(rute tidak dikenal)* | Semua | `22_not_found_errorbuilder.png` |

## 2. Komponen Modal, Overlay, & Dialog Non-Route

| Komponen | Lokasi Kode | Pemicu | Verifikasi |
|---|---|---|---|
| `_MapPlantPreviewCard` | `explore_map_page.dart:620` | Otomatis di peta saat ada marker / ketuk marker | Terlihat di `06_explore_map*.png` |
| `_EditProfileBottomSheet` | `profile_page.dart:38,867` | Tombol *Ubah Profil* (hanya mode Auth) | Diaudit dari kode |
| `showAchievementUnlockDialog` | `achievement_unlock_dialog.dart:45` | Buka badge baru / ketuk badge terbuka (mode Auth) | Diaudit dari kode |
| Dialog Keluar Kuis (`AlertDialog`) | `quiz_gameplay_page.dart:78` | Tombol kembali saat mengerjakan kuis (mode Auth) | Diaudit dari kode |

## 3. Penelusuran Alur Pengguna (User Flow) & Jarak Tap Core Loop

### 3.1 Alur Masuk (First-Time Experience, Mode Tamu, & Auth)
- **Pengguna baru (Onboarding → Tamu):** `SplashPage` (`splash_page.dart:53-56`) tidak membaca `isGuestModeProvider` (in-memory di `auth_provider.dart:11-22`), langsung mengarah ke `/onboarding` atau `/login`. Dari `OnboardingPage` (3 slide), pengguna harus menyelesaikan/melewati onboarding menuju `/login` sebelum menemukan tombol `Jelajahi sebagai Tamu` (`login_page.dart:341-354`). *(FAKTA)*
- **Pengguna tamu kembali (`SplashPage`):** Karena `isGuestMode` hanya di memori dan `SplashPage` tidak menyinkronkannya, sesi tamu hilang saat cold start dan harus masuk ulang lewat `/login`. *(FAKTA)*
- **Kontras UI Login vs Register:** `LoginPage` memakai `SecondaryButton` penuh + teks penjelas Mode Tamu + 3 highlight fitur; `RegisterPage:318-336` memakai `TextButton.icon` kecil tanpa penjelasan. *(FAKTA)*

### 3.2 Jarak Tap ke Kuis Pertama & Alur Core Loop
| Skenario Pengguna | Alur Layar | Jumlah Tap | Catatan Hambatan |
|---|---|---|---|
| **Auth — Jalur Cepat** | Home (`/home`) → Tab `Quiz` → `Mulai Kuis` | **2 tap** | Langsung ke `QuizGameplayPage`. *(FAKTA)* |
| **Auth — Core Loop Penuh (4 Pilar)** | Home → Tab `Explore` (1) → `Lihat Detail` di preview card (2) → `Bandingkan Karakteristik & Dampak` di `PlantDetail` (3) → `Baca Modul Transisi` di `EnergyComparison` (4) → `Mulai Kuis Topik Ini` di `LearningDetail` (5) | **5 tap** (+ banyak scroll) | Tombol *Pelajari/Bandingkan* di `PlantDetail` berada di bagian bawah scroll panjang (`~3.500+dp`), tertutupi footer sticky Google Maps (`~145dp`). *(FAKTA)* |
| **Pengguna Baru (Tamu) — Awal s.d. Kuis** | Onboarding 1 (`Lanjut` 1, 2, `Mulai Sekarang` 3) → `Jelajahi sebagai Tamu` (4) → Tab `Quiz` (5) → `Mulai Kuis` (6) | **6 tap → TERBLOKIR** | Diredirect ke `/login` + SnackBar (`quiz_dashboard_page.dart:30-41`); Mode Tamu tidak punya pre-test/latihan lokal. *(FAKTA)* |

### 3.3 Navigasi Bottom Nav, Tombol Back, & Dead-End
- **Struktur Bottom Nav (`glass_bottom_nav.dart:45-77`):** 5 tab berurutan `Explore` (`branch 1`) · `Learn` (`branch 2`) · `Home` (`branch 0`, ikon melayang di tengah) · `Quiz` (`branch 3`) · `Profile` (`branch 4`). Urutan branch `0` berada di tengah secara visual (selaras `moodboard.png`), tetapi label seluruhnya **bahasa Inggris** meski judul header tiap layar berbahasa **Indonesia** (`Peta Pembangkit`, `Pusat Edukasi`, `Kuis Energi Terbarukan`, `Profil Saya`). *(FAKTA)*
- **Ketidaksinkronan `Home` hit-area (`glass_bottom_nav.dart:115,243`):** Ikon lingkaran tengah dan teks `"Home"` di bawahnya memakai dua `GestureDetector` terpisah; tanpa label semantik pada tombol teksnya. *(FAKTA)*
- **Dead-end & akses tersembunyi di Mode Tamu:**
  1. `ProfilePage` Mode Tamu (`profile_page.dart:81-104`) hanya menampilkan `Masuk / Daftar Akun` & `Tentang EduEarth & Sumber Data` — **tidak ada akses ke `SettingsPage`** (`/settings`), sehingga tamu di HP Android spek rendah tidak bisa mengaktifkan opsi *"Kurangi efek glass"*. *(FAKTA)*
  2. `BookmarksPage` (`16_bookmarks_guest.png`) & `MyLearningPage` (`15_my_learning_guest.png`) menampilkan layar kunci penuh ke `/login`; tombol back konsisten kembali ke tab asal. *(FAKTA)*
  3. **Duplikasi navigasi Pembangkit Terdekat:** Ikon `near_me_rounded` ke `/nearby-plants` muncul di 3 titik sekaligus (header Home, header ExploreMap `143`, dan tombol melayang ExploreMap `326`), sedangkan peta justru tidak memiliki tombol *pusatkan ke lokasi saya*. *(FAKTA)*
  4. **Tombol Back & Deep Link:** Rute turunan memakai `push` (kembali wajar ke tab shell); `LoginPage` ↔ `RegisterPage` memakai `context.go`; rute tidak dikenal tertangkap `GoRouter.errorBuilder` (`22_not_found_errorbuilder.png`, tombol `Kembali ke Beranda`). *(FAKTA)*
  5. **Fitur pendukung vs Core Loop:** `HomeDashboardPage` menumpuk 7 elemen (header 3 ikon aksi + banner tamu + search bar + hero + kartu 4 Pilar + kategori + rekomendasi) sehingga kartu rekomendasi pembangkit terdorong ke bawah lipatan layar (`05_home_top.png`). *(FAKTA)*
