# AGENTS.md — EduEarth

> File ini adalah **aturan utama** untuk AI agent yang bekerja di repo ini.
> Baca file ini PENUH di awal setiap sesi, lalu baca dokumen di `docs/` yang relevan dengan tugas.
> (Jika agent kamu memakai nama file lain, salin file ini sebagai `CLAUDE.md`, `.cursorrules`, atau `.github/copilot-instructions.md`.)

## 1. Tentang proyek

**EduEarth** — aplikasi mobile edukasi energi terbarukan di Indonesia.
Tagline: *Explore Energy, Understand Earth.*
Platform: Android dan iOS. Pengembang: 1 orang (solo), dibantu AI agent.

## 2. Tech stack (FINAL — jangan diganti tanpa persetujuan pemilik)

| Bagian | Pilihan |
|---|---|
| Framework | Flutter (Dart) |
| Backend | Supabase (Auth, PostgreSQL, RLS, RPC, Storage) |
| State management | Riverpod (`flutter_riverpod`, tanpa code generation di awal) |
| Navigasi | GoRouter |
| Peta | `flutter_map` + tile OpenStreetMap + `latlong2` |
| Buka Google Maps | `url_launcher` (URL resmi Google Maps, tanpa API key) |
| Lokasi pengguna | `geolocator` |
| Model | Class Dart biasa dengan `fromJson`/`toJson` (tanpa freezed/build_runner di awal) |

Peta di dalam app memakai **OpenStreetMap, BUKAN Google Maps SDK**. Google Maps hanya dibuka dari tombol aksi lewat deep link.

## 3. Aturan yang TIDAK BOLEH dilanggar

1. **Jangan pernah** menaruh `service_role` key di kode Flutter, file aset, atau repo. Hanya `anon` key yang boleh dipakai di app, dan disuntikkan lewat `--dart-define` (atau file env yang di-gitignore). Jangan hardcode.
2. **Jangan mengarang data nyata.** Koordinat, kapasitas, status operasional, dan operator pembangkit hanya boleh berasal dari sumber yang dapat ditelusuri. Data buatan/contoh WAJIB ditandai jelas sebagai demo (lihat `docs/06_CODING_STANDARDS.md`, bagian Data Demo).
3. **Jangan membuat seluruh app dalam satu langkah.** Kerjakan per fase dan per fitur sesuai `docs/05_ROADMAP.md`.
4. **Jangan menambah tabel, kolom, dependency besar, atau mengubah arsitektur** di luar dokumen ini tanpa menjelaskan alasannya dan meminta persetujuan pemilik dulu.
5. **Jawaban kuis tidak boleh bisa dibaca client.** Penilaian kuis dilakukan di server lewat RPC (lihat `docs/04_DATABASE.md`).
6. **Semua tabel wajib RLS aktif.** Tidak ada tabel tanpa policy yang disengaja.
7. **Jangan menghapus atau menulis ulang file yang tidak terkait tugas.**
8. **Jangan melewati fase.** Selesaikan dan verifikasi fase saat ini sebelum lanjut.

## 4. Cara kerja per tugas (wajib diikuti)

Untuk setiap tugas:

1. **Konfirmasi pemahaman**: sebutkan fase/fitur yang sedang dikerjakan dan file mana yang akan dibuat atau diubah.
2. **Tulis kode lengkap langsung ke file di repo** (jangan memakai potongan `// ... sisa kode` di dalam file). **JANGAN menempelkan ulang kode lengkap di chat**; tampilkan potongan kode di chat hanya jika diminta atau ada keputusan desain yang perlu direview. Target panjang jawaban di chat maksimal ±40 baris.
3. **Pastikan terintegrasi**: import benar, provider terdaftar, route terdaftar, tidak ada referensi ke file yang belum ada.
4. **Sebutkan dependency baru** yang perlu ditambahkan ke `pubspec.yaml` dan konfigurasi platform (AndroidManifest/Info.plist) bila ada.
5. **Sertakan SQL** untuk perubahan database sebagai file migrasi di `supabase/migrations/`.
6. **Tangani tiga state UI**: loading, error (dengan tombol coba lagi), dan empty state — di setiap layar yang memuat data.
7. **Akhiri dengan checklist verifikasi**: perintah yang harus dijalankan (`flutter analyze`, `flutter run`) dan hal yang harus dicek manual.
8. Jika ada hal yang tidak jelas atau berisiko berbeda dari dokumen, **tanya dulu**, jangan menebak.

## 5. Peta dokumen

| Dokumen | Isi | Baca saat |
|---|---|---|
| `docs/01_PROJECT_OVERVIEW.md` | Tujuan, fitur, kategori energi, cakupan MVP | Awal sesi / tugas fitur baru |
| `docs/02_ARCHITECTURE.md` | Struktur folder, layering, state, routing | Membuat/ubah kode |
| `docs/03_DESIGN_SYSTEM.md` | Warna, tipografi, glass effect, komponen | Membuat UI |
| `docs/04_DATABASE.md` | Skema Supabase, RLS, RPC | Menyentuh data/backend |
| `docs/05_ROADMAP.md` | Fase, checklist, status | Menentukan tugas berikutnya |
| `docs/06_CODING_STANDARDS.md` | Konvensi kode, data demo, error handling | Setiap tugas |

## 6. Definition of Done (sebuah tugas dianggap selesai jika)

- [ ] `flutter analyze` bersih tanpa error dan warning baru.
- [ ] Aplikasi dapat dijalankan (`flutter run`) dan fitur dapat dicoba.
- [ ] Loading, error, dan empty state ada.
- [ ] Tidak ada secret di kode. Tidak ada data nyata yang dikarang.
- [ ] Mengikuti design system dan struktur folder.
- [ ] `docs/05_ROADMAP.md` diperbarui (centang item yang selesai).
