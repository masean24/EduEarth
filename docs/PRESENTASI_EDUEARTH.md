# Materi & Panduan Presentasi — EduEarth

> **Tagline:** *Explore Energy, Understand Earth.*  
> **Jenis:** Aplikasi Mobile Edukasi Energi Terbarukan Indonesia (Flutter + Supabase) — Versi `1.2.0+2`  
> **Target Pengguna:** Pelajar SMP–SMA/SMK dan masyarakat umum (Platform utama: Android)

---

## 1. Ringkasan 30 Detik (Pembuka Presentasi)

**EduEarth** adalah aplikasi pembelajaran pendamping berbasis geospasial untuk mengenalkan **5 jenis energi terbarukan di Indonesia** (**Surya/PLTS**, **Air/PLTA**, **Angin/PLTB**, **Panas Bumi/PLTP**, dan **Bioenergi**). Berbeda dari aplikasi ensiklopedia statis, EduEarth menghubungkan peta lokasi pembangkit nyata di Indonesia langsung ke materi belajar, matriks perbandingan dampak lingkungan, dan kuis evaluasi yang dinilai aman di server.

---

## 2. Masalah yang Diselesaikan & Konsep Produk (4 Pilar)

| Pilar | Fokus Pembelajaran | Implementasi di EduEarth |
|---|---|---|
| **1. Explore** | Mengenal pembangkit nyata di sekitar Nusantara | Peta interaktif **128 pembangkit on-grid (>= 1 MW)**: `85 Beroperasi`, `9 Konstruksi`, `34 Rencana` (filter kategori, status, pencarian, & pembangkit terdekat via GPS). |
| **2. Learn** | Memahami cara kerja & alasan geografisnya | **9 modul materi terstruktur** (Pemula–Lanjut), skema konversi energi 3 tahap, *flashcard*, contoh pembangkit terkait, & progres baca (*high-water mark*). |
| **3. Understand Impact** | Berpikir kritis soal manfaat & *trade-off* | **Perbandingan 5 EBT** berdampingan pada 8 dimensi kualitatif (merujuk **IPCC AR6 WGIII 2022**, **IRENA**, dan **ESDM / Ditjen EBTKE**). |
| **4. Evaluate** | Mengukur peningkatan pemahaman | **6 paket kuis** (*server-side grading*), pembahasan ilmiah tiap soal, rekomendasi materi remedial, & pelacakan delta skor (**Awal → Terbaru**). |

---

## 3. Arsitektur, Tech Stack, & Fitur Pendukung

- **Frontend:** Flutter (Dart), state management **Riverpod** (`flutter_riverpod`), navigasi **GoRouter** (`StatefulShellRoute` 5 tab: **Jelajah · Belajar · Beranda · Kuis · Profil**).
- **Backend:** **Supabase** (Auth, PostgreSQL, **PostGIS** untuk RPC `nearby_plants`, Row-Level Security / RLS, dan RPC `SECURITY DEFINER`).
- **Peta & Geospasial:** `flutter_map` + ubin **OpenStreetMap (ODbL)** + `latlong2` + `geolocator` (tanpa Google Maps SDK berbayar; Google Maps hanya dibuka lewat *deep link* `url_launcher`).
- **Desain:** Konsep *Nature Tech + Liquid Glass* selektif, tipografi *Plus Jakarta Sans*, maskot **Eco**, dukungan *Kurangi efek glass* di Pengaturan, dan **Mode Tamu persisten** (bisa langsung jelajah peta, materi, perbandingan, & pengaturan tanpa login).
- **Fitur Pendukung:** Bookmark materi/pembangkit, Pencarian Global (*debounce* 350 ms), Pusat Informasi, dan 12 lencana Pencapaian (*Achievement*).

---

## 4. Keunggulan Teknis, Kejujuran Data, & Keamanan

1. **Kuis Aman (*Server-Side Grading*):**
   - Tabel kunci jawaban (`quiz_answer_keys`) terkunci total oleh RLS tanpa *policy* baca dari client.
   - Penilaian skor, jumlah benar, dan pembahasan dijalankan di server lewat RPC `submit_quiz_attempt`.
2. **Kejujuran Data Geospasial:**
   - Dari 128 pembangkit, **64 titik** berkoordinat tapak presisi (`exact`) dan **64 titik** berlabel jujur **`Lokasi perkiraan`** (`approximate` pada tingkat desa/kecamatan/kabupaten).
   - Setiap pembangkit menyertakan atribusi sumber (`source_url`, `data_as_of`, `source_notes`), serta tombol pintar Google Maps (koordinat untuk `exact`, pencarian nama+wilayah untuk `approximate`).
3. **Keamanan Kredensial:**
   - Tidak ada `service_role` key di kode atau aset; hanya `anon` key publik lewat `--dart-define` / `.env.local` (di-gitignore).
4. **Kualitas Kode & CI:**
   - `flutter analyze` bersih (`0` isu), `20` unit & widget test lulus (`learning_integration_helper_test.dart` & `widget_test.dart`), serta workflow GitHub Actions otomatis build APK rilis (`.github/workflows/build-apk.yml`).

---

## 5. Skenario Demo Langsung (±5 Menit)

> **Tips Persiapan:** Gunakan **akun yang sudah login** agar fitur Kuis, Bookmark, Progres Belajar, dan Badge dapat didemonstrasikan utuh tanpa terhenti di layar login (siapkan juga penjelasan bahwa Mode Tamu tersedia untuk eksplorasi bebas).

1. **Beranda (`/home`):** Tunjukkan sapaan, kartu **Alur Belajar 4 Pilar**, dan ringkasan **5 Kategori Energi** (`Total 128 lokasi`).
2. **Peta Eksplorasi (`Jelajah`):** Tunjukkan *framing* kepulauan Indonesia utuh, nyalakan filter kategori (mis. **Surya** + status **Beroperasi**), tunjukkan perbedaan label `Lokasi perkiraan` vs titik presisi, lalu ketuk **`PLTS Terapung Cirata`** (atau **`Lihat unggulan`**) → **`Lihat Detail`**.
3. **Detail Pembangkit:** Tunjukkan **Kapasitas terpasang (menurut sumber)**, skema cara kerja, manfaat & tantangan lingkungan, atribusi sumber, lalu ketuk tombol sticky **`Bandingkan EBT`**.
4. **Perbandingan Energi:** Bandingkan dua kategori (mis. **Surya** vs **Panas Bumi**) untuk menunjukkan perbedaan karakter pasokan (*intermiten* vs *baseload*) dan *trade-off* lingkungan.
5. **Pusat Edukasi (`Belajar`) → Detail Materi:** Buka modul terkait, tunjukkan simulator interaktif 3 tahap, *flashcard*, lalu ketuk tombol menuju **Kuis Topik Ini**.
6. **Kuis & Progres:** Jawab soal, kirim ke server (*server-side grading*), tunjukkan skor + pembahasan per soal, lalu buka **Progres Belajar Saya** / **Pencapaian** untuk memperlihatkan delta skor (**Awal → Terbaru**) dan lencana.

---

## 6. Antisipasi Pertanyaan Penguji / Dosen (Q&A)

- **Kenapa tidak pakai Google Maps SDK di dalam aplikasi?**  
  Agar bebas ketergantungan API key berbayar di dalam peta utama; kami memakai `flutter_map` + OpenStreetMap, dan hanya memanggil Google Maps resmi lewat *deep link* `url_launcher` saat pengguna ingin navigasi eksternal.
- **Bagaimana memastikan jawaban kuis tidak bisa dicontek dari client/network?**  
  Soal dikirim tanpa kunci jawaban. Kunci berada di tabel `quiz_answer_keys` dengan RLS tertutup bagi client, lalu seluruh pencocokan dan penyimpanan skor dieksekusi di PostgreSQL melalui RPC `submit_quiz_attempt` (`SECURITY DEFINER`).
- **Mengapa ada pembangkit berlabel *Lokasi perkiraan*?**  
  Karena tidak semua sumber publik mencantumkan koordinat tapak tepat. Demi integritas ilmiah, 64 titik administratif ditandai eksplisit sebagai `Lokasi perkiraan` agar pelajar tidak mengira titik tersebut pasti di lokasi gedung pembangkit.
- **Apa peran Mode Tamu dan batasannya?**  
  Mode Tamu menurunkan hambatan awal bagi pelajar yang ingin langsung mencoba peta, 9 modul materi, dan perbandingan 5 EBT. Namun fitur yang menulis progres pribadi (kuis, bookmark, badge) tetap mewajibkan login agar data tercatat akurat per akun.
- **Bagaimana aplikasi menangani kondisi internet bermasalah / spek HP rendah?**  
  `ProviderScope(retry: null)` mencegah *spinner* macet berkepanjangan saat offline dan segera memunculkan `ErrorView` dengan tombol *Coba Lagi*, sementara menu Pengaturan menyediakan opsi **Kurangi efek glass** untuk mengurangi beban *blur*.
