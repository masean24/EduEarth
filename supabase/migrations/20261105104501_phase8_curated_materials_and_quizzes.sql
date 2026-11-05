-- ============================================================================
-- Fase 8: Kurasi Materi Pembelajaran Lengkap (8 Modul) & Kuis Interaktif (5 Kuis, 30 Soal)
-- ============================================================================
-- PRINSIP INTEGRITAS DATA (AGENTS.md & docs/07_DATA_PROTOCOL.md):
-- 1. Seluruh materi dan soal mengacu pada prinsip fisika/rekayasa energi terbarukan
--    serta contoh pembangkit nyata dari dataset terverifikasi EduEarth (128 unit:
--    GEM, ESDM/EBTKE, PLN, Buku Saku Bioenergi).
-- 2. Tidak ada angka klaim/statistik yang dikarang.
-- 3. Kunci jawaban tetap disimpan eksklusif di tabel `public.quiz_answer_keys`
--    (RLS aktif tanpa policy baca client; penilaian dilakukan di server via RPC).

-- Pastikan kolom is_draft tersedia
alter table public.learning_materials
  add column if not exists is_draft boolean not null default false;

alter table public.quizzes
  add column if not exists is_draft boolean not null default false;

-- ============================================================================
-- BAGIAN 1: 8 MODUL MATERI PEMBELAJARAN BERKUALITAS (is_draft = false)
-- ============================================================================

insert into public.learning_materials (
  category_id,
  title,
  slug,
  summary,
  content_md,
  cover_image_url,
  read_minutes,
  difficulty,
  sort_order,
  is_published,
  is_draft
)
values
  -- 1. ENERGI SURYA (PLTS) — Dasar & Komponen
  (
    (select id from public.energy_categories where slug = 'solar'),
    'Teknologi Pembangkit Listrik Tenaga Surya (PLTS) & Efek Fotovoltaik',
    'draf-konsep-dasar-plts',
    'Memahami proses perubahan foton cahaya matahari menjadi listrik searah (DC) hingga bolak-balik (AC), arsitektur komponen PLTS, serta inovasi PLTS Terapung di Indonesia.',
    '> **Intisari Konsep:** Sel fotovoltaik mengubah energi foton cahaya matahari secara langsung menjadi listrik searah (*Direct Current* / DC) pada semikonduktor silikon tanpa bagian mekanis yang berputar.

## 1. Mengapa Energi Surya Penting bagi Nusantara?

Sebagai negara kepulauan yang dilalui garis khatulistiwa, wilayah Indonesia menerima penyinaran matahari secara konsisten sepanjang tahun. **Pembangkit Listrik Tenaga Surya (PLTS)** memanfaatkan keunggulan geografis ini untuk menghasilkan listrik bersih baik di jaringan utama maupun di pulau-pulau terpencil.

---

## 2. Alur Konversi Energi dari Foton ke Jaringan

1. **Penyerapan Foton pada Sel Silikon:** Modul surya tersusun atas lapisan semikonduktor tipe-P dan tipe-N. Ketika foton cahaya matahari menumbuk permukaan sel, elektron terlepas dari ikatan atomnya dan mengalir membentuk arus listrik searah (**DC**).
2. **Optimasi Daya (*MPPT*):** Pengendali *Maximum Power Point Tracker* menyesuaikan titik kerja tegangan dan arus agar modul surya selalu menghasilkan daya paling optimal meskipun intensitas sinar berubah.
3. **Konversi Arus di Inverter:** Karena jaringan distribusi dan peralatan listrik menggunakan arus bolak-balik (**AC**), *solar inverter* mengubah arus DC menjadi AC dengan frekuensi yang sinkron terhadap jaringan.
4. **Transformator Penaik Tegangan (*Step-Up*):** Pada PLTS skala utilitas, tegangan dinaikkan sebelum diinjeksikan ke saluran transmisi PLN.

| Komponen Utama | Fungsi Teknis |
| :--- | :--- |
| **Modul Fotovoltaik** | Menangkap radiasi surya dan menghasilkan arus listrik DC |
| **Inverter Surya** | Mengubah arus DC menjadi arus AC sinkron jaringan |
| **Sistem Penyimpanan (BESS)** | Menyimpan energi pada baterai untuk meredam fluktuasi awan/malam hari |
| **Gardu & Transformator** | Menyesuaikan level tegangan menuju jaringan distribusi |

---

## 3. Inovasi PLTS Darat & PLTS Terapung di Indonesia

Dalam basis data pembangkit terverifikasi EduEarth, pengembangan PLTS skala utilitas di Indonesia mencakup dua pendekatan utama:

- **PLTS Terapung (*Floating Solar PV*):** Dipasang di atas permukaan waduk buatan (seperti **PLTS Terapung Cirata** di Jawa Barat). Penempatan di atas air membantu mendinginkan suhu panel secara alami sekaligus menghemat penggunaan lahan daratan.
- **PLTS Darat (*Ground-Mounted*) & Hibrida Kepulauan:** Dibangun di berbagai wilayah seperti **PLTS Likupang** (Sulawesi Utara), **PLTS Kupang** (Nusa Tenggara Timur), serta deretan PLTS di Lombok dan Bali untuk memperkuat bauran energi daerah.

---

## 4. Keunggulan & Tantangan Teknis

- **Keunggulan:** Tidak menghasilkan emisi gas buang saat beroperasi, bersifat modular (mudah diperluas), dan minim keausan mekanis.
- **Tantangan Intermitensi:** Output listrik bergantung pada tutupan awan dan siklus siang-malam (*Variable Renewable Energy*), sehingga integrasi skala besar memerlukan dukungan baterai (**BESS**) atau pembangkit penyeimbang yang responsif.

---

### Referensi Belajar Lebih Lanjut
- [International Renewable Energy Agency (IRENA) — Solar Energy](https://www.irena.org/Energy-Transition/Technology/Solar-energy)
- [Direktorat Jenderal EBTKE Kementerian ESDM](https://ebtke.esdm.go.id/)',
    null,
    6,
    'beginner',
    1,
    true,
    false
  ),

  -- 2. ENERGI AIR (PLTA) — Dasar & Fleksibilitas Jaringan
  (
    (select id from public.energy_categories where slug = 'hydro'),
    'Pembangkit Listrik Tenaga Air (PLTA): Energi Gravitasi & Penyeimbang Jaringan',
    'draf-konsep-dasar-plta',
    'Mempelajari cara kerja waduk, pipa pesat (penstock), dan turbin air dalam menghasilkan listrik serta peran strategis PLTA menjaga kestabilan frekuensi jaringan listrik.',
    '> **Intisari Konsep:** PLTA memanfaatkan beda tinggi (*head*) dan debit aliran air untuk memutar turbin mekanis dan generator melalui induksi elektromagnetik.

## 1. Prinsip Fisika Konversi Energi Air

**Pembangkit Listrik Tenaga Air (PLTA)** merupakan tulang punggung energi terbarukan yang paling matang secara teknologi. Prinsip utamanya adalah mengubah **energi potensial gravitasi** air yang berada pada ketinggian tertentu menjadi **energi kinetik** aliran bertekanan, lalu diubah oleh turbin menjadi **energi mekanik putaran** dan oleh generator menjadi **energi listrik**.

---

## 2. Komponen & Tahapan Operasional PLTA

1. **Bendungan & Waduk (*Reservoir*):** Menampung air sungai untuk menciptakan beda tinggi permukaan air (*head*) sekaligus mengatur cadangan air lintas musim.
2. **Pipa Pesat (*Penstock*):** Saluran pipa baja bertekanan tinggi yang mengarahkan air dari pintu pengambilan (*intake*) menuju rumah pembangkit (*powerhouse*).
3. **Katup & Sudu Pengarah (*Guide Vane*):** Mengatur besarnya debit air yang masuk ke turbin sesuai kebutuhan beban listrik saat itu.
4. **Turbin Air (Francis, Kaplan, atau Pelton):** Pemilihan jenis turbin disesuaikan dengan karakteristik tinggi jatuh air (*head*) dan volume debit aliran.
5. **Saluran Pembuangan (*Tailrace*):** Mengembalikan air yang telah memutar turbin kembali ke aliran sungai di bagian hilir tanpa mengonsumsi air tersebut.

| Tipe PLTA | Karakteristik Operasi |
| :--- | :--- |
| **PLTA Reservoir (Waduk)** | Memiliki waduk penampung besar; daya dapat diatur mengikuti beban puncak |
| **PLTA Run-of-River** | Memanfaatkan aliran sungai langsung dengan bendung pengarah kecil |
| **Pumped Storage** | Memompa air kembali ke waduk atas saat beban listrik rendah sebagai penyimpan energi |

---

## 3. Peran PLTA di Berbagai Pulau Indonesia

Berdasarkan data pembangkit yang tercatat di EduEarth, PLTA tersebar luas di daerah bertopografi pegunungan dan sungai besar:

- **Jawa & Sumatera:** Sistem kaskade Sungai Citarum (**PLTA Saguling, Cirata, dan Jatiluhur**) di Jawa Barat, serta **PLTA Asahan**, **PLTA Maninjau**, **PLTA Singkarak**, dan **PLTA Musi** di Sumatera.
- **Kalimantan & Sulawesi:** **PLTA Riam Kanan** di Kalimantan Selatan, serta **PLTA Poso**, **PLTA Larona**, **PLTA Balambano**, dan **PLTA Bakaru** di Sulawesi.

---

## 4. Keunggulan & Aspek Keberlanjutan

- **Keunggulan Operasional:** Mampu menaikkan dan menurunkan produksi daya dengan cepat (*load following*) untuk menstabilkan frekuensi jaringan listrik saat pembangkit surya atau angin berfluktuasi.
- **Perhatian Lingkungan:** Memerlukan pelestarian hutan di Daerah Aliran Sungai (DAS) hulu untuk mencegah sedimentasi waduk serta pengelolaan ekosistem sungai yang berkelanjutan.

---

### Referensi Belajar Lebih Lanjut
- [International Renewable Energy Agency (IRENA) — Hydropower](https://www.irena.org/Energy-Transition/Technology/Hydropower)
- [PT PLN (Persero) — Statistik & Transisi Energi](https://web.pln.co.id/)',
    null,
    6,
    'beginner',
    2,
    true,
    false
  ),

  -- 3. ENERGI ANGIN (PLTB) — Aerodinamika & Kontrol Turbin
  (
    (select id from public.energy_categories where slug = 'wind'),
    'Aerodinamika Turbin Angin: Cara Kerja Pembangkit Listrik Tenaga Bayu (PLTB)',
    'draf-konsep-dasar-pltb',
    'Mengupas gaya angkat aerodinamis pada bilah rotor, sistem kendali arah angin (yaw & pitch control) di dalam nacelle, serta profil PLTB di Sulawesi Selatan.',
    '> **Intisari Konsep:** Bilah turbin PLTB tidak sekadar didorong angin, melainkan bekerja seperti sayap pesawat terbang yang menghasilkan gaya angkat (*aerodynamic lift*) untuk memutar rotor.

## 1. Dari Hembusan Angin Menjadi Putaran Rotor

**Pembangkit Listrik Tenaga Bayu (PLTB)** memanen energi kinetik dari pergerakan massa udara di atmosfer. Semakin tinggi menara turbin, aliran angin umumnya semakin stabil dan minim hambatan permukaan tanah (*wind shear*).

---

## 2. Anatomi Menara Turbin Angin Modern

1. **Bilah Rotor (*Rotor Blades*):** Dirancang dengan profil aerodinamis (*airfoil*). Ketika angin mengalir melewati bilah, perbedaan tekanan udara menciptakan gaya angkat yang memutar poros utama.
2. **Rumah Turbin (*Nacelle*):** Terletak di puncak menara dan berisi komponen transmisi mekanik, sistem pengereman, serta generator listrik.
3. **Sistem *Pitch & Yaw Control*:**
   - **Yaw Mechanism:** Memutar kepala *nacelle* mengikuti arah datangnya angin berdasarkan pembacaan sensor *anemometer* dan *wind vane*.
   - **Pitch Control:** Mengatur sudut kemiringan bilah untuk mengoptimalkan daya saat angin sedang dan membatasi putaran (*feathering*) demi keamanan saat terjadi angin kencang.
4. **Transformator & Jaringan Pengumpul:** Listrik dari tiap menara turbin dikumpulkan melalui kabel bawah tanah menuju gardu induk pembangkit.

---

## 3. Peta PLTB di Indonesia

Meskipun Indonesia berada di wilayah ekuator dengan kecepatan angin rata-rata moderat, terdapat koridor geografis dan celah topografi yang memiliki potensi angin sangat baik:

- **Koridor Sulawesi Selatan:** Menjadi pelopor PLTB skala utilitas nasional melalui **PLTB Sidrap** di Kabupaten Sidenreng Rappang dan **PLTB Tolo (Jeneponto)** yang telah beroperasi menyuplai jaringan interkoneksi Sulawesi Bagian Selatan.
- **Pengembangan Selanjutnya:** Sejumlah proyek PLTB baru juga masuk dalam tahapan perencanaan di wilayah pesisir dan perbukitan seperti Tanah Laut (Kalimantan Selatan), Sukabumi, dan Kepulauan Selayar.

---

## 4. Kelebihan & Tantangan Pengembangan

- **Kelebihan:** Bebas emisi gas rumah kaca, tidak memerlukan air pendingin sama sekali, dan lahan di sekitar kaki menara tetap dapat dimanfaatkan oleh masyarakat untuk perkebunan atau penggembalaan.
- **Tantangan:** Membutuhkan studi pengukuran angin jangka panjang (*wind resource assessment*), logistik pengangkutan bilah berukuran raksasa, serta manajemen fluktuasi daya pada jaringan.

---

### Referensi Belajar Lebih Lanjut
- [International Renewable Energy Agency (IRENA) — Wind Energy](https://www.irena.org/Energy-Transition/Technology/Wind-energy)
- [Global Energy Monitor — Global Wind Power Tracker](https://globalenergymonitor.org/)',
    null,
    5,
    'beginner',
    3,
    true,
    false
  ),

  -- 4. ENERGI PANAS BUMI (PLTP) — Sistem Hidrotermal & Siklus Uap
  (
    (select id from public.energy_categories where slug = 'geothermal'),
    'Pembangkit Listrik Tenaga Panas Bumi (PLTP): Energi Sabuk Vulkanik Nusantara',
    'draf-konsep-dasar-pltp',
    'Menjelajahi sistem hidrotermal bawah permukaan bumi, teknologi uap kering, flash steam, dan binary cycle, serta praktik injeksi ulang (reinjection) untuk kelestarian reservoar.',
    '> **Intisari Konsep:** Panas bumi adalah sumber energi terbarukan beban dasar (*baseload*) yang beroperasi 24 jam sehari sepanjang tahun tanpa dipengaruhi cuaca di permukaan.

## 1. Mengapa Indonesia Kaya akan Panas Bumi?

Indonesia terletak pada pertemuan tiga lempeng tektonik utama dunia yang membentuk jalur cincin api vulkanik (*Ring of Fire*) dari Sumatera, Jawa, Bali, Nusa Tenggara, hingga Sulawesi Utara dan Maluku. Aktivitas magmatik di bawah permukaan bumi memanaskan batuan dan air tanah yang terperangkap di dalam batuan permeabel, membentuk **reservoar hidrotermal**.

---

## 2. Tiga Teknologi Utama Konversi PLTP

| Teknologi PLTP | Karakteristik Fluida & Cara Kerja |
| :--- | :--- |
| **Dry Steam (Uap Kering)** | Reservoar menghasilkan uap dominan kering yang langsung dialirkan untuk memutar turbin uap (contoh klasik: lapangan Kamojang). |
| **Flash Steam (Uap Pemisahan)** | Fluida air panas bertekanan tinggi dipisahkan di *separator* menjadi uap penggerak turbin dan air sisa (*brine*). |
| **Binary Cycle (Siklus Biner)** | Panas fluida bumi dipindahkan melalui *heat exchanger* untuk menguapkan fluida kerja organik bertitik didih rendah dalam siklus tertutup. |

---

## 3. Pentingnya Sumur Injeksi (*Reinjection Well*)

Salah satu kunci keberlanjutan PLTP adalah **siklus tertutup fluida**:
1. **Sumur Produksi:** Mengangkat uap/air panas dari kedalaman ribuan meter ke fasilitas permukaan.
2. **Kondensor & Menara Pendingin:** Setelah memutar turbin, uap dikondensasikan kembali menjadi air.
3. **Sumur Injeksi:** Air kondensat dan *brine* dipompakan kembali ke dalam reservoar bumi untuk menjaga tekanan bawah permukaan dan mencegah penurunan muka tanah.

---

## 4. Sebaran PLTP Utama di Indonesia

Dalam basis data EduEarth, PLTP beroperasi di sepanjang jalur vulkanik utama:
- **Jawa Barat & Jawa Tengah:** **PLTP Kamojang**, **Salak**, **Wayang Windu**, **Darajat**, **Patuha**, dan **Dieng**.
- **Sumatera:** **PLTP Sarulla** (Sumatera Utara), **Ulubelu** (Lampung), **Lumut Balai** & **Rantau Dedap** (Sumatera Selatan), serta **Muara Laboh** (Sumatera Barat).
- **Sulawesi Utara & Nusa Tenggara:** **PLTP Lahendong** di Minahasa dan **PLTP Ulumbu** di Flores.

---

### Referensi Belajar Lebih Lanjut
- [International Renewable Energy Agency (IRENA) — Geothermal Energy](https://www.irena.org/Energy-Transition/Technology/Geothermal-energy)
- [Direktorat Panas Bumi — Ditjen EBTKE Kementerian ESDM](https://ebtke.esdm.go.id/)',
    null,
    7,
    'intermediate',
    4,
    true,
    false
  ),

  -- 5. BIOENERGI (PLTBm & PLTBg) — Ekonomi Sirkular Agroindustri
  (
    (select id from public.energy_categories where slug = 'bioenergy'),
    'Bioenergi Sirkular: Pembangkit Biomassa (PLTBm) dan Biogas (PLTBg)',
    'draf-konsep-dasar-bioenergi',
    'Membedah perbedaan jalur termokimia biomassa padat (PLTBm) dan jalur biokimia fermentasi anaerobik (PLTBg) dalam mengubah limbah agroindustri menjadi listrik bersih.',
    '> **Intisari Konsep:** Bioenergi mengubah residu organik pertanian dan perkebunan menjadi energi listrik terukur (*dispatchable*) sekaligus mengurangi timbulan limbah dan emisi metana lepas.

## 1. Dua Jalur Konversi Bioenergi Listrik

Di Indonesia, pemanfaatan bioenergi untuk pembangkit listrik terbagi menjadi dua teknologi utama yang saling melengkapi:

### A. PLTBm (Pembangkit Listrik Tenaga Biomassa) — Jalur Termokimia
- **Bahan Baku:** Residu padat seperti cangkang dan serat kelapa sawit, sekam padi, tongkol jagung, ampas tebu (*bagasse*), atau kayu energi dari hutan tanaman.
- **Prinsip Kerja:** Biomassa padat dibakar secara terkendali di dalam ketel uap (*boiler*) untuk memanaskan air hingga menjadi uap bertekanan tinggi yang memutar turbin uap dan generator.

### B. PLTBg (Pembangkit Listrik Tenaga Biogas) — Jalur Biokimia
- **Bahan Baku:** Limbah organik cair seperti *Palm Oil Mill Effluent* (POME / limbah cair pabrik kelapa sawit), limbah industri tapioka, atau kotoran ternak.
- **Prinsip Kerja:** Limbah cair dialirkan ke dalam reaktor tertutup tanpa oksigen (**Anaerobic Digester**). Bakteri metanogen menguraikan bahan organik dan menghasilkan **biogas** (kaya akan gas metana $\text{CH}_4$), yang kemudian dimurnikan untuk menggerakkan mesin gas (*gas engine*) pemutar generator.

---

## 2. Manfaat Ganda Ekonomi Sirkular

1. **Menangkap Gas Metana:** Jika limbah cair organik dibiarkan di kolam terbuka, gas metana akan lepas ke atmosfer sebagai gas rumah kaca yang kuat. Dengan PLTBg, gas tersebut ditangkap dan diubah menjadi listrik bermanfaat.
2. **Pasokan Listrik Pedesaan & Agroindustri:** Sebagaimana tercatat pada basis data pembangkit Bioenergi di Sumatera, Kalimantan, dan Bangka Belitung, puluhan unit PLTBm dan PLTBg menyuplai listrik langsung ke jaringan distribusi lokal (*excess power* / *on-grid*).
3. **Sifat *Dispatchable*:** Selama pasokan bahan baku organik dikelola dan disimpan dengan baik, pembangkit bioenergi dapat dioperasikan kapan saja tanpa bergantung pada cuaca.

---

### Referensi Belajar Lebih Lanjut
- [International Renewable Energy Agency (IRENA) — Bioenergy](https://www.irena.org/Energy-Transition/Technology/Bioenergy)
- [Direktorat Bioenergi — Ditjen EBTKE Kementerian ESDM](https://ebtke.esdm.go.id/)',
    null,
    6,
    'beginner',
    5,
    true,
    false
  ),

  -- 6. MODUL MENDALAM: Beban Dasar (Baseload) vs Intermiten (VRE)
  (
    (select id from public.energy_categories where slug = 'geothermal'),
    'Memahami Pembangkit Beban Dasar (Baseload), Peaker, dan Energi Intermiten (VRE)',
    'baseload-vs-intermiten-vre',
    'Bagaimana operator jaringan listrik memadukan PLTP, PLTA, PLTS, PLTB, dan Bioenergi agar lampu di rumah tetap menyala stabil 24 jam tanpa pemadaman?',
    '> **Intisari Konsep:** Jaringan listrik membutuhkan keseimbangan instan setiap detik antara daya yang dibangkitkan oleh pembangkit dan daya yang dikonsumsi oleh masyarakat.

## 1. Mengapa Satu Jenis Pembangkit Saja Tidak Cukup?

Kebutuhan listrik masyarakat berubah-ubah sepanjang hari: lebih rendah pada dini hari, meningkat pada jam kerja siang hari, dan mencapai puncak (*peak load*) pada sore hingga malam hari saat lampu dan peralatan rumah tangga dinyalakan bersamaan.

Karena setiap sumber energi terbarukan memiliki sifat alami yang berbeda, sistem ketenagalistrikan mengelompokkannya menjadi tiga peran utama:

| Peran di Jaringan | Karakteristik Operasi | Contoh Pembangkit EBT |
| :--- | :--- | :--- |
| **Pembangkit Beban Dasar (*Baseload*)** | Beroperasi stabil 24 jam terus-menerus dengan faktor kapasitas tinggi | **PLTP (Panas Bumi)**, **PLTBm/PLTBg (Bioenergi)** |
| **Pembangkit Penyeimbang & Beban Puncak (*Peaker / Load Following*)** | Mampu menaikkan/menurunkan output dengan cepat saat beban melonjak | **PLTA Reservoir (Waduk)**, **Pumped Storage** |
| **Energi Terbarukan Variabel (*VRE / Intermiten*)** | Output mengikuti kondisi cuaca alami (sinar matahari & kecepatan angin) | **PLTS (Surya)**, **PLTB (Angin)** |

---

## 2. Fenomena Kurva Bebek (*Duck Curve*) pada Siang & Malam Hari

Ketika kapasitas PLTS di suatu jaringan sangat besar:
1. **Siang Hari Terik:** PLTS memproduksi listrik melimpah sehingga kebutuhan dari pembangkit lain turun drastis.
2. **Menjelang Matahari Terbenam:** Produksi PLTS turun cepat tepat saat masyarakat pulang ke rumah dan menyalakan lampu (beban malam melonjak).
3. **Peran Penyelamat:** Pada momen transisi sore hari inilah **PLTA berwaduk** dan **sistem baterai (BESS)** melepaskan daya secara cepat untuk menjaga agar frekuensi jaringan tetap stabil.

---

## 3. Sinergi 5 Sumber Energi di Indonesia

Keunggulan besar Indonesia adalah memiliki **kelima jenis energi terbarukan sekaligus**. Kombinasi panas bumi dan bioenergi sebagai penopang beban dasar, air sebagai penyeimbang fleksibel, serta surya dan angin sebagai penyuplai bersih di siang dan musim angin menjadikan transisi energi Nusantara saling melengkapi.

---

### Referensi Belajar Lebih Lanjut
- [IRENA — Power System Flexibility for the Energy Transition](https://www.irena.org/)',
    null,
    6,
    'intermediate',
    6,
    true,
    false
  ),

  -- 7. MODUL MENDALAM: Penyimpanan Energi (BESS & Pumped Storage)
  (
    (select id from public.energy_categories where slug = 'solar'),
    'Teknologi Penyimpanan Energi: Baterai (BESS) dan Pumped Storage Hydropower',
    'teknologi-penyimpanan-energi-bess-pumped-storage',
    'Mengenal cara kerja sistem penyimpanan energi baterai berskala jaringan dan waduk bertingkat (Pumped Storage) sebagai kunci masa depan energi bersih.',
    '> **Intisari Konsep:** Penyimpanan energi (*Energy Storage*) bertindak sebagai "tabungan daya" yang menyerap kelebihan listrik saat produksi melimpah dan menyalurkannya kembali saat dibutuhkan.

## 1. Tantangan Menyimpan Energi Listrik

Arus listrik pada jaringan bolak-balik (AC) harus langsung digunakan saat itu juga kecuali diubah terlebih dahulu ke bentuk energi lain—seperti **energi kimia** di dalam baterai atau **energi potensial gravitasi** di dalam waduk air bertingkat.

---

## 2. Dua Teknologi Penyimpanan Utama

### A. Battery Energy Storage System (BESS) — Penyimpanan Elektrokimia
- **Cara Kerja:** Menggunakan deretan modul baterai isi ulang berskala besar yang terhubung dengan *bidirectional inverter*.
- **Keunggulan Utama:** Memiliki waktu respons sangat cepat (dalam hitungan milidetik) untuk meredam kedipan frekuensi jaringan (*frequency regulation*) saat awan menutupi ladang PLTS, serta mendukung mikrogrid di pulau-pulau kecil.

### B. Pumped Hydro Energy Storage (PHES) — Baterai Air Raksasa
- **Cara Kerja:** Menggunakan dua waduk pada ketinggian berbeda (waduk atas dan waduk bawah):
  1. **Mode Mengisi (*Charging*):** Saat pasokan listrik berlebih atau beban jaringan sedang rendah, pompa mengalirkan air dari waduk bawah naik ke waduk atas.
  2. **Mode Melepas (*Discharging*):** Saat jam beban puncak malam hari, air dari waduk atas dilepaskan turun kembali memutar turbin generator layaknya PLTA konvensional.
- **Contoh Pengembangan di Indonesia:** Proyek *Pumped Storage* seperti **PLTA Upper Cisokan** di Jawa Barat dirancang untuk menyimpan energi dalam kapasitas besar guna memperkuat keandalan sistem interkoneksi.

---

### Referensi Belajar Lebih Lanjut
- [International Renewable Energy Agency (IRENA) — Electricity Storage](https://www.irena.org/)',
    null,
    5,
    'intermediate',
    7,
    true,
    false
  ),

  -- 8. MODUL MENDALAM: Smart Grid & Transisi Energi Kepulauan
  (
    (select id from public.energy_categories where slug = 'wind'),
    'Jaringan Listrik Pintar (Smart Grid) & Elektrifikasi Kepulauan Nusantara',
    'smart-grid-dan-elektrifikasi-kepulauan',
    'Strategi menghubungkan ribuan pulau di Indonesia dengan pembangkit energi terbarukan lokal, mikrogrid hibrida, dan pemantauan digital pintar.',
    '> **Intisari Konsep:** *Smart Grid* memadukan jaringan kelistrikan dengan sensor digital, komunikasi dua arah, dan pengendali otomatis untuk mengintegrasikan pembangkit terbarukan yang tersebar.

## 1. Karakteristik Geografis Kelistrikan Kepulauan

Berbeda dengan negara daratan kontinental yang dapat dihubungkan oleh satu jaringan kabel tunggal, Indonesia terdiri atas sistem interkoneksi besar (seperti Jawa-Madura-Bali, Sumatera, Kalimantan, dan Sulawesi) serta ratusan sistem kelistrikan kepulauan terpisah (*isolated grids*).

---

## 2. Peran Mikrogrid & Sistem Hibrida

Di wilayah kepulauan dan perbatasan, mengandalkan pengiriman bahan bakar fosil lewat kapal laut sering kali terkendala cuaca dan biaya logistik. Solusi modern yang diterapkan adalah **Mikrogrid Energi Terbarukan Hibrida**:

1. **Pembangkit Lokal Sesuai Potensi Pulau:** Memadukan **PLTS**, mikrohidro (**PLTM/PLTMH**), angin (**PLTB**), atau **biomassa lokal**.
2. **Manajemen Energi Pintar (*Energy Management System*):** Komputer pengendali secara otomatis mengatur prioritas pasokan dari panel surya/turbin dan mengatur pengisian baterai tanpa intervensi manual yang rumit.
3. **Peningkatan Kemandirian Energi:** Mengurangi ketergantungan pulau terhadap pasokan bahan bakar luar sekaligus menekan emisi karbon lokal.

---

### Referensi Belajar Lebih Lanjut
- [Kementerian ESDM — Rencana Umum Ketenagalistrikan & Transisi Energi](https://ebtke.esdm.go.id/)',
    null,
    5,
    'advanced',
    8,
    true,
    false
  )
on conflict (slug) do update set
  category_id = excluded.category_id,
  title = excluded.title,
  summary = excluded.summary,
  content_md = excluded.content_md,
  read_minutes = excluded.read_minutes,
  difficulty = excluded.difficulty,
  sort_order = excluded.sort_order,
  is_published = excluded.is_published,
  is_draft = excluded.is_draft,
  updated_at = now();

-- ============================================================================
-- BAGIAN 2: 5 KUIS INTERAKTIF (30 SOAL TERKURASI & KUNCI JAWABAN ACAK A/B/C/D)
-- ============================================================================

insert into public.quizzes (
  id,
  category_id,
  title,
  description,
  difficulty,
  time_limit_seconds,
  is_published,
  is_draft
)
values
  (
    '11111111-1111-4111-8111-111111111101',
    null,
    'Eksplorasi Dasar 5 Energi Terbarukan',
    'Kuis pengantar seru untuk menguji pemahaman prinsip kerja PLTS, PLTA, PLTB, PLTP, dan Bioenergi di Indonesia.',
    'beginner',
    180,
    true,
    false
  ),
  (
    '11111111-1111-4111-8111-111111111102',
    (select id from public.energy_categories where slug = 'solar'),
    'Teknologi Surya (PLTS) & Angin (PLTB)',
    'Uji wawasan teknis tentang efek fotovoltaik, fungsi inverter, aerodinamika bilah turbin angin, dan solusi penyimpanan baterai.',
    'intermediate',
    240,
    true,
    false
  ),
  (
    '11111111-1111-4111-8111-111111111103',
    (select id from public.energy_categories where slug = 'geothermal'),
    'Air (PLTA) & Panas Bumi (PLTP): Penopang Jaringan',
    'Tantangan mengenai sistem hidrotermal bawah bumi, pipa pesat (penstock), injeksi ulang uap, dan kestabilan beban dasar.',
    'intermediate',
    240,
    true,
    false
  ),
  (
    '11111111-1111-4111-8111-111111111104',
    (select id from public.energy_categories where slug = 'bioenergy'),
    'Sirkularitas Bioenergi: Biomassa & Biogas',
    'Kenali bagaimana limbah organik perkebunan dan pertanian diubah menjadi listrik bersih melalui jalur termokimia dan biokimia.',
    'beginner',
    180,
    true,
    false
  ),
  (
    '11111111-1111-4111-8111-111111111105',
    null,
    'Tantangan Master: Peta Pembangkit & Transisi Energi Nusantara',
    'Kuis tingkat lanjut seputar sebaran pembangkit nyata di Indonesia, kurva beban listrik, dan strategi Smart Grid kepulauan.',
    'advanced',
    300,
    true,
    false
  )
on conflict (id) do update set
  category_id = excluded.category_id,
  title = excluded.title,
  description = excluded.description,
  difficulty = excluded.difficulty,
  time_limit_seconds = excluded.time_limit_seconds,
  is_published = excluded.is_published,
  is_draft = excluded.is_draft,
  updated_at = now();

-- Seed 30 Soal Kuis (6 soal per kuis)
insert into public.quiz_questions (
  id,
  quiz_id,
  question,
  options,
  explanation,
  sort_order
)
values
  -- ================= KUIS 1: Eksplorasi Dasar 5 Energi Terbarukan =================
  (
    '22222222-2222-4222-8222-222222222101',
    '11111111-1111-4111-8111-111111111101',
    'Fenomena fisika apa yang dimanfaatkan oleh sel surya pada PLTS untuk mengubah cahaya matahari secara langsung menjadi listrik?',
    '[
      {"id": "a", "text": "Efek fotovoltaik pada material semikonduktor"},
      {"id": "b", "text": "Pembakaran termokimia biomassa padat"},
      {"id": "c", "text": "Fermentasi anaerobik mikroorganisme"},
      {"id": "d", "text": "Tekanan hidrostatik air pada pipa pesat"}
    ]'::jsonb,
    'Sel surya (solar cell) bekerja menggunakan efek fotovoltaik, di mana foton cahaya matahari melepaskan elektron pada semikonduktor silikon sehingga menghasilkan arus listrik searah (DC).',
    1
  ),
  (
    '22222222-2222-4222-8222-222222222102',
    '11111111-1111-4111-8111-111111111101',
    'Komponen apakah pada sistem PLTS yang bertugas mengubah arus listrik searah (DC) dari panel surya menjadi arus bolak-balik (AC)?',
    '[
      {"id": "a", "text": "Penstock (pipa pesat)"},
      {"id": "b", "text": "Inverter"},
      {"id": "c", "text": "Kondensor uap"},
      {"id": "d", "text": "Anaerobic digester"}
    ]'::jsonb,
    'Panel surya menghasilkan arus searah (DC), sedangkan jaringan listrik dan peralatan rumah tangga menggunakan arus bolak-balik (AC). Inverter bertugas melakukan konversi DC ke AC tersebut.',
    2
  ),
  (
    '22222222-2222-4222-8222-222222222103',
    '11111111-1111-4111-8111-111111111101',
    'Pada Pembangkit Listrik Tenaga Air (PLTA), bagaimana urutan konversi energi utama yang terjadi dari waduk hingga ke jaringan?',
    '[
      {"id": "a", "text": "Energi radiasi cahaya -> energi kimia -> energi listrik"},
      {"id": "b", "text": "Energi panas bumi -> energi foton -> energi listrik"},
      {"id": "c", "text": "Energi potensial/kinetik air -> energi mekanik turbin -> energi listrik generator"},
      {"id": "d", "text": "Energi angin -> energi biogas -> energi listrik"}
    ]'::jsonb,
    'Air pada ketinggian waduk memiliki energi potensial yang berubah menjadi energi kinetik saat mengalir memutar sudu turbin (energi mekanik), lalu generator mengubahnya menjadi energi listrik.',
    3
  ),
  (
    '22222222-2222-4222-8222-222222222104',
    '11111111-1111-4111-8111-111111111101',
    'Mengapa Pembangkit Listrik Tenaga Panas Bumi (PLTP) dikategorikan sebagai pembangkit beban dasar (baseload) yang sangat andal?',
    '[
      {"id": "a", "text": "Karena hanya dapat menghasilkan listrik saat matahari bersinar terik"},
      {"id": "b", "text": "Karena turbinnya digerakkan oleh hembusan angin pesisir"},
      {"id": "c", "text": "Karena tidak menggunakan turbin maupun generator"},
      {"id": "d", "text": "Karena sumber panas dari reservoar bumi tersedia kontinu 24 jam tanpa bergantung cuaca harian"}
    ]'::jsonb,
    'Berbeda dengan surya dan angin yang bergantung pada kondisi cuaca di permukaan, uap panas dari reservoar bumi tersedia secara stabil sepanjang hari dan malam.',
    4
  ),
  (
    '22222222-2222-4222-8222-222222222105',
    '11111111-1111-4111-8111-111111111101',
    'Apa perbedaan utama antara jalur PLTBm (Biomassa) dan PLTBg (Biogas) dalam menghasilkan energi listrik?',
    '[
      {"id": "a", "text": "PLTBm memanfaatkan bahan organik padat (mis. cangkang sawit/sekam), sedangkan PLTBg memanfaatkan gas metana hasil fermentasi anaerobik"},
      {"id": "b", "text": "PLTBm menggunakan panel silikon, sedangkan PLTBg menggunakan kincir angin"},
      {"id": "c", "text": "PLTBm hanya bekerja di laut lepas, sedangkan PLTBg di kawah gunung berapi"},
      {"id": "d", "text": "Keduanya sama sekali tidak menggunakan bahan organik"}
    ]'::jsonb,
    'PLTBm mengolah biomassa padat secara termokimia (pembakaran boiler/gasifikasi), sedangkan PLTBg mengolah limbah organik cair di dalam reaktor kedap udara (anaerobic digester) menjadi gas metana.',
    5
  ),
  (
    '22222222-2222-4222-8222-222222222106',
    '11111111-1111-4111-8111-111111111101',
    'Gaya fisika apa yang membuat bilah turbin angin modern pada PLTB dapat berputar secara efisien saat dilewati angin?',
    '[
      {"id": "a", "text": "Gaya magnetik dari inti bumi"},
      {"id": "b", "text": "Gaya angkat aerodinamis (lift) akibat profil bilah menyerupai sayap pesawat"},
      {"id": "c", "text": "Reaksi uap air panas di dalam menara"},
      {"id": "d", "text": "Getaran akustik dari suara angin"}
    ]'::jsonb,
    'Bilah turbin PLTB dirancang dengan bentuk airfoil seperti sayap pesawat terbang sehingga aliran angin menciptakan perbedaan tekanan dan menghasilkan gaya angkat (lift) yang memutar rotor.',
    6
  ),

  -- ================= KUIS 2: Teknologi Surya (PLTS) & Angin (PLTB) =================
  (
    '22222222-2222-4222-8222-222222222201',
    '11111111-1111-4111-8111-111111111102',
    'Apa yang dimaksud dengan sifat intermiten (Variable Renewable Energy) pada pembangkit surya (PLTS) dan angin (PLTB)?',
    '[
      {"id": "a", "text": "Output daya listrik berfluktuasi mengikuti ketersediaan sinar matahari atau kecepatan angin"},
      {"id": "b", "text": "Pembangkit dapat memproduksi listrik konstan tanpa henti di segala cuaca"},
      {"id": "c", "text": "Pembangkit membutuhkan bahan bakar batu bara sebagai pemicu utama"},
      {"id": "d", "text": "Sistem tidak memerlukan inverter maupun transformator"}
    ]'::jsonb,
    'Intermiten berarti produksi daya tidak konstan sepanjang waktu karena mengikuti dinamika cuaca alami seperti tutupan awan, pergantian siang-malam, dan perubahan hembusan angin.',
    1
  ),
  (
    '22222222-2222-4222-8222-222222222202',
    '11111111-1111-4111-8111-111111111102',
    'Apa keuntungan teknis utama membangun PLTS Terapung (Floating Solar PV) di atas permukaan waduk seperti PLTS Terapung Cirata?',
    '[
      {"id": "a", "text": "Panel surya dapat berenang mengikuti arus sungai ke laut"},
      {"id": "b", "text": "Air waduk memutar panel surya secara mekanis di malam hari"},
      {"id": "c", "text": "Menghemat lahan daratan dan efek sejuk permukaan air membantu menjaga efisiensi suhu kerja modul surya"},
      {"id": "d", "text": "Menghilangkan kebutuhan penggunaan inverter"}
    ]'::jsonb,
    'Efisiensi sel fotovoltaik silikon cenderung menurun jika suhu permukaannya terlalu panas. Penempatan di atas air waduk memberikan efek pendinginan alami sekaligus memanfaatkan area waduk PLTA yang sudah ada.',
    2
  ),
  (
    '22222222-2222-4222-8222-222222222203',
    '11111111-1111-4111-8111-111111111102',
    'Pada puncak menara turbin angin (PLTB), apa fungsi dari mekanisme Pitch Control ketika terjadi badai atau angin yang terlalu kencang?',
    '[
      {"id": "a", "text": "Memompa air laut ke atas menara"},
      {"id": "b", "text": "Mengubah sudut kemiringan bilah (feathering) untuk membatasi putaran rotor agar turbin tetap aman"},
      {"id": "c", "text": "Melepaskan bilah turbin agar terbang mengikuti angin"},
      {"id": "d", "text": "Menyalakan pemanas uap di dalam nacelle"}
    ]'::jsonb,
    'Sistem Pitch Control memutar sudut bilah turbin terhadap arah angin. Saat angin melebihi batas aman (cut-out speed), sudut bilah diatur agar tidak menangkap gaya angkat berlebih sehingga struktur turbin terlindungi.',
    3
  ),
  (
    '22222222-2222-4222-8222-222222222204',
    '11111111-1111-4111-8111-111111111102',
    'Solusi teknologi apa yang dipadukan dengan PLTS agar kelebihan energi listrik di siang hari dapat disimpan dan disalurkan pada malam hari?',
    '[
      {"id": "a", "text": "Penambahan cermin cekung di bawah tanah"},
      {"id": "b", "text": "Pelepasan uap panas ke atmosfer"},
      {"id": "c", "text": "Penghentian fungsi transformator"},
      {"id": "d", "text": "Battery Energy Storage System (BESS) atau penyimpanan energi baterai"}
    ]'::jsonb,
    'BESS menyimpan energi listrik dalam bentuk energi elektrokimia pada siang hari dan menyalurkannya kembali melalui inverter dua arah saat malam hari atau saat awan tebal melintas.',
    4
  ),
  (
    '22222222-2222-4222-8222-222222222205',
    '11111111-1111-4111-8111-111111111102',
    'Bagian di puncak menara PLTB yang berfungsi sebagai rumah pelindung bagi generator, poros transmisi, dan sistem pengereman disebut...',
    '[
      {"id": "a", "text": "Nacelle"},
      {"id": "b", "text": "Penstock"},
      {"id": "c", "text": "Tailrace"},
      {"id": "d", "text": "Digester"}
    ]'::jsonb,
    'Nacelle adalah kabin atau rumah mesin di puncak menara turbin angin tempat poros rotor terhubung ke gearbox/generator listrik.',
    5
  ),
  (
    '22222222-2222-4222-8222-222222222206',
    '11111111-1111-4111-8111-111111111102',
    'Di provinsi manakah dua PLTB skala utilitas pertama yang beroperasi di Indonesia (PLTB Sidrap dan PLTB Tolo) berada?',
    '[
      {"id": "a", "text": "Kalimantan Tengah"},
      {"id": "b", "text": "Sulawesi Selatan"},
      {"id": "c", "text": "Kepulauan Bangka Belitung"},
      {"id": "d", "text": "Bengkulu"}
    ]'::jsonb,
    'PLTB Sidrap (Kabupaten Sidenreng Rappang) dan PLTB Tolo (Kabupaten Jeneponto) keduanya beroperasi di Provinsi Sulawesi Selatan dan terhubung ke jaringan kelistrikan Sulawesi Bagian Selatan.',
    6
  ),

  -- ================= KUIS 3: Air (PLTA) & Panas Bumi (PLTP) =================
  (
    '22222222-2222-4222-8222-222222222301',
    '11111111-1111-4111-8111-111111111103',
    'Apa fungsi pipa pesat (penstock) pada konstruksi Pembangkit Listrik Tenaga Air (PLTA)?',
    '[
      {"id": "a", "text": "Menyalurkan air bertekanan dari waduk/intake menuju sudu-sudu turbin di rumah pembangkit"},
      {"id": "b", "text": "Menangkap sinar matahari untuk memanaskan air waduk"},
      {"id": "c", "text": "Mengolah limbah cair sawit menjadi gas metana"},
      {"id": "d", "text": "Menyimpan baterai lithium di dasar sungai"}
    ]'::jsonb,
    'Penstock adalah pipa bertekanan tinggi yang mengarahkan aliran air dari ketinggian bendungan/intake menuju turbin air sehingga energi potensial gravitasi berubah menjadi energi kinetik.',
    1
  ),
  (
    '22222222-2222-4222-8222-222222222302',
    '11111111-1111-4111-8111-111111111103',
    'Mengapa pada operasional PLTP dilakukan proses injeksi ulang (reinjection) fluida yang telah dikondensasikan ke dalam sumur injeksi?',
    '[
      {"id": "a", "text": "Untuk mendinginkan panel fotovoltaik di permukaan"},
      {"id": "b", "text": "Untuk menjaga tekanan serta keberlanjutan cadangan fluida di dalam reservoar panas bumi"},
      {"id": "c", "text": "Untuk menciptakan angin buatan di sekitar gunung"},
      {"id": "d", "text": "Untuk menghentikan produksi uap secara permanen"}
    ]'::jsonb,
    'Mengembalikan air kondensat dan brine ke dalam perut bumi melalui sumur injeksi memastikan tekanan reservoar hidrotermal tetap terjaga dan mencegah dampak lingkungan di permukaan.',
    2
  ),
  (
    '22222222-2222-4222-8222-222222222303',
    '11111111-1111-4111-8111-111111111103',
    'Bagaimana cara kerja sistem siklus biner (Binary Cycle) pada pembangkit panas bumi bersuhu menengah?',
    '[
      {"id": "a", "text": "Menggunakan dua bendungan air sungai yang digabung"},
      {"id": "b", "text": "Membakar batu bara dan biomassa secara bersamaan"},
      {"id": "c", "text": "Fluida panas bumi memanaskan fluida kerja sekunder bertitik didih lebih rendah melalui alat penukar panas (heat exchanger) untuk memutar turbin"},
      {"id": "d", "text": "Memasang dua baling-baling angin pada satu poros"}
    ]'::jsonb,
    'Pada sistem Binary Cycle, fluida panas bumi tidak bersentuhan langsung dengan bilah turbin, melainkan memindahkan panasnya ke fluida sekunder dalam siklus tertutup.',
    3
  ),
  (
    '22222222-2222-4222-8222-222222222304',
    '11111111-1111-4111-8111-111111111103',
    'Apa perbedaan utama antara PLTA sistem Reservoir (waduk) dan PLTA sistem Run-of-River?',
    '[
      {"id": "a", "text": "Run-of-River menggunakan uap vulkanik, sedangkan Reservoir menggunakan angin"},
      {"id": "b", "text": "Reservoir hanya bekerja di siang hari, sedangkan Run-of-River hanya di malam hari"},
      {"id": "c", "text": "Keduanya tidak menggunakan turbin air"},
      {"id": "d", "text": "PLTA Reservoir menampung cadangan air dalam waduk besar sehingga debitnya mudah diatur, sedangkan Run-of-River mengandalkan aliran sungai langsung"}
    ]'::jsonb,
    'PLTA Reservoir memiliki fleksibilitas tinggi untuk mengatur kapan air dilepaskan (misalnya saat beban puncak malam hari), sementara Run-of-River mengikuti debit alami aliran sungai.',
    4
  ),
  (
    '22222222-2222-4222-8222-222222222305',
    '11111111-1111-4111-8111-111111111103',
    'Manakah dari pernyataan berikut yang merupakan tantangan utama pengembangan proyek PLTP pada tahap awal?',
    '[
      {"id": "a", "text": "Risiko ketidakpastian bawah permukaan dan biaya teknis pada tahap eksplorasi geosains serta pengeboran sumur awal"},
      {"id": "b", "text": "Ketergantungan penuh pada cahaya matahari siang hari"},
      {"id": "c", "text": "Kebutuhan pasokan cangkang sawit setiap hari"},
      {"id": "d", "text": "Tidak dapat beroperasi saat turun hujan"}
    ]'::jsonb,
    'Sebelum PLTP dibangun, pengembang harus melakukan survei geologi, geofisika, geokimia, dan pengeboran eksplorasi untuk membuktikan ketersediaan uap di kedalaman bumi.',
    5
  ),
  (
    '22222222-2222-4222-8222-222222222306',
    '11111111-1111-4111-8111-111111111103',
    'Bagaimana teknologi Pumped Storage Hydropower menyimpan energi listrik dalam skala besar?',
    '[
      {"id": "a", "text": "Menyimpan arus listrik di dalam kabel tembaga bawah laut"},
      {"id": "b", "text": "Memompa air dari waduk bawah ke waduk atas saat listrik berlebih, lalu mengalirkannya kembali memutar turbin saat beban puncak"},
      {"id": "c", "text": "Mengubah air sungai menjadi hidrogen padat tanpa listrik"},
      {"id": "d", "text": "Memanaskan air waduk dengan sinar matahari"}
    ]'::jsonb,
    'Pumped Storage bekerja sebagai baterai gravitasi raksasa: menyimpan energi dalam bentuk posisi ketinggian air di waduk atas dan melepaskannya lewat turbin saat jaringan membutuhkan daya.',
    6
  ),

  -- ================= KUIS 4: Sirkularitas Bioenergi (PLTBm & PLTBg) =================
  (
    '22222222-2222-4222-8222-222222222401',
    '11111111-1111-4111-8111-111111111104',
    'Di dalam reaktor Anaerobic Digester pada PLTBg, kondisi lingkungan seperti apa yang dibutuhkan agar bakteri dapat menghasilkan biogas?',
    '[
      {"id": "a", "text": "Terbuka lebar dan terpapar angin kencang"},
      {"id": "b", "text": "Kedap udara (tanpa oksigen bebas) agar mikroorganisme anaerobik dapat menguraikan bahan organik menjadi gas metana"},
      {"id": "c", "text": "Dibekukan hingga di bawah titik beku es"},
      {"id": "d", "text": "Disinari lampu ultraviolet berintensitas tinggi"}
    ]'::jsonb,
    'Proses pencernaan anaerobik (anaerobic digestion) berlangsung tanpa oksigen bebas sehingga bakteri metanogen dapat mengubah limbah organik cair menjadi biogas yang kaya metana (CH4).',
    1
  ),
  (
    '22222222-2222-4222-8222-222222222402',
    '11111111-1111-4111-8111-111111111104',
    'Manakah dari bahan berikut yang merupakan contoh bahan bakar biomassa padat untuk Pembangkit Listrik Tenaga Biomassa (PLTBm)?',
    '[
      {"id": "a", "text": "Cangkang kelapa sawit, sekam padi, dan residu kayu"},
      {"id": "b", "text": "Pasir kuarsa dan batuan granit"},
      {"id": "c", "text": "Uap kawah vulkanik"},
      {"id": "d", "text": "Air terjun pegunungan"}
    ]'::jsonb,
    'Residu padat agroindustri seperti cangkang sawit, serat buah sawit, sekam padi, dan ampas tebu memiliki nilai kalor yang dapat dimanfaatkan pada boiler uap PLTBm.',
    2
  ),
  (
    '22222222-2222-4222-8222-222222222403',
    '11111111-1111-4111-8111-111111111104',
    'Mengapa pengolahan limbah cair pabrik kelapa sawit (POME) menjadi listrik melalui PLTBg memberikan manfaat lingkungan ganda?',
    '[
      {"id": "a", "text": "Karena mengubah limbah cair menjadi logam mulia"},
      {"id": "b", "text": "Karena menurunkan suhu air laut secara langsung"},
      {"id": "c", "text": "Karena mencegah pelepasan gas rumah kaca metana ke udara bebas sekaligus menghasilkan energi listrik bersih"},
      {"id": "d", "text": "Karena menghilangkan kebutuhan jaringan kabel listrik"}
    ]'::jsonb,
    'Gas metana dari kolam limbah terbuka memiliki efek rumah kaca yang kuat. Menangkapnya di dalam reaktor PLTBg mengurangi emisi metana sekaligus menyuplai listrik terbarukan.',
    3
  ),
  (
    '22222222-2222-4222-8222-222222222404',
    '11111111-1111-4111-8111-111111111104',
    'Berbeda dengan PLTS dan PLTB yang bergantung pada cuaca jam-ke-jam, bagaimana karakteristik operasional pembangkit bioenergi?',
    '[
      {"id": "a", "text": "Hanya bisa menyala saat terjadi gerhana matahari"},
      {"id": "b", "text": "Tidak dapat diatur sama sekali oleh operator"},
      {"id": "c", "text": "Hanya bekerja di puncak gunung berapi"},
      {"id": "d", "text": "Bersifat dispatchable (dapat diatur jadwal operasinya) selama pasokan bahan baku biomassa atau biogas tersedia"}
    ]'::jsonb,
    'Karena bahan baku biomassa atau biogas dapat disimpan di fasilitas penampungan, pembangkit bioenergi dapat dioperasikan secara terjadwal sesuai kebutuhan beban listrik.',
    4
  ),
  (
    '22222222-2222-4222-8222-222222222405',
    '11111111-1111-4111-8111-111111111104',
    'Faktor manakah yang menjadi kunci utama keberlanjutan operasional sebuah PLTBm dalam jangka panjang?',
    '[
      {"id": "a", "text": "Kemiringan atap gedung perkantoran di kota besar"},
      {"id": "b", "text": "Keandalan rantai pasok (pengumpulan, transportasi, dan penyimpanan) bahan baku organik agar tidak terputus lintas musim"},
      {"id": "c", "text": "Kecepatan angin laut di atas 20 meter per detik"},
      {"id": "d", "text": "Kedalaman sumur magma di bawah 3 kilometer"}
    ]'::jsonb,
    'PLTBm membutuhkan pasokan bahan bakar organik secara kontinu. Manajemen logistik dan keberlanjutan sumber biomassa sangat menentukan keandalan operasi pembangkit.',
    5
  ),
  (
    '22222222-2222-4222-8222-222222222406',
    '11111111-1111-4111-8111-111111111104',
    'Gas utama apakah di dalam komposisi biogas yang memiliki nilai kalor bakar untuk menggerakkan gas engine pada PLTBg?',
    '[
      {"id": "a", "text": "Argon (Ar)"},
      {"id": "b", "text": "Helium (He)"},
      {"id": "c", "text": "Metana (CH4)"},
      {"id": "d", "text": "Neon (Ne)"}
    ]'::jsonb,
    'Biogas hasil fermentasi anaerobik sebagian besar terdiri atas gas metana (CH4) dan karbon dioksida (CO2). Kandungan metana inilah yang menjadi bahan bakar penggerak mesin generator.',
    6
  ),

  -- ================= KUIS 5: Tantangan Master Transisi Energi Nusantara =================
  (
    '22222222-2222-4222-8222-222222222501',
    '11111111-1111-4111-8111-111111111105',
    'Mengapa wilayah Sumatera, Jawa, Bali, Nusa Tenggara, hingga Sulawesi Utara memiliki banyak lokasi Pembangkit Listrik Tenaga Panas Bumi (PLTP)?',
    '[
      {"id": "a", "text": "Karena wilayah tersebut dilalui jalur sabuk vulkanik Cincin Api (Ring of Fire) akibat pertemuan lempeng tektonik"},
      {"id": "b", "text": "Karena wilayah tersebut tidak pernah mengalami musim hujan"},
      {"id": "c", "text": "Karena seluruh sungainya mengalir ke arah utara"},
      {"id": "d", "text": "Karena hanya wilayah tersebut yang memiliki sinar matahari"}
    ]'::jsonb,
    'Aktivitas tektonik dan vulkanik di sepanjang jalur Ring of Fire membentuk sistem hidrotermal bawah permukaan yang ideal bagi pengembangan PLTP.',
    1
  ),
  (
    '22222222-2222-4222-8222-222222222502',
    '11111111-1111-4111-8111-111111111105',
    'Dalam manajemen jaringan listrik modern, apa tantangan utama yang digambarkan oleh fenomena "Kurva Bebek" (Duck Curve) saat penetrasi PLTS sangat tinggi?',
    '[
      {"id": "a", "text": "Listrik padam otomatis saat siang hari karena terlalu banyak sinar matahari"},
      {"id": "b", "text": "Penurunan produksi PLTS secara cepat menjelang matahari terbenam yang bertepatan dengan lonjakan beban puncak malam hari"},
      {"id": "c", "text": "Turbin air berputar terbalik saat musim kemarau"},
      {"id": "d", "text": "Kabel transmisi berubah menjadi arus searah secara permanen"}
    ]'::jsonb,
    'Saat sore menjelang malam, produksi PLTS turun ke nol sementara konsumsi listrik rumah tangga justru naik tajam. Jaringan memerlukan pembangkit fleksibel (seperti PLTA/BESS) untuk menutup selisih tersebut dengan cepat.',
    2
  ),
  (
    '22222222-2222-4222-8222-222222222503',
    '11111111-1111-4111-8111-111111111105',
    'Di daerah aliran Sungai Citarum, Jawa Barat, terdapat tiga PLTA berwaduk besar yang beroperasi secara kaskade (berurutan dari hulu ke hilir), yaitu...',
    '[
      {"id": "a", "text": "PLTA Asahan, Maninjau, dan Singkarak"},
      {"id": "b", "text": "PLTA Poso, Larona, dan Bakaru"},
      {"id": "c", "text": "PLTA Saguling, Cirata, dan Jatiluhur (Ir. H. Djuanda)"},
      {"id": "d", "text": "PLTA Riam Kanan, Musi, dan Besai"}
    ]'::jsonb,
    'Waduk Saguling, Cirata, dan Jatiluhur berada pada aliran Sungai Citarum di Jawa Barat dan memanfaatkan aliran air secara berjenjang untuk membangkitkan listrik sekaligus keperluan pengairan.',
    3
  ),
  (
    '22222222-2222-4222-8222-222222222504',
    '11111111-1111-4111-8111-111111111105',
    'Mengapa pada beberapa data pembangkit bioenergi di tingkat desa/kecamatan dalam peta EduEarth diberikan label "Lokasi perkiraan" (approximate)?',
    '[
      {"id": "a", "text": "Karena pembangkitnya bergerak berpindah-pindah setiap hari"},
      {"id": "b", "text": "Karena transparansi metodologi data: sumber publik mencantumkan lokasi administratif desa/kecamatan sehingga koordinat mewakili titik wilayah sekitar, bukan titik tapak presisi"},
      {"id": "c", "text": "Karena pembangkit bioenergi berada di atas awan"},
      {"id": "d", "text": "Karena aplikasi sengaja mengacak seluruh koordinat di Indonesia"}
    ]'::jsonb,
    'Sesuai protokol integritas data EduEarth, apabila sumber resmi hanya mencantumkan nama desa/kecamatan tanpa koordinat tapak presisi, titik ditandai jujur sebagai "Lokasi perkiraan" (approximate).',
    4
  ),
  (
    '22222222-2222-4222-8222-222222222505',
    '11111111-1111-4111-8111-111111111105',
    'Apa keuntungan menerapkan sistem Mikrogrid Hibrida (misalnya PLTS + Baterai + Biomassa/Mikrohidro) pada pulau-pulau terpencil di Indonesia?',
    '[
      {"id": "a", "text": "Mengharuskan pulau tersebut menarik kabel bawah laut ribuan kilometer ke pulau Jawa"},
      {"id": "b", "text": "Membuat pulau hanya memiliki listrik selama 2 jam sehari"},
      {"id": "c", "text": "Meningkatkan kemandirian energi lokal dengan memadukan sumber energi setempat dan mengurangi ketergantungan pengiriman bahan bakar fosil lewat laut"},
      {"id": "d", "text": "Menghilangkan kebutuhan perawatan peralatan sama sekali"}
    ]'::jsonb,
    'Mikrogrid hibrida mengoptimalkan potensi energi bersih lokal di pulau tersebut dan saling menopang antara sumber variabel (surya) dengan penyimpanan baterai atau pembangkit lokal lainnya.',
    5
  ),
  (
    '22222222-2222-4222-8222-222222222506',
    '11111111-1111-4111-8111-111111111105',
    'Kombinasi pembangkit manakah yang paling tepat untuk menyuplai kebutuhan beban dasar (baseload) 24 jam sekaligus merespons lonjakan beban puncak dengan cepat?',
    '[
      {"id": "a", "text": "PLTP (Panas Bumi) sebagai pemikul beban dasar + PLTA Waduk sebagai penyeimbang beban puncak"},
      {"id": "b", "text": "PLTS tanpa baterai untuk malam hari"},
      {"id": "c", "text": "Hanya mengandalkan satu PLTB saat musim angin teduh"},
      {"id": "d", "text": "Mematikan seluruh gardu induk saat sore hari"}
    ]'::jsonb,
    'PLTP beroperasi stabil sepanjang waktu sebagai baseload, sedangkan PLTA berwaduk dapat mengatur bukaan katup airnya dengan sangat cepat ketika beban listrik masyarakat melonjak.',
    6
  )
on conflict (id) do update set
  quiz_id = excluded.quiz_id,
  question = excluded.question,
  options = excluded.options,
  explanation = excluded.explanation,
  sort_order = excluded.sort_order;

-- Seed Kunci Jawaban 30 Soal (Variasi A, B, C, D — hanya dapat dibaca oleh RPC Server)
insert into public.quiz_answer_keys (question_id, correct_option_id)
values
  -- Kuis 1 (a, b, c, d, a, b)
  ('22222222-2222-4222-8222-222222222101', 'a'),
  ('22222222-2222-4222-8222-222222222102', 'b'),
  ('22222222-2222-4222-8222-222222222103', 'c'),
  ('22222222-2222-4222-8222-222222222104', 'd'),
  ('22222222-2222-4222-8222-222222222105', 'a'),
  ('22222222-2222-4222-8222-222222222106', 'b'),

  -- Kuis 2 (a, c, b, d, a, b)
  ('22222222-2222-4222-8222-222222222201', 'a'),
  ('22222222-2222-4222-8222-222222222202', 'c'),
  ('22222222-2222-4222-8222-222222222203', 'b'),
  ('22222222-2222-4222-8222-222222222204', 'd'),
  ('22222222-2222-4222-8222-222222222205', 'a'),
  ('22222222-2222-4222-8222-222222222206', 'b'),

  -- Kuis 3 (a, b, c, d, a, b)
  ('22222222-2222-4222-8222-222222222301', 'a'),
  ('22222222-2222-4222-8222-222222222302', 'b'),
  ('22222222-2222-4222-8222-222222222303', 'c'),
  ('22222222-2222-4222-8222-222222222304', 'd'),
  ('22222222-2222-4222-8222-222222222305', 'a'),
  ('22222222-2222-4222-8222-222222222306', 'b'),

  -- Kuis 4 (b, a, c, d, b, c)
  ('22222222-2222-4222-8222-222222222401', 'b'),
  ('22222222-2222-4222-8222-222222222402', 'a'),
  ('22222222-2222-4222-8222-222222222403', 'c'),
  ('22222222-2222-4222-8222-222222222404', 'd'),
  ('22222222-2222-4222-8222-222222222405', 'b'),
  ('22222222-2222-4222-8222-222222222406', 'c'),

  -- Kuis 5 (a, b, c, b, c, a)
  ('22222222-2222-4222-8222-222222222501', 'a'),
  ('22222222-2222-4222-8222-222222222502', 'b'),
  ('22222222-2222-4222-8222-222222222503', 'c'),
  ('22222222-2222-4222-8222-222222222504', 'b'),
  ('22222222-2222-4222-8222-222222222505', 'c'),
  ('22222222-2222-4222-8222-222222222506', 'a')
on conflict (question_id) do update set
  correct_option_id = excluded.correct_option_id;

-- ============================================================================
-- BAGIAN 3: 12 BADGE PENCAPAIAN & EVALUASI SERVER (check_and_award_achievements)
-- ============================================================================

insert into public.achievements (code, title, description, icon, points, sort_order)
values
  (
    'first_bookmark',
    'Penjelajah Ingin Tahu',
    'Menyimpan materi pembelajaran atau pembangkit pertama ke Daftar Tersimpan.',
    'bookmark_added_rounded',
    10,
    1
  ),
  (
    'avid_learner',
    'Pembelajar Energi Bersih',
    'Menyimpan minimal 2 materi pembelajaran energi terbarukan untuk dipelajari.',
    'menu_book_rounded',
    20,
    2
  ),
  (
    'library_guardian',
    'Kolektor Pustaka Hijau',
    'Menyimpan minimal 5 materi pembelajaran energi terbarukan di Daftar Tersimpan.',
    'auto_stories_rounded',
    35,
    3
  ),
  (
    'plant_collector',
    'Pemeta Nusantara',
    'Menyimpan minimal 2 lokasi pembangkit energi terbarukan di Indonesia.',
    'map_rounded',
    20,
    4
  ),
  (
    'grid_explorer',
    'Penjelajah Jaringan EBT',
    'Menyimpan minimal 5 lokasi pembangkit energi terbarukan dari peta Nusantara.',
    'explore_rounded',
    35,
    5
  ),
  (
    'all_rounder_saver',
    'Kolektor Seimbang',
    'Menyimpan setidaknya 1 materi pembelajaran sekaligus 1 lokasi pembangkit.',
    'stars_rounded',
    25,
    6
  ),
  (
    'first_quiz',
    'Langkah Pertama Kuis',
    'Menyelesaikan percobaan kuis energi terbarukan pertama hingga tuntas.',
    'quiz_rounded',
    15,
    7
  ),
  (
    'quiz_enthusiast',
    'Pejuang Kuis Tangguh',
    'Menyelesaikan minimal 3 percobaan kuis evaluasi di EduEarth.',
    'bolt_rounded',
    30,
    8
  ),
  (
    'multi_quiz_explorer',
    'Penakluk Lintas Topik',
    'Menyelesaikan minimal 3 topik kuis yang berbeda di EduEarth.',
    'military_tech_rounded',
    40,
    9
  ),
  (
    'quiz_master',
    'Juara Energi Terbarukan',
    'Meraih skor minimal 80 pada salah satu kuis evaluasi EduEarth.',
    'workspace_premium_rounded',
    30,
    10
  ),
  (
    'consistent_scholar',
    'Cendekiawan Konsisten',
    'Meraih skor tinggi (minimal 80) sebanyak 3 kali atau lebih pada kuis EduEarth.',
    'school_rounded',
    45,
    11
  ),
  (
    'perfect_score',
    'Master Skor Sempurna 100',
    'Menjawab seluruh pertanyaan dengan benar (skor 100) pada kuis EduEarth.',
    'emoji_events_rounded',
    60,
    12
  )
on conflict (code) do update
set
  title = excluded.title,
  description = excluded.description,
  icon = excluded.icon,
  points = excluded.points,
  sort_order = excluded.sort_order;

create or replace function public.check_and_award_achievements()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_bookmark_count integer := 0;
  v_material_bookmark_count integer := 0;
  v_plant_bookmark_count integer := 0;
  v_quiz_count integer := 0;
  v_distinct_quiz_count integer := 0;
  v_high_score_count integer := 0;
  v_max_score integer := 0;
  v_newly_awarded jsonb := '[]'::jsonb;
  v_total_unlocked integer := 0;
begin
  if v_user_id is null then
    raise exception 'Pengguna harus masuk (login) untuk mengevaluasi pencapaian.';
  end if;

  select
    count(*)::integer,
    count(*) filter (where material_id is not null)::integer,
    count(*) filter (where plant_id is not null)::integer
  into
    v_bookmark_count,
    v_material_bookmark_count,
    v_plant_bookmark_count
  from public.bookmarks
  where user_id = v_user_id;

  select
    count(*)::integer,
    count(distinct quiz_id)::integer,
    count(*) filter (where score >= 80)::integer,
    coalesce(max(score), 0)::integer
  into
    v_quiz_count,
    v_distinct_quiz_count,
    v_high_score_count,
    v_max_score
  from public.quiz_attempts
  where user_id = v_user_id;

  with eligible_codes as (
    select code
    from (
      values
        ('first_bookmark', v_bookmark_count >= 1),
        ('avid_learner', v_material_bookmark_count >= 2),
        ('library_guardian', v_material_bookmark_count >= 5),
        ('plant_collector', v_plant_bookmark_count >= 2),
        ('grid_explorer', v_plant_bookmark_count >= 5),
        ('all_rounder_saver', v_material_bookmark_count >= 1 and v_plant_bookmark_count >= 1),
        ('first_quiz', v_quiz_count >= 1),
        ('quiz_enthusiast', v_quiz_count >= 3),
        ('multi_quiz_explorer', v_distinct_quiz_count >= 3),
        ('quiz_master', v_max_score >= 80),
        ('consistent_scholar', v_high_score_count >= 3),
        ('perfect_score', v_max_score >= 100)
    ) as t(code, is_met)
    where t.is_met = true
  ),
  inserted as (
    insert into public.user_achievements (user_id, achievement_id)
    select v_user_id, a.id
    from public.achievements a
    inner join eligible_codes e on e.code = a.code
    on conflict (user_id, achievement_id) do nothing
    returning achievement_id
  )
  select coalesce(
    jsonb_agg(a.title order by a.sort_order),
    '[]'::jsonb
  )
  into v_newly_awarded
  from inserted i
  inner join public.achievements a on a.id = i.achievement_id;

  select count(*)::integer
  into v_total_unlocked
  from public.user_achievements
  where user_id = v_user_id;

  return jsonb_build_object(
    'newly_awarded_titles', v_newly_awarded,
    'total_unlocked', v_total_unlocked
  );
end;
$$;

revoke all on function public.check_and_award_achievements() from public, anon;
grant execute on function public.check_and_award_achievements() to authenticated;


