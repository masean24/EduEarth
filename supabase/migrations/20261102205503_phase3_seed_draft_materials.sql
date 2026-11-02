-- ============================================================================
-- Fase 3 (3/3): Seed Draf Materi Pembelajaran Konsep Dasar (5 Kategori Energi)
-- ============================================================================
-- PENTING: Seluruh materi pada seed ini ditandai "[DRAF]" pada judul dan ringkasan
-- untuk direview pemilik sebelum rilis. Hanya memuat konsep fisika/rekayasa umum
-- (prinsip kerja, kelebihan, dan keterbatasan umum) TANPA statistik, angka kapasitas,
-- atau klaim spesifik tanpa sumber.

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
  is_published
)
values
  (
    (select id from public.energy_categories where slug = 'solar'),
    '[DRAF] Konsep Dasar Pembangkit Listrik Tenaga Surya (PLTS)',
    'draf-konsep-dasar-plts',
    '[DRAF - Perlu Review] Pengenalan prinsip efek fotovoltaik, komponen utama sistem PLTS, serta kelebihan dan keterbatasan energi surya secara umum.',
    '## Pengertian Umum

**Pembangkit Listrik Tenaga Surya (PLTS)** adalah sistem pembangkit energi yang mengubah radiasi cahaya matahari secara langsung menjadi energi listrik menggunakan prinsip **efek fotovoltaik** pada material semikonduktor.

---

## Cara Kerja Sistem PLTS

1. **Penyerapan Foton:** Panel surya tersusun atas sel-sel fotovoltaik (umumnya berbahan silikon). Saat cahaya matahari mengenai permukaan sel, energi foton melepaskan elektron di dalam semikonduktor.
2. **Aliran Arus Searah (DC):** Pergerakan elektron menghasilkan arus listrik searah (*Direct Current* / DC).
3. **Konversi di Inverter:** Arus DC dialirkan menuju *inverter* untuk diubah menjadi arus bolak-balik (*Alternating Current* / AC) agar dapat digunakan oleh peralatan listrik rumah tangga atau disalurkan ke jaringan listrik.

---

## Kelebihan Secara Umum

- **Sumber energi bersih:** Tidak menghasilkan emisi gas buang saat beroperasi.
- **Modular dan fleksibel:** Dapat dipasang dalam skala kecil (atap bangunan) maupun skala utilitas (ladang panel surya).
- **Minim bagian bergerak:** Biaya dan kebutuhan perawatan mekanis relatif sederhana.

---

## Keterbatasan Secara Umum

- **Bersifat intermiten:** Produksi listrik sangat bergantung pada intensitas penyinaran matahari, kondisi awan, dan hanya berlangsung pada siang hari.
- **Kebutuhan penyimpanan:** Memerlukan sistem baterai (*Battery Energy Storage System*) atau penyeimbang jaringan bila ingin menyuplai listrik di malam hari.
- **Kebutuhan luas area:** Instalasi skala besar memerlukan ruang terbuka yang tidak terhalang bayangan.

---

### Referensi Belajar Lebih Lanjut
- [International Renewable Energy Agency (IRENA) — Solar Energy](https://www.irena.org/Energy-Transition/Technology/Solar-energy)',
    null,
    4,
    'beginner',
    1,
    true
  ),
  (
    (select id from public.energy_categories where slug = 'hydro'),
    '[DRAF] Konsep Dasar Pembangkit Listrik Tenaga Air (PLTA)',
    'draf-konsep-dasar-plta',
    '[DRAF - Perlu Review] Penjelasan konversi energi potensial dan kinetik air menjadi energi mekanik turbin dan listrik, beserta kelebihan dan tantangannya.',
    '## Pengertian Umum

**Pembangkit Listrik Tenaga Air (PLTA)** memanfaatkan energi potensial gravitasi dan energi kinetik dari aliran atau terjunan air untuk memutar turbin air yang terhubung dengan generator listrik.

---

## Cara Kerja Sistem PLTA

1. **Pengumpulan atau Pengalihan Air:** Sistem *reservoir* (bendungan/waduk) menahan air pada ketinggian tertentu untuk menciptakan beda tinggi (*head*), sedangkan sistem *run-of-river* memanfaatkan aliran sungai secara langsung melalui saluran pengarah.
2. **Penyaluran lewat Pipa Pesat (*Penstock*):** Air dialirkan dengan tekanan menuju sudu-sudu turbin.
3. **Putaran Turbin & Generator:** Dorongan air memutar turbin (energi mekanik), lalu poros turbin memutar rotor generator untuk menghasilkan energi listrik melalui induksi elektromagnetik.
4. **Pengembalian Air:** Air yang telah melewati turbin dikembalikan kembali ke hilir sungai melalui saluran pembuangan (*tailrace*).

---

## Kelebihan Secara Umum

- **Pasokan relatif stabil:** Terutama pada PLTA berbasis waduk yang laju alirannya dapat diatur sesuai kebutuhan beban listrik.
- **Respon cepat:** Mampu menyesuaikan output daya dengan cepat untuk menjaga kestabilan frekuensi jaringan.
- **Umur teknis panjang:** Infrastruktur sipil dan turbin air dirancang untuk beroperasi dalam jangka waktu panjang.

---

## Keterbatasan Secara Umum

- **Ketergantungan hidrologi:** Kinerja dipengaruhi oleh ketersediaan curah hujan dan kondisi daerah aliran sungai (DAS) di hulu.
- **Dampak lingkungan dan sosial lokal:** Pembangunan bendungan besar memerlukan kajian mendalam terkait ekosistem sungai dan tata guna lahan.
- **Waktu konstruksi:** Membutuhkan perencanaan geoteknik dan pembangunan sipil yang cermat.

---

### Referensi Belajar Lebih Lanjut
- [International Renewable Energy Agency (IRENA) — Hydropower](https://www.irena.org/Energy-Transition/Technology/Hydropower)',
    null,
    5,
    'beginner',
    1,
    true
  ),
  (
    (select id from public.energy_categories where slug = 'wind'),
    '[DRAF] Konsep Dasar Pembangkit Listrik Tenaga Bayu (PLTB)',
    'draf-konsep-dasar-pltb',
    '[DRAF - Perlu Review] Dasar aerodinamika turbin angin dalam mengubah hembusan angin menjadi energi listrik, serta kelebihan dan keterbatasannya.',
    '## Pengertian Umum

**Pembangkit Listrik Tenaga Bayu (PLTB)** adalah sistem konversi energi yang mengubah energi kinetik pergerakan udara (angin) menjadi energi mekanik pada poros rotor, lalu menjadi energi listrik melalui generator.

---

## Cara Kerja Sistem PLTB

1. **Gaya Aerodinamis pada Bilah (*Blades*):** Ketika angin melewati bilah turbin yang dirancang khusus seperti sayap pesawat, tercipta gaya angkat (*lift*) yang membuat rotor berputar.
2. **Transmisi di *Nacelle*:** Di dalam rumah turbin (*nacelle*) di puncak menara, putaran rotor diteruskan ke generator (baik secara langsung dengan *direct-drive* maupun melalui *gearbox* peningkat putaran).
3. **Sistem Pengarah (*Yaw & Pitch Control*):** Turbin modern dilengkapi sensor arah angin dan pengatur sudut bilah agar tetap menghadap arah angin secara optimal dan aman saat angin terlalu kencang.

---

## Kelebihan Secara Umum

- **Tidak membutuhkan bahan bakar:** Memanfaatkan pergerakan angin alami tanpa konsumsi air pendingin maupun bahan bakar fosil.
- **Pemanfaatan lahan ganda:** Area di sekitar dasar menara turbin darat (*onshore*) umumnya masih dapat dimanfaatkan untuk pertanian atau penggembalaan.

---

## Keterbatasan Secara Umum

- **Fluktuasi kecepatan angin:** Hembusan angin berubah-ubah terhadap waktu dan musim, sehingga output daya bersifat variabel.
- **Spesifik lokasi:** Hanya efektif dibangun di wilayah yang memiliki profil kecepatan angin yang konsisten.
- **Tantangan logistik:** Bilah dan menara berukuran besar memerlukan akses transportasi khusus menuju lokasi pemasangan.

---

### Referensi Belajar Lebih Lanjut
- [International Renewable Energy Agency (IRENA) — Wind Energy](https://www.irena.org/Energy-Transition/Technology/Wind-energy)',
    null,
    4,
    'beginner',
    1,
    true
  ),
  (
    (select id from public.energy_categories where slug = 'geothermal'),
    '[DRAF] Konsep Dasar Pembangkit Listrik Tenaga Panas Bumi (PLTP)',
    'draf-konsep-dasar-pltp',
    '[DRAF - Perlu Review] Cara pemanfaatan fluida uap panas dari reservoir bawah permukaan bumi untuk pembangkit listrik beban dasar (baseload).',
    '## Pengertian Umum

**Pembangkit Listrik Tenaga Panas Bumi (PLTP)** adalah pembangkit yang memanfaatkan energi termal (panas) yang tersimpan di dalam kerak bumi untuk memanaskan fluida dan menggerakkan turbin uap.

---

## Cara Kerja Sistem PLTP

1. **Ekstraksi Fluida Panas Bumi:** Melalui sumur produksi yang dibor hingga ke reservoir panas bumi, uap panas atau air bersuhu tinggi dialirkan ke permukaan.
2. **Pemisahan & Pemutaran Turbin:** Pada sistem uap kering (*dry steam*) atau *flash steam*, uap bertekanan tinggi diarahkan langsung memutar turbin uap. Pada sistem siklus biner (*binary cycle*), panas fluida digunakan untuk menguapkan fluida kerja sekunder yang memiliki titik didih lebih rendah.
3. **Kondensasi & Injeksi Kembali (*Reinjection*):** Uap yang telah melewati turbin didinginkan kembali menjadi cair di kondensor, kemudian diinjeksikan kembali ke dalam perut bumi melalui sumur injeksi untuk menjaga keberlanjutan tekanan reservoir.

---

## Kelebihan Secara Umum

- **Pembangkit beban dasar (*Baseload*):** Tidak bergantung pada cuaca harian maupun pergantian siang-malam, sehingga dapat beroperasi secara kontinu.
- **Jejak lahan permukaan kompak:** Dibandingkan kapasitas dayanya, fasilitas permukaan PLTP relatif ringkas.

---

## Keterbatasan Secara Umum

- **Terbatas secara geologis:** Hanya dapat dikembangkan di zona geologi aktif yang memiliki sistem hidrotermal memadai.
- **Risiko eksplorasi awal:** Tahap survei geosains dan pengeboran sumur eksplorasi membutuhkan biaya awal serta ketelitian teknis yang tinggi.

---

### Referensi Belajar Lebih Lanjut
- [International Renewable Energy Agency (IRENA) — Geothermal Energy](https://www.irena.org/Energy-Transition/Technology/Geothermal-energy)',
    null,
    5,
    'intermediate',
    1,
    true
  ),
  (
    (select id from public.energy_categories where slug = 'bioenergy'),
    '[DRAF] Konsep Dasar Pembangkit Listrik Tenaga Bioenergi (PLTBm & PLTBg)',
    'draf-konsep-dasar-bioenergi',
    '[DRAF - Perlu Review] Pengenalan konversi biomassa padat (PLTBm) dan biogas hasil fermentasi anaerobik (PLTBg) menjadi energi listrik.',
    '## Pengertian Umum

**Bioenergi** mencakup pemanfaatan bahan organik (biomassa) yang berasal dari tanaman, residu pertanian/perkebunan, maupun limbah organik untuk menghasilkan panas, bahan bakar, atau listrik melalui **PLTBm (Biomassa)** dan **PLTBg (Biogas)**.

---

## Cara Kerja Sistem Bioenergi

1. **Jalur Termokimia (PLTBm — Biomassa Padat):** Bahan organik padat (seperti residu kayu, cangkang, atau sekam) digunakan sebagai bahan bakar pada ketel uap (*boiler*) atau melalui proses gasifikasi untuk menghasilkan uap bertekanan yang memutar turbin.
2. **Jalur Biokimia (PLTBg — Biogas):** Limbah organik cair atau basah diolah di dalam reaktor kedap udara (*anaerobic digester*). Mikroorganisme menguraikan bahan organik dan menghasilkan gas metana yang kemudian digunakan untuk menggerakkan mesin generator (*gas engine*).

---

## Kelebihan Secara Umum

- **Mendukung ekonomi sirkular:** Memanfaatkan residu organik dari aktivitas pertanian atau agroindustri sehingga mengurangi limbah yang terbuang.
- **Dapat diatur (*Dispatchable*):** Selama pasokan bahan baku biomassa atau biogas tersedia dan tersimpan, pembangkit dapat dioperasikan sesuai jadwal kebutuhan.

---

## Keterbatasan Secara Umum

- **Keberlanjutan rantai pasok:** Memerlukan manajemen pengumpulan, pengangkutan, dan penyimpanan bahan baku organik secara konsisten agar tidak terganggu musim panen.
- **Pengendalian emisi pembakaran:** Membutuhkan sistem penyaring udara yang baik pada fasilitas pembakaran biomassa serta pengelolaan tata guna lahan yang bertanggung jawab.

---

### Referensi Belajar Lebih Lanjut
- [International Renewable Energy Agency (IRENA) — Bioenergy](https://www.irena.org/Energy-Transition/Technology/Bioenergy)',
    null,
    5,
    'beginner',
    1,
    true
  )
on conflict (slug) do update set
  title = excluded.title,
  summary = excluded.summary,
  content_md = excluded.content_md,
  read_minutes = excluded.read_minutes,
  difficulty = excluded.difficulty,
  sort_order = excluded.sort_order,
  is_published = excluded.is_published,
  updated_at = now();
