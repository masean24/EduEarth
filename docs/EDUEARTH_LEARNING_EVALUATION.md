# Rancangan Evaluasi Keberhasilan Pembelajaran — EduEarth

Dokumen ini menyajikan protokol evaluasi pembelajaran (Pre-Test, Post-Test, dan Uji Penggunaan / *Usability Testing*) serta pemetaan kurikulum SMA/SMK untuk mengukur sejauh mana aplikasi **EduEarth** mencapai 4 *Expected Learning Outcomes* yang ditetapkan pada Blueprint V2.

---

## 1. Tujuan & Indikator Hasil Pembelajaran (*Expected Learning Outcomes*)

Setelah menggunakan EduEarth secara terintegrasi melalui 4 pilar (**Explore → Learn → Understand Impact → Evaluate**), siswa SMA/SMK kelas X–XII diharapkan mampu:

| Kode | Kompetensi (*Learning Outcome*) | Indikator Keberhasilan Terukur |
|---|---|---|
| **LO-1** | **Literasi Geospasial Energi** | Mampu mengidentifikasi contoh sebaran pembangkit 5 kategori EBT di Indonesia, membedakan status (`Beroperasi`, `Konstruksi`, `Rencana`), memahami arti label `Lokasi perkiraan`, dan menjelaskan alasan geografis umum suatu wilayah mendukung jenis energi tertentu. |
| **LO-2** | **Pemahaman Sistem Energi** | Mampu menjelaskan prinsip konversi energi primer menjadi listrik serta membedakan karakteristik pasokan umum (pembangkit beban dasar / *baseload*, pembangkit fleksibel / *peaker*, dan pembangkit variabel cuaca / *VRE*) beserta variasi desainnya. |
| **LO-3** | **Pemahaman Dampak & *Trade-off* Lingkungan** | Mampu membandingkan manfaat penurunan emisi siklus hidup (*Life-Cycle Assessment / LCA*) dengan tantangan lingkungan spesifik tiap jenis EBT (kebutuhan lahan, perubahan hidrologi sungai, konservasi hutan lindung, keberlanjutan rantai pasok biomassa). |
| **LO-4** | **Evaluasi Mandiri** | Mampu menguji pemahaman konsep melalui kuis topik dan meninjau pembahasan ilmiah setiap butir soal. |

---

## 2. Pemetaan Kurikulum SMA/SMK

| Mata Pelajaran | Jenjang / Fase | Keterkaitan Topik pada EduEarth | Status Validasi |
|---|---|---|---|
| **Geografi SMA** | Kelas XI (Fase F) | Persebaran sumber daya alam strategis, potensi energi terbarukan berdasarkan kondisi fisiografis kepulauan Indonesia, dan pemanfaatan peta tematik. | Selaras secara tematik; *perlu konfirmasi guru mata pelajaran untuk penyesuaian silabus sekolah*. |
| **Fisika SMA** | Kelas X (Fase E) & Kelas XII (Fase F) | Bentuk-bentuk energi, hukum kekekalan dan transformasi energi (radiasi foton $\rightarrow$ listrik DC/AC, energi potensial air $\rightarrow$ mekanik turbin, entalpi panas bumi), serta sumber energi alternatif. | Selaras secara tematik; *perlu konfirmasi guru mata pelajaran untuk penyesuaian kedalaman rumus*. |
| **Biologi / IPAS SMA** | Kelas X (Fase E) | Siklus karbon, fermentasi anaerobik limbah organik menjadi biogas metana ($\text{CH}_4$), pelestarian ekosistem, dan perubahan iklim. | Selaras secara tematik; *perlu konfirmasi guru mata pelajaran*. |
| **SMK Teknik Energi Terbarukan / Ketenagalistrikan** | Kelas X–XII | Dasar-dasar pembangkit listrik tenaga surya, hidro, angin, panas bumi, dan bioenergi, serta pengenalan karakteristik jaringan (*grid*) dan penyimpanan energi (BESS / *Pumped Storage*). | Selaras sebagai media pengenalan awal; *perlu konfirmasi guru kejuruan*. |

---

## 3. Desain Pre-Test & Post-Test (Setara Kompetensi)

Untuk menghindari bias hafalan soal yang sama (*testing effect*), evaluasi menggunakan **dua paket soal berbeda namun setara secara tingkat kesulitan dan kompetensi (LO-1 s.d. LO-3)**, masing-masing terdiri dari **6 butir pilihan ganda**.

### 3.1. Paket Pre-Test (Dikerjakan Sebelum Menggunakan Aplikasi — 10 Menit)

1. **[LO-1 | Geospasial & Geologi]** Mengapa potensi Pembangkit Listrik Tenaga Panas Bumi (PLTP) di Indonesia umumnya banyak ditemukan di sepanjang Pulau Sumatra, Jawa, Bali, Nusa Tenggara, hingga Sulawesi Utara?
   - A. Wilayah tersebut memiliki curah hujan tahunan paling rendah di Indonesia
   - B. Wilayah tersebut berada di jalur vulkanik *Ring of Fire* dengan gradien panas hidrotermal bawah permukaan *(Kunci)*
   - C. Wilayah tersebut merupakan dataran rendah aluvial tanpa pegunungan
   - D. Wilayah tersebut hanya mengandalkan hembusan angin muson pantai
2. **[LO-1 | Literasi Data Peta]** Ketika mengamati titik pembangkit pada peta edukasi, mengapa penting memperhatikan status (`Beroperasi`, `Konstruksi`, `Rencana`) dan keterangan presisi koordinat (`Lokasi perkiraan`)?
   - A. Karena semua titik pada peta pasti sudah menghasilkan listrik penuh dan berada tepat di atas gedung turbin
   - B. Agar pengguna dapat membedakan pembangkit yang sudah menyuplai listrik aktif dari proyek yang masih dibangun/direncanakan, serta memahami bila titik hanya mewakili koordinat administratif kabupaten/provinsi *(Kunci)*
   - C. Karena status operasional hanya menentukan warna ikon tanpa arti teknis
   - D. Agar pengguna dapat mengubah koordinat pembangkit secara bebas
3. **[LO-2 | Prinsip Kerja & Karakteristik Pasokan]** Apa perbedaan umum antara karakteristik pasokan listrik PLTP (Panas Bumi) dan PLTS (Surya) tanpa baterai?
   - A. PLTP umumnya hanya beroperasi siang hari, sedangkan PLTS beroperasi 24 jam penuh
   - B. PLTP umumnya menyuplai daya stabil sepanjang hari (*baseload*), sedangkan keluaran PLTS tanpa baterai bersifat variabel mengikuti penyinaran matahari (*intermittent*) *(Kunci)*
   - C. Keduanya hanya dapat beroperasi saat musim hujan
   - D. Keduanya menghasilkan arus searah (DC) tanpa memerlukan peralatan konversi
4. **[LO-2 | Variasi Desain Pembangkit]** Mengapa kita tidak boleh menyamakan cara kerja semua Pembangkit Listrik Tenaga Air (PLTA)?
   - A. Karena sebagian PLTA menggunakan sistem waduk (*reservoir*) yang alirannya dapat diatur, sementara PLTMH/*run-of-river* memanfaatkan aliran sungai langsung tanpa tampungan besar *(Kunci)*
   - B. Karena PLTA tidak memerlukan turbin air
   - C. Karena semua PLTA di Indonesia menggunakan panel fotovoltaik
   - D. Karena PLTA hanya bisa dibangun di wilayah pesisir laut
5. **[LO-3 | Manfaat Siklus Hidup / LCA]** Apa manfaat lingkungan utama pembangkit energi terbarukan dibandingkan pembangkit bahan bakar fosil menurut kajian siklus hidup (*Life-Cycle Assessment*)?
   - A. Sama sekali tidak memerlukan mineral atau lahan saat pembangunan konstruksi
   - B. Memiliki emisi gas rumah kaca siklus hidup per kWh yang jauh lebih rendah karena tidak membakar batu bara, minyak, atau gas secara terus-menerus saat beroperasi *(Kunci)*
   - C. Menghilangkan seluruh kebutuhan pemeliharaan peralatan listrik
   - D. Dapat dibangun di lokasi mana pun tanpa studi dampak lingkungan
6. **[LO-3 | Tantangan & *Trade-off* Lingkungan]** Tantangan lingkungan apa yang umumnya perlu dikelola secara hati-hati pada pembangunan PLTA berwaduk besar?
   - A. Emisi asap pembakaran batu bara dari cerobong ketel
   - B. Kebutuhan genangan lahan waduk serta perubahan pola aliran dan migrasi biota sungai *(Kunci)*
   - C. Ketergantungan pada hembusan angin pesisir setiap sore
   - D. Limbah tandan kosong kelapa sawit di ruang kontrol

### 3.2. Paket Post-Test (Dikerjakan Setelah Sesi Belajar Terpandu 25 Menit)

1. **[LO-1 | Geospasial & Iklim]** Mengapa wilayah pesisir selatan Sulawesi (seperti Sidrap dan Jeneponto) umumnya dipilih untuk pengembangan Pembangkit Listrik Tenaga Bayu (PLTB)?
   - A. Karena wilayah tersebut memiliki cadangan uap magma vulkanik aktif
   - B. Karena topografi perbukitan dan koridor pesisirnya mendukung hembusan angin muson yang relatif konsisten untuk memutar rotor turbin *(Kunci)*
   - C. Karena wilayah tersebut merupakan lembah sungai terpanjang di Kalimantan
   - D. Karena PLTB hanya bekerja di daerah yang tidak pernah terkena sinar matahari
2. **[LO-1 | Literasi Data Kapasitas]** Jika sebuah pembangkit memiliki keterangan *"Kapasitas terpasang (menurut sumber): 192 MW • Beroperasi"*, bagaimana cara menafsirkan angka tersebut secara tepat?
   - A. Pembangkit tersebut pasti menghasilkan tepat 192 MW setiap detik sepanjang tahun tanpa pernah berubah
   - B. Angka 192 MW adalah kapasitas maksimum nominal menurut sumber referensi; daya listrik aktual yang dihasilkan pada waktu tertentu tetap bergantung pada ketersediaan sumber energi primer dan kondisi operasi *(Kunci)*
   - C. Pembangkit tersebut masih berupa rencana di atas kertas dan belum dibangun
   - D. Angka 192 MW menunjukkan jumlah tiang transmisi di sekitar lokasi
3. **[LO-2 | Prinsip Kerja & Fleksibilitas Jaringan]** Mengapa kombinasi pembangkit variabel seperti PLTS/PLTB dengan penyimpan energi (BESS atau *Pumped Storage*) maupun PLTA waduk penting bagi kestabilan jaringan listrik?
   - A. Karena PLTS dan PLTB menghasilkan uap panas bertekanan tinggi di malam hari
   - B. Karena sistem penyimpanan dan PLTA waduk dapat membantu menyeimbangkan pasokan listrik ketika penyinaran matahari meredup atau kecepatan angin berubah *(Kunci)*
   - C. Karena BESS berfungsi membakar biomassa padat menjadi uap
   - D. Karena jaringan listrik tidak membutuhkan kestabilan frekuensi
4. **[LO-2 | Variasi Desain Bioenergi]** Apa perbedaan utama antara Pembangkit Listrik Tenaga Biomassa (PLTBm) dan Pembangkit Listrik Tenaga Biogas (PLTBg)?
   - A. PLTBm mengonversi biomassa padat melalui pembakaran boiler/gasifikasi, sedangkan PLTBg memfermentasi limbah organik cair secara anaerobik menjadi gas metana ($\text{CH}_4$) *(Kunci)*
   - B. PLTBm menggunakan panel silikon, sedangkan PLTBg menggunakan kincir angin
   - C. Keduanya menggunakan uap panas bumi dari sumur produksi
   - D. PLTBm hanya beroperasi di laut lepas
5. **[LO-3 | Manfaat Lingkungan Spesifik]** Selain menghasilkan listrik, apa manfaat lingkungan tambahan dari pengolahan limbah cair pabrik kelapa sawit (*POME*) menjadi biogas pada PLTBg?
   - A. Mengubah air sungai menjadi air laut
   - B. Menangkap gas metana ($\text{CH}_4$) dari limbah organik agar tidak terlepas bebas ke atmosfer sebagai gas rumah kaca berpotensi pemanasan tinggi *(Kunci)*
   - C. Menghilangkan kebutuhan turbin dan generator
   - D. Menghasilkan batu bara sintetis
6. **[LO-3 | Tantangan & *Trade-off* Lingkungan]** Mengapa pemanfaatan PLTS skala besar di daratan kerap dikembangkan juga dalam bentuk PLTS Terapung di atas permukaan waduk (seperti di Waduk Cirata)?
   - A. Karena panel surya hanya bisa bekerja jika direndam di dalam air
   - B. Untuk mengurangi tekanan alih fungsi lahan daratan produktif dan memanfaatkan infrastruktur jaringan listrik PLTA yang sudah ada, dengan tetap memperhatikan pengelolaan kualitas air waduk *(Kunci)*
   - C. Karena permukaan waduk selalu gelap sepanjang tahun
   - D. Untuk menggantikan fungsi bendungan air secara keseluruhan

---

## 4. Protokol Sesi Uji Penggunaan (*Usability & Learning Evaluation Session*)

Sesi pengujian dirancang untuk **5–10 siswa SMA/SMK kelas X–XII** dengan durasi total **40 menit per peserta/kelompok kecil**:

1. **Tahap 1 — Pengantar & Pre-Test (8 menit)**
   - Peserta mengisi lembar Pre-Test (6 soal) tanpa membuka aplikasi.
2. **Tahap 2 — Eksplorasi Terpandu 4 Pilar (20 menit)**
   - **Tugas A (Explore, 5 menit):** Buka tab **Peta**, filter kategori *Surya* dan *Panas Bumi*, amati perbedaan status pembangkit, lalu buka detail **PLTS Terapung Cirata** dan satu pembangkit berlabel `Lokasi perkiraan`. Baca kartu *Memahami Kapasitas & Status* serta *Konteks Geografis*.
   - **Tugas B (Understand Impact, 5 menit):** Dari halaman detail pembangkit, ketuk tombol **Bandingkan Karakteristik & Dampak Energi Ini** untuk membuka halaman *Perbandingan & Dampak Energi*. Bandingkan manfaat dan tantangan lingkungan antara *Surya (PLTS)* dan *Panas Bumi (PLTP)*.
   - **Tugas C (Learn, 6 menit):** Buka modul **Transisi Energi Indonesia: Manfaat dan Tantangan Lingkungan Energi Terbarukan** atau modul kategori terkait, baca ringkasan, lalu amati bagian **Contoh Pembangkit Tercatat di Indonesia**.
   - **Tugas D (Evaluate, 4 menit):** Ketuk tombol rekomendasi kuis di bagian bawah materi, kerjakan kuis 5 soal, dan baca pembahasan setiap soal pada halaman hasil.
3. **Tahap 3 — Post-Test & Kuesioner Singkat (12 menit)**
   - Peserta mengerjakan Paket Post-Test (6 soal).
   - Peserta mengisi kuesioner persepsi pengguna (skala Likert 1–5).

---

## 5. Metrik Evaluasi & Kriteria Keberhasilan

1. **Peningkatan Skor Pemahaman (*Normalized Gain / N-Gain*):**
   $$g = \frac{\text{Skor Post-Test} - \text{Skor Pre-Test}}{\text{Skor Maksimum} - \text{Skor Pre-Test}}$$
   - Interpretasi: $g \ge 0{,}70$ (Tinggi), $0{,}30 \le g < 0{,}70$ (Sedang), $g < 0{,}30$ (Rendah). Target keberhasilan produk pendamping belajar adalah rata-rata **$g \ge 0{,}45$ (kategori Sedang–Tinggi)**.
2. **Tingkat Penyelesaian Tugas (*Task Completion Rate*):**
   - Persentase peserta yang berhasil menyelesaikan keempat tugas (Explore $\rightarrow$ Impact $\rightarrow$ Learn $\rightarrow$ Evaluate) tanpa bantuan teknis langsung. Target: **$\ge 85\%$**.
3. **Kuesioner Persepsi Siswa (5 Pertanyaan Skala 1–5):**
   - Q1: Bahasa penjelasan pada halaman detail pembangkit dan materi mudah saya pahami sebagai siswa SMA/SMK.
   - Q2: Peta dan penjelasan geografis membantu saya mengerti mengapa jenis pembangkit tertentu cocok di wilayah tertentu di Indonesia.
   - Q3: Halaman perbandingan membuat saya paham bahwa energi terbarukan memiliki manfaat besar sekaligus tantangan lingkungan (*trade-off*).
   - Q4: Alur berpindah dari Peta $\rightarrow$ Materi $\rightarrow$ Perbandingan $\rightarrow$ Kuis terasa jelas dan saling terhubung.
   - Q5: Pembahasan jawaban setelah kuis membantu saya mengoreksi konsep yang tadinya belum saya pahami.

