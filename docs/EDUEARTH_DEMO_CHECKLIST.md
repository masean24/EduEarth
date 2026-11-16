# Panduan Demonstrasi Konsultasi Dosen — EduEarth (Alur 5 Menit)

Dokumen ini adalah panduan praktis untuk mendemonstrasikan **EduEarth** secara runtut dalam waktu **±5 menit** saat konsultasi atau sidang akademik, sekaligus daftar antisipasi pertanyaan kritis dari dosen penguji/pembimbing.

---

## 1. Pesan Kunci Pembuka (30 Detik)

> *"EduEarth adalah aplikasi pembelajaran pendamping berbasis peta untuk pelajar (SMP–SMA/SMK) dan masyarakat umum. Fokus utamanya menghubungkan **4 pilar belajar secara utuh**: **Explore** (melihat sebaran & studi kasus nyata pembangkit), **Learn** (9 modul bertingkat Pemula–Lanjut), **Understand Impact** (membandingkan manfaat dekarbonisasi & trade-off lingkungan), dan **Evaluate** (6 kuis aman server-side dengan pembahasan ilmiah serta pelacakan perkembangan skor)."*

---

## 2. Skenario Demo Langsung 5 Menit (Urutan Layar)

### Menit 1 — Beranda & Peta Interaktif (Pilar 1: *Explore*)
1. **Buka Beranda (`HomeDashboardPage`):**
   - Tunjukkan kartu **Alur Belajar EduEarth (4 Pilar)** dan ringkasan **Kategori Energi** yang menampilkan rincian jujur: **Total 128 pembangkit tercatat (`Beroperasi 85 • Konstruksi 9 • Rencana 34`)**.
2. **Buka Tab Peta (`ExploreMapPage`):**
   - Filter kategori **Surya (PLTS)** atau **Panas Bumi (PLTP)**.
   - Tunjukkan bagaimana siswa dapat memfilter berdasarkan **Status Operasional** (`Beroperasi`, `Konstruksi`, `Rencana`).
   - Ketuk marker **PLTS Terapung Cirata (192 MW, Jawa Barat)** lalu buka **Lihat Detail Lengkap**.

### Menit 2 — Konteks Geografis, Kapasitas, & *Trade-off* di Detail Pembangkit (`PlantDetailPage`)
1. **Tunjukkan Kartu *Memahami Kapasitas & Status Pembangkit*:**
   - Jelaskan bahwa angka **192,00 MW** dijelaskan sebagai kapasitas maksimum nominal menurut sumber referensi (bukan daya konstan 24 jam).
2. **Tunjukkan Kartu *Konteks Geografis & Karakteristik Operasional*:**
   - Tunjukkan mengapa jenis pembangkit ini *umumnya* cocok di wilayah tersebut, lengkap dengan **catatan variasi desain** (misalnya PLTS terapung vs darat, dengan/tanpa baterai BESS).
3. **Tunjukkan Kartu *Manfaat & Tantangan Lingkungan (Trade-off)*:**
   - Tunjukkan bahwa EduEarth tidak mengklaim energi terbarukan bebas dampak, melainkan menyajikan manfaat dekarbonisasi bersanding dengan tantangan lingkungan beserta rujukan `IPCC AR6 WGIII (2022)`, `IRENA`, dan `Kementerian ESDM — Ditjen EBTKE`.
4. **Tunjukkan Transparansi Presisi Koordinat:**
   - Tunjukkan bahwa jika pembangkit memiliki koordinat pendekatan kabupaten/provinsi, aplikasi menampilkan badge **`Lokasi perkiraan`** secara jujur.

### Menit 3 — Perbandingan Karakteristik & Dampak Lingkungan (Pilar 3: *Understand Impact*)
1. Dari halaman detail pembangkit, ketuk tombol **`Bandingkan Karakteristik & Dampak Energi Ini`**.
2. **Di `EnergyComparisonPage`:**
   - Tunjukkan kartu **Metodologi & Sumber Referensi** di bagian atas.
   - Bandingkan **Surya (PLTS)** vs **Panas Bumi (PLTP)** pada dimensi:
     - *Karakteristik Pasokan (Umum)* (intermiten siang hari vs *baseload* 24 jam),
     - *Variasi Desain Pembangkit*,
     - *Manfaat Lingkungan & Dekarbonisasi*,
     - *Tantangan Lingkungan (Trade-off)*, dan *Emisi Siklus Hidup (LCA)*.

### Menit 4 — Materi Kontekstual & Studi Kasus Nyata (Pilar 2: *Learn*)
1. Ketuk tombol **`Baca Modul Transisi Energi & Trade-off Lingkungan`** (Modul 9) atau buka modul **Energi Surya (PLTS)**.
2. **Di `LearningDetailPage`:**
   - Scroll untuk menunjukkan indikator progres baca (*Reading Progress Bar*), tabel perbandingan Markdown, dan *Flashcard: Uji Kilat Pemahamanmu!*.
   - Di bagian bawah artikel, tunjukkan kartu **`Contoh Pembangkit Tercatat di Indonesia (Explore)`** yang menampilkan hingga 3 pembangkit nyata terprioritas (`operating` + koordinat `exact`) yang bisa langsung diketuk kembali ke peta/detail.

### Menit 5 — Evaluasi Kuis & Pembahasan Ilmiah (Pilar 4: *Evaluate*)
1. Di bagian paling bawah halaman materi, tunjukkan kartu **`Uji Pemahaman Materi Ini (Evaluate)`** yang otomatis merekomendasikan paket kuis topik terkait (`SmartQuizResolver`).
2. Masuk ke halaman kuis, jawab 5 soal dengan cepat, lalu kirim jawaban (dinilai di sisi server via RPC `submit_quiz_attempt` tanpa membocorkan kunci jawaban ke client).
3. **Di `QuizResultPage`:** Tunjukkan skor, ulasan pembahasan ilmiah per butir soal, dan pencapaian (*badge*) belajar di halaman Profil.

---

## 3. Antisipasi Pertanyaan Kritis Dosen & Jawaban Akademik

| No | Pertanyaan Kritis Dosen | Jawaban Akademik & Bukti di Aplikasi |
|---|---|---|
| **1** | *"Apa masalah utama yang diselesaikan EduEarth dan siapa target penggunanya?"* | Pelajar SMP–SMA maupun masyarakat umum sering mempelajari energi terbarukan secara abstrak di buku teks tanpa mengetahui di mana pembangkit nyata berada di Indonesia, perbedaan beban dasar vs intermiten, dan *trade-off* lingkungannya. EduEarth menjembatani kesenjangan tersebut melalui alur *Explore → Learn → Understand Impact → Evaluate* (bisa dijajal cepat lewat Mode Tamu, lalu masuk akun untuk menyimpan progres & skor). |
| **2** | *"Apa bedanya EduEarth dengan Google Maps atau membaca artikel di internet?"* | Google Maps hanya menunjukkan lokasi umum tanpa kurasi kategori EBT, status operasional, catatan studi kasus, maupun evaluasi belajar. Sebaliknya, portal artikel tidak menghubungkan teori dengan titik geospasial nyata dan perbandingan dampak siklus hidup (*LCA*). EduEarth mengintegrasikan keempatnya dalam satu alur belajar. |
| **3** | *"Dari mana sumber data 128 pembangkit ini? Apakah semua koordinatnya akurat di atas gedung turbin?"* | Seluruh 128 titik dikurasi dari **Global Energy Monitor (`gem.wiki`, CC BY 4.0)**, **Buku Saku Bioenergi 2023 Ditjen EBTKE Kementerian ESDM**, serta siaran pers ESDM/PLN/operator yang tercantum pada `source_url` tiap baris (`data/DATA_LOG.md`). Kami membedakan ketat **85 Beroperasi**, **9 Konstruksi**, dan **34 Rencana**, serta menandai **64 titik berkoordinat pendekatan** (termasuk 22 titik bioenergi hasil sentroid OSM Nominatim) dengan badge **`Lokasi perkiraan`** agar tidak salah ditafsirkan. |
| **4** | *"Mengapa kalian tidak menampilkan kalkulator penghematan ton $\text{CO}_2$ per pembangkit?"* | Menghitung reduksi emisi $\text{CO}_2$ aktual per pembangkit membutuhkan data produksi listrik tahunan (MWh/tahun), *capacity factor* aktual tiap unit, dan faktor emisi *grid* regional tempat pembangkit terhubung. Karena data publik hanya memuat kapasitas terpasang (MW), membuat angka ton $\text{CO}_2$ otomatis justru berisiko tidak akurat secara ilmiah. Oleh karena itu, kami menyajikan perbandingan berbasis literatur **IPCC AR6 WGIII (2022)** dan **IRENA**. |
| **5** | *"Bagaimana kalian mengukur bahwa aplikasi ini benar-benar meningkatkan pemahaman siswa?"* | Kami telah menyusun protokol evaluasi Pre-Test dan Post-Test 6 soal yang setara secara kompetensi (Literasi Geospasial, Sistem Energi, dan *Trade-off* Lingkungan) dengan metrik *Normalized Gain (N-Gain)* serta uji *Task Completion Rate* pada dokumen `docs/EDUEARTH_LEARNING_EVALUATION.md`. |

