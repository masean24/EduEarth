# 05 — Roadmap Implementasi

> Agent: kerjakan **satu fase sekali**, urut. Centang item yang selesai dan terverifikasi.
> Jangan mulai fase berikutnya sebelum "Kriteria selesai" fase saat ini terpenuhi dan pemilik menyetujui.

**Status saat ini:** Fase 0 (belum dimulai)

---

## Fase 0 — Fondasi
- [ ] Buat proyek Flutter (`com.<nama>.eduearth` atau sesuai pemilik), Android + iOS
- [ ] `pubspec.yaml` dengan dependency di `docs/02_ARCHITECTURE.md`
- [ ] Struktur folder sesuai arsitektur
- [ ] `app_colors.dart`, `app_text_styles.dart`, `app_theme.dart`
- [ ] `GlassContainer` (dengan fallback tanpa blur) + halaman demo komponen
- [ ] `LoadingView`, `ErrorView`, `EmptyView`
- [ ] `route_names.dart` + `app_router.dart` (GoRouter, placeholder halaman)
- [ ] `app_config.dart` (dart-define), `.env.example`, `.gitignore` aman
- [ ] Inisialisasi Supabase di `supabase_service.dart`
- [ ] Setup Git + commit awal

**Kriteria selesai:** app berjalan di Android/iOS, tema dan glass tampil benar, navigasi placeholder berfungsi, `flutter analyze` bersih.

## Fase 1 — Database dan Autentikasi
- [ ] Migrasi: ekstensi, `energy_categories`, `user_profiles` + trigger, RLS dasar
- [ ] Seed 5 kategori energi (data pasti, bukan data pembangkit)
- [ ] Splash screen
- [ ] Onboarding (simpan status selesai di `shared_preferences`)
- [ ] Register, Login, Logout, sesi persisten
- [ ] Redirect auth di GoRouter
- [ ] Pesan error auth yang ramah (Bahasa Indonesia)

**Kriteria selesai:** user bisa daftar, login, keluar; profil terbuat otomatis; RLS terverifikasi.

## Fase 2 — Peta dan Pembangkit
- [ ] Migrasi: `power_plants` (+ PostGIS, index, RLS), RPC `nearby_plants`
- [ ] Data pembangkit: **hanya** data bersumber terverifikasi atau baris `is_demo = true` yang jelas ditandai
- [ ] Bottom navigation shell (5 tab)
- [ ] Home Dashboard (kategori, ringkasan, akses cepat)
- [ ] Explore Map (`flutter_map` + OSM, marker per kategori, atribusi)
- [ ] Map Filter (glass filter chips per kategori)
- [ ] Plant Preview (glass bottom sheet)
- [ ] Plant Detail (data + sumber + tombol "Buka di Google Maps")
- [ ] Nearby Plants (izin lokasi, jarak, empty state saat izin ditolak/tidak ada hasil)

**Kriteria selesai:** peta menampilkan pembangkit dari Supabase, filter bekerja, preview → detail → buka Google Maps berfungsi.

## Fase 3 — Pembelajaran dan Bookmark
- [ ] Migrasi: `learning_materials`, `bookmarks` + RLS
- [ ] Learning Dashboard
- [ ] Energy Category (daftar materi per kategori)
- [ ] Learning Detail (render Markdown)
- [ ] Bookmark materi dan pembangkit (toggle, daftar bookmark)

**Kriteria selesai:** user bisa membaca materi dan menyimpan bookmark yang tersimpan per akun.

## Fase 4 — Kuis
- [ ] Migrasi: `quizzes`, `quiz_questions`, `quiz_answer_keys`, `quiz_attempts` + RLS
- [ ] RPC `submit_quiz_attempt` (penilaian server-side)
- [ ] Quiz Dashboard
- [ ] Quiz Gameplay (timer opsional, progres)
- [ ] Quiz Result (skor, jawaban benar, penjelasan)
- [ ] Verifikasi: client **tidak bisa** membaca `quiz_answer_keys` dan tidak bisa insert `quiz_attempts` langsung

## Fase 5 — Profil dan Kelengkapan
- [ ] Profile (edit nama, avatar opsional)
- [ ] My Learning (riwayat kuis, bookmark, progres)
- [ ] Settings (termasuk opsi "Kurangi efek glass")
- [ ] About EduEarth
- [ ] Global Search (materi + pembangkit)

## Fase 6 — Fitur Lanjutan dan Rilis
- [ ] Achievement (`achievements`, `user_achievements`, RPC award)
- [ ] Notification Center (butuh persetujuan tabel `notifications`)
- [ ] Energy Comparison (dari `energy_categories.comparison`)
- [ ] Optimasi performa (profiling, gambar, blur)
- [ ] Uji di perangkat Android menengah dan iOS
- [ ] Ikon app, splash native, versi, build rilis

---

## Catatan kemajuan
(Agent: tambahkan ringkasan singkat per sesi di sini — tanggal, apa yang selesai, apa yang tertunda.)
