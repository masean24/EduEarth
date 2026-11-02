# 05 — Roadmap Implementasi

> Agent: kerjakan **satu fase sekali**, urut. Centang item yang selesai dan terverifikasi.
> Jangan mulai fase berikutnya sebelum "Kriteria selesai" fase saat ini terpenuhi dan pemilik menyetujui.

**Status saat ini:** Fase 5 selesai & terverifikasi — Putaran Polish UI #1 (Moodboard)

---

## Fase 0 — Fondasi
- [x] Buat proyek Flutter (`com.<nama>.eduearth` atau sesuai pemilik), Android + iOS
- [x] `pubspec.yaml` dengan dependency di `docs/02_ARCHITECTURE.md`
- [x] Struktur folder sesuai arsitektur
- [x] `app_colors.dart`, `app_text_styles.dart`, `app_theme.dart`
- [x] `GlassContainer` (dengan fallback tanpa blur) + halaman demo komponen
- [x] `LoadingView`, `ErrorView`, `EmptyView`
- [x] `route_names.dart` + `app_router.dart` (GoRouter, placeholder halaman)
- [x] `app_config.dart` (dart-define), `.env.example`, `.gitignore` aman
- [x] Inisialisasi Supabase di `supabase_service.dart`
- [x] Setup Git + commit awal

**Kriteria selesai:** app berjalan di Android/iOS, tema dan glass tampil benar, navigasi placeholder berfungsi, `flutter analyze` bersih.

## Fase 1 — Database dan Autentikasi
- [x] Migrasi: ekstensi, `energy_categories`, `user_profiles` + trigger, RLS dasar
- [x] Seed 5 kategori energi (data pasti, bukan data pembangkit)
- [x] Splash screen
- [x] Onboarding (simpan status selesai di `shared_preferences`)
- [x] Register, Login, Logout, sesi persisten
- [x] Redirect auth di GoRouter
- [x] Pesan error auth yang ramah (Bahasa Indonesia)

**Kriteria selesai:** user bisa daftar, login, keluar; profil terbuat otomatis; RLS terverifikasi.

## Fase 2 — Peta dan Pembangkit
- [x] Migrasi: `power_plants` (+ PostGIS, index, RLS), RPC `nearby_plants`
- [x] Data pembangkit: **hanya** data bersumber terverifikasi atau baris `is_demo = true` yang jelas ditandai
- [x] Bottom navigation shell (5 tab)
- [x] Home Dashboard (kategori, ringkasan, akses cepat)
- [x] Explore Map (`flutter_map` + OSM, marker per kategori, atribusi)
- [x] Map Filter (glass filter chips per kategori)
- [x] Plant Preview (glass bottom sheet)
- [x] Plant Detail (data + sumber + tombol "Buka di Google Maps")
- [x] Nearby Plants (izin lokasi, jarak, empty state saat izin ditolak/tidak ada hasil)

**Kriteria selesai:** peta menampilkan pembangkit dari Supabase, filter bekerja, preview → detail → buka Google Maps berfungsi.

## Fase 3 — Pembelajaran dan Bookmark
- [x] Migrasi: `learning_materials`, `bookmarks` + RLS
- [x] Learning Dashboard
- [x] Energy Category (daftar materi per kategori)
- [x] Learning Detail (render Markdown)
- [x] Bookmark materi dan pembangkit (toggle, daftar bookmark)

**Kriteria selesai:** user bisa membaca materi dan menyimpan bookmark yang tersimpan per akun.

## Fase 4 — Kuis
- [x] Migrasi: `quizzes`, `quiz_questions`, `quiz_answer_keys`, `quiz_attempts` + RLS
- [x] RPC `submit_quiz_attempt` (penilaian server-side)
- [x] Quiz Dashboard
- [x] Quiz Gameplay (timer opsional, progres)
- [x] Quiz Result (skor, jawaban benar, penjelasan)
- [x] Verifikasi: client **tidak bisa** membaca `quiz_answer_keys` dan tidak bisa insert `quiz_attempts` langsung

## Fase 5 — Profil dan Kelengkapan
- [x] Profile (edit nama, avatar opsional)
- [x] My Learning (riwayat kuis, bookmark, progres)
- [x] Settings (termasuk opsi "Kurangi efek glass")
- [x] About EduEarth
- [x] Global Search (materi + pembangkit)

## Fase 6 — Fitur Lanjutan dan Rilis
- [ ] Achievement (`achievements`, `user_achievements`, RPC award)
- [ ] Notification Center (butuh persetujuan tabel `notifications`)
- [ ] Energy Comparison (dari `energy_categories.comparison`)
- [ ] Optimasi performa (profiling, gambar, blur)
- [ ] Uji di perangkat Android menengah dan iOS
- [ ] Ikon app, splash native, versi, build rilis

---

## Catatan kemajuan
- **2026-11-02 (Fase 0):** Fondasi proyek (`com.eduearth.app`), struktur arsitektur feature-based, design system *Nature Tech + Liquid Glass*, `GlassContainer` dengan fallback tanpa blur, tiga state UI (`LoadingView`, `ErrorView`, `EmptyView`), halaman demo komponen, dan GoRouter 5 tab selesai dan terverifikasi.
- **2026-11-02 (Fase 1):** Migrasi SQL (`energy_categories`, `user_profiles`, trigger `set_updated_at` & `handle_new_user`, RLS, seed 5 kategori energi), alur Splash → Onboarding (`SharedPreferences`) → Login/Register/Logout Supabase Auth, dan redirect dinamis GoRouter selesai dan terverifikasi.
- **2026-11-02 (Fase 2):** Migrasi PostGIS `power_plants` + RPC `nearby_plants` + seed demo, Home Dashboard, Explore Map (OSM + glass filter chips + marker per kategori), Plant Preview bottom sheet, Plant Detail (dengan tombol Google Maps), dan Nearby Plants selesai dan terverifikasi.
- **2026-11-02 (Fase 3):** Migrasi `learning_materials` & `bookmarks` (`num_nonnulls`, partial unique index, RLS), seed 5 materi draf konsep dasar, Learning Dashboard, Energy Category, Learning Detail (`flutter_markdown_plus`), dan fitur Bookmark selesai dan terverifikasi.
- **2026-11-02 (Fase 4):** Migrasi tabel kuis (`quizzes`, `quiz_questions`, `quiz_answer_keys` tertutup dari client, `quiz_attempts` read-only bagi client), RPC `submit_quiz_attempt` (`security definer`), seed kuis draf & kunci jawaban terpisah, serta UI Quiz Dashboard, Gameplay, dan Result selesai dan terverifikasi.
- **2026-11-03 (Fase 5):** UX riwayat kuis di Quiz Dashboard, halaman Profile (`user_profiles`), My Learning, Settings (toggle persisten "Kurangi efek glass"), About EduEarth, dan Global Search (sanitasi PostgREST + escape wildcard + debounce 350 ms) selesai dan terverifikasi.
