# 02 — Architecture

## Prinsip
Feature-based architecture. Alur data satu arah:

```
UI (pages/widgets) → Riverpod providers → Repository → Supabase (datasource)
```

- UI **tidak** memanggil Supabase langsung.
- Provider tidak berisi query mentah; query ada di repository/datasource.
- Repository mengembalikan **model** Dart, bukan `Map<String, dynamic>`.
- Dengan pola ini, data demo dan data Supabase bisa ditukar tanpa mengubah UI.

## Struktur folder

```
lib/
├── main.dart
├── app.dart                      # MaterialApp.router, tema
├── core/
│   ├── config/                   # env/dart-define, app_config.dart
│   ├── constants/                # app_constants.dart, asset paths
│   ├── theme/                    # app_colors.dart, app_text_styles.dart, app_theme.dart
│   ├── widgets/                  # widget reusable lintas fitur
│   │   ├── glass/                # glass_container.dart, glass_bottom_nav.dart, ...
│   │   └── common/               # loading_view.dart, error_view.dart, empty_view.dart, ...
│   ├── errors/                   # app_exception.dart, error_mapper.dart
│   └── utils/                    # formatters, validators, extensions
├── routes/
│   ├── app_router.dart           # GoRouter + redirect auth
│   └── route_names.dart
├── models/                       # model yang dipakai lintas fitur
│   ├── energy_category.dart
│   ├── power_plant.dart
│   ├── learning_material.dart
│   ├── quiz.dart / quiz_question.dart / quiz_attempt.dart
│   ├── user_profile.dart
│   ├── bookmark.dart
│   └── achievement.dart
├── services/
│   ├── supabase_service.dart     # inisialisasi + akses client
│   ├── location_service.dart     # geolocator
│   └── external_map_service.dart # buka Google Maps via url_launcher
└── features/
    ├── splash/
    ├── onboarding/
    ├── auth/
    ├── home/
    ├── map/                      # explore map, filter, nearby
    ├── plants/                   # preview, detail
    ├── learning/                 # dashboard, kategori, detail, comparison
    ├── quiz/
    ├── bookmark/
    ├── achievement/
    ├── notification/
    ├── search/
    ├── profile/                  # profile, my learning
    └── settings/                 # settings, about
```

Struktur di dalam tiap fitur:

```
features/<nama>/
├── data/
│   └── <nama>_repository.dart    # akses Supabase, mapping ke model
└── presentation/
    ├── providers/                # Riverpod providers/notifiers
    ├── pages/                    # satu file per layar
    └── widgets/                  # widget khusus fitur ini
```

Aturan penempatan:
- Dipakai **>1 fitur** → `core/widgets` atau `models/`.
- Dipakai **1 fitur** → tetap di dalam fitur itu.
- Jangan membuat dependensi silang antar fitur lewat `presentation`; pakai model dan repository bersama.

## State management (Riverpod)
- Gunakan `Provider`, `FutureProvider`, `StreamProvider`, `Notifier`, `AsyncNotifier`.
- State data dari server memakai `AsyncValue` dan **wajib** menangani `loading`, `error`, `data` (+ empty state bila list kosong).
- Provider infrastruktur (supabase client, repository) ada di `core` atau di fitur terkait dan di-`ref.watch` oleh provider lain.
- Penamaan: `plantsRepositoryProvider`, `plantsListProvider`, `selectedCategoryFilterProvider`.

## Routing (GoRouter)
- Semua nama dan path route di `route_names.dart` (tidak ada string path tersebar).
- `redirect` di `app_router.dart` menangani: belum onboarding → onboarding; belum login → login; sudah login → home.
- Bottom navigation memakai `StatefulShellRoute` dengan 5 tab: **Home, Explore (Map), Learn, Quiz, Profile**.
- Layar detail (plant detail, learning detail, quiz gameplay) berada di atas shell.

## Penanganan error
- Repository menangkap `PostgrestException` / `AuthException` dan melempar `AppException` dengan pesan yang ramah pengguna (Bahasa Indonesia).
- UI menampilkan `ErrorView` dengan tombol "Coba lagi" yang memanggil `ref.invalidate(...)`.

## Konfigurasi & secret
- `SUPABASE_URL` dan `SUPABASE_ANON_KEY` dibaca lewat `String.fromEnvironment` (`--dart-define`) di `core/config/app_config.dart`.
- Contoh menjalankan: `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
- Sertakan `.env.example` (tanpa nilai asli) dan pastikan file env asli ada di `.gitignore`.

## Dependency awal (`pubspec.yaml`)
Gunakan versi terbaru yang kompatibel (cek pub.dev), jangan mengarang nomor versi:
`flutter_riverpod`, `go_router`, `supabase_flutter`, `flutter_map`, `latlong2`, `url_launcher`, `geolocator`, `cached_network_image`, `google_fonts`, `flutter_markdown` (atau pengganti yang masih dirawat), `shared_preferences`.
Tambahan lain harus disebutkan alasannya.

## Konfigurasi platform yang diperlukan
- Android: izin lokasi dan internet di `AndroidManifest.xml`; blok `<queries>` untuk `url_launcher` (Android 11+).
- iOS: `NSLocationWhenInUseUsageDescription` di `Info.plist`.
- Pada peta OSM, set `userAgentPackageName` dan tampilkan atribusi "© OpenStreetMap contributors".
