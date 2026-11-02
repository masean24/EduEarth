# 06 — Coding Standards

## Dart / Flutter
- Null safety penuh; hindari `!` kecuali benar-benar pasti.
- Gunakan `const` constructor sebisa mungkin.
- Satu widget publik per file; nama file `snake_case.dart`, class `PascalCase`.
- Pecah widget besar menjadi widget kecil (bukan method `_buildX` yang panjang bila bisa jadi class).
- Jangan menaruh logika bisnis atau query di dalam `build()`.
- Gunakan `ref.watch` di `build`, `ref.read` di callback/event.
- Aktifkan lint (`flutter_lints` atau yang lebih ketat) dan perbaiki semua warning.
- Komentar hanya untuk "mengapa", bukan "apa".

## Model
- Class immutable (`final` field) dengan `fromJson`, `toJson`, dan `copyWith` bila perlu.
- Parsing defensif: kolom nullable ditangani, tipe numerik dari JSON (`num`) dikonversi dengan benar.
- Nama field Dart `camelCase`, kolom DB `snake_case`; mapping hanya di model.

## Error handling
- Repository: bungkus pemanggilan Supabase dengan `try/catch`, ubah ke `AppException` dengan pesan ramah.
- UI: tampilkan `ErrorView` + tombol coba lagi. Jangan menampilkan stack trace atau pesan teknis ke pengguna.
- Jangan menelan error diam-diam; minimal log di mode debug.

## Tiga state UI (wajib di setiap layar berdata)
1. **Loading** — skeleton/indikator, bukan layar kosong.
2. **Error** — pesan jelas + aksi coba lagi.
3. **Empty** — ikon + penjelasan + (bila relevan) aksi lanjut.

## Data Demo
Data demo hanya dibuat jika benar-benar diperlukan untuk mengembangkan UI. Aturannya:
- Di database: kolom `is_demo = true`. Di kode: berada di file bernama jelas, mis. `demo_data.dart`, dengan komentar `// DEMO DATA — bukan data nyata`.
- Nama pembangkit demo harus jelas fiktif/tertandai (mis. diawali "[DEMO]") agar tidak tertukar dengan data nyata.
- **Dilarang** mengarang koordinat, kapasitas, status operasional, atau operator pembangkit yang tampak seperti data nyata.
- Data nyata hanya dimasukkan dengan `source_url` dan `verified_at`. Jika agent tidak punya sumber, **tanyakan ke pemilik**, jangan menebak.
- Sebelum rilis, filter `is_demo = false` pada query produksi atau hapus data demo.

## Keamanan
- Hanya `anon` key di app. Tidak ada `service_role` di kode, aset, log, atau commit.
- Jangan commit file berisi secret. Periksa `.gitignore` sebelum commit pertama.
- Validasi input di sisi client (email, password minimal), tetapi percayakan otorisasi pada RLS.
- Jangan log token, email lengkap, atau data pribadi.

## Performa
- Gunakan `ListView.builder` untuk list panjang.
- Gambar jaringan lewat `cached_network_image` dengan placeholder dan ukuran terkontrol.
- Batasi `BackdropFilter`: tidak di dalam item list; bungkus dengan `RepaintBoundary` bila di atas peta.
- Marker peta: jika jumlah banyak, pertimbangkan clustering atau muat berdasarkan area/filter.
- Hindari rebuild besar: pecah provider, gunakan `select` bila perlu.

## Git
- Commit kecil dan sering, pesan jelas (mis. `feat(map): add category filter chips`).
- Satu commit per langkah yang sudah berjalan, agar mudah rollback.
- Jangan commit kode yang tidak lolos `flutter analyze`.

## Format jawaban agent (untuk setiap tugas)
Karena agent menulis file langsung ke repo, **JANGAN menempelkan ulang kode lengkap di chat** (tampilkan potongan kode hanya jika diminta atau untuk review keputusan desain). Target panjang jawaban maksimal ±40 baris:
1. Ringkasan singkat (3–6 baris).
2. Daftar file yang dibuat/diubah (path + satu baris fungsi).
3. Dependency / konfigurasi baru (jika ada).
4. Hasil perintah verifikasi yang sudah dijalankan (`flutter analyze`, `flutter test`, dll.).
5. Apa yang perlu dicek manual oleh pemilik.
6. Usulan tugas berikutnya.
