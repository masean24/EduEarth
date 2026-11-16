-- ============================================================================
-- Fase 9: Finalisasi Blueprint V2 — Perbandingan Energi Berbasis Sumber,
-- Modul Materi Ke-9 (Transisi Energi & Trade-Off Lingkungan), dan Panduan Pusat Informasi
-- ============================================================================
-- PRINSIP INTEGRITAS DATA (FINAL_EDUEARTH_PRODUCT_BLUEPRINT_V2.md):
-- 1. Seluruh perbandingan dan materi menggunakan bahasa non-generalisasi ("umumnya",
--    "bergantung pada desain") serta menyajikan manfaat dan tantangan lingkungan
--    secara seimbang.
-- 2. Tidak ada angka klaim/kalkulasi emisi tanpa metodologi. Seluruh rujukan
--    mengacu pada IPCC AR6 WGIII (2022), IRENA, dan Kementerian ESDM (Ditjen EBTKE).
-- 3. Migrasi ini bersifat idempotent (aman dijalankan ulang tanpa duplikasi).

-- ============================================================================
-- BAGIAN 1: PEMBARUAN MATRIKS PERBANDINGAN ENERGI (`energy_categories.comparison`)
-- ============================================================================

update public.energy_categories
set comparison = jsonb_build_object(
  'sumber_energi', 'Radiasi cahaya matahari yang dikonversi melalui efek fotovoltaik pada sel semikonduktor silikon.',
  'karakter_pasokan', 'Umumnya bersifat variabel (intermiten); berproduksi optimal pada siang hari dan dipengaruhi tutupan awan.',
  'faktor_kapasitas', 'Umumnya relatif rendah hingga menengah karena mengikuti jam penyinaran matahari harian.',
  'emisi_siklus_hidup', 'Sangat rendah saat beroperasi (tanpa pembakaran bahan bakar); jejak emisi siklus hidup terutama berasal dari proses manufaktur modul dan konstruksi.',
  'kebutuhan_lahan', 'Umumnya membutuhkan area permukaan yang luas per satuan MW di daratan, namun dapat memanfaatkan atap bangunan atau permukaan waduk (PLTS terapung).',
  'keunggulan_utama', 'Bersifat modular, tidak memerlukan air pendingin turbin, dan tidak menghasilkan emisi gas buang saat beroperasi.',
  'tantangan_utama', 'Fluktuasi daya saat mendung/malam hari memerlukan dukungan penyimpanan baterai (BESS) atau pembangkit penyeimbang di jaringan.',
  'karakter_lokasi', 'Umumnya cocok di wilayah dengan iradiasi matahari konsisten, lahan terbuka atau perairan tenang, dan minim bayangan penghalang.',
  'manfaat_lingkungan', 'Menghasilkan listrik tanpa pembakaran bahan bakar fosil saat operasi serta dapat dipasang pada permukaan waduk buatan untuk menghemat lahan darat.',
  'tantangan_lingkungan', 'Membutuhkan tata guna lahan yang terencana pada instalasi darat skala besar serta pengelolaan daur ulang limbah modul surya dan baterai di akhir masa pakai.',
  'variasi_desain', 'Karakteristik tiap PLTS dapat berbeda antara PLTS tanpa penyimpanan, PLTS dengan baterai (BESS), PLTS darat (ground-mounted), maupun PLTS terapung (floating PV).'
),
updated_at = now()
where slug = 'solar';

update public.energy_categories
set comparison = jsonb_build_object(
  'sumber_energi', 'Energi potensial gravitasi dan kinetik dari aliran sungai atau terjunan air waduk.',
  'karakter_pasokan', 'Umumnya stabil dan fleksibel; pada sistem berwaduk dapat diatur untuk menopang beban dasar maupun beban puncak.',
  'faktor_kapasitas', 'Umumnya menengah hingga tinggi, bergantung pada ketersediaan debit air Daerah Aliran Sungai (DAS) lintas musim.',
  'emisi_siklus_hidup', 'Sangat rendah selama operasi pembangkitan listrik; emisi siklus hidup berasal dari konstruksi sipil bendungan dan kondisi biogenik waduk.',
  'kebutuhan_lahan', 'Luas untuk sistem bendungan berwaduk besar; relatif lebih ringkas untuk sistem aliran sungai langsung (run-of-river).',
  'keunggulan_utama', 'Umur teknis infrastruktur panjang dan mampu merespons perubahan beban jaringan listrik dengan cepat.',
  'tantangan_utama', 'Waktu dan biaya konstruksi sipil awal tinggi serta produksi daya dapat menurun saat musim kemarau panjang.',
  'karakter_lokasi', 'Umumnya cocok di wilayah bertopografi pegunungan/perbukitan (memiliki beda tinggi/head) dengan aliran sungai berdebit memadai.',
  'manfaat_lingkungan', 'Menyuplai energi rendah karbon dalam kapasitas besar sekaligus membantu menstabilkan jaringan listrik saat pembangkit cuaca (surya/angin) berfluktuasi.',
  'tantangan_lingkungan', 'Pembuatan waduk besar dapat mengubah ekosistem sungai, memengaruhi migrasi ikan, memerlukan alih fungsi lahan genangan, dan menuntut kelestarian hutan hulu DAS.',
  'variasi_desain', 'PLTA berwaduk (reservoir), PLTA aliran sungai langsung (run-of-river), dan PLTA Pumped Storage memiliki fleksibilitas operasional serta dampak lahan yang berbeda.'
),
updated_at = now()
where slug = 'hydro';

update public.energy_categories
set comparison = jsonb_build_object(
  'sumber_energi', 'Energi kinetik hembusan massa udara yang memutar bilah aerodinamis rotor turbin angin.',
  'karakter_pasokan', 'Umumnya variabel (intermiten); mengikuti fluktuasi kecepatan angin harian maupun pola angin musiman (monsun).',
  'faktor_kapasitas', 'Umumnya rendah hingga menengah, sangat bergantung pada kelas kecepatan angin lokal dan tinggi menara.',
  'emisi_siklus_hidup', 'Sangat rendah; tidak menghasilkan emisi gas buang pembakaran selama turbin beroperasi.',
  'kebutuhan_lahan', 'Jarak antar-menara membutuhkan area hamparan terbuka, namun lahan di sekitar kaki menara umumnya masih dapat digunakan untuk pertanian/penggembalaan.',
  'keunggulan_utama', 'Dapat membangkitkan listrik siang maupun malam hari saat angin berhembus dan tidak memerlukan air pendingin.',
  'tantangan_utama', 'Terbatas pada lokasi dengan koridor angin yang memadai serta memerlukan pengaturan kestabilan frekuensi jaringan.',
  'karakter_lokasi', 'Umumnya cocok di kawasan pesisir, punggung perbukitan terbuka, atau celah pegunungan dengan hembusan angin terarah.',
  'manfaat_lingkungan', 'Menghasilkan listrik tanpa emisi pembakaran dan tanpa konsumsi air pada masa operasional.',
  'tantangan_lingkungan', 'Membutuhkan kajian lokasi untuk meminimalkan risiko tabrakan satwa terbang (burung/kelelawar), kebisingan mekanis, serta dampak visual lanskap.',
  'variasi_desain', 'Kinerja tiap PLTB bervariasi menurut tinggi menara (hub height), diameter rotor, profil angin musiman, dan dukungan sistem penyimpanan di gardu induk.'
),
updated_at = now()
where slug = 'wind';

update public.energy_categories
set comparison = jsonb_build_object(
  'sumber_energi', 'Panas alami dan uap bertekanan dari reservoar hidrotermal di dalam kerak bumi.',
  'karakter_pasokan', 'Umumnya berperan sebagai pemikul beban dasar (baseload) yang beroperasi kontinu 24 jam tanpa bergantung cuaca harian.',
  'faktor_kapasitas', 'Umumnya tinggi dibandingkan pembangkit energi terbarukan berbasis cuaca.',
  'emisi_siklus_hidup', 'Rendah dibandingkan pembangkit fosil, terutama dengan penerapan injeksi ulang (reinjection) fluida kembali ke sumur.',
  'kebutuhan_lahan', 'Tapak fasilitas permukaan per satuan MW umumnya relatif ringkas dibandingkan ladang surya atau waduk air.',
  'keunggulan_utama', 'Keluaran daya stabil sepanjang tahun sehingga andal sebagai tulang punggung jaringan kelistrikan.',
  'tantangan_utama', 'Risiko ketidakpastian geologi bawah permukaan pada tahap pengeboran eksplorasi awal dan durasi pengembangan proyek yang panjang.',
  'karakter_lokasi', 'Umumnya berada di sepanjang jalur sabuk vulkanik aktif (Ring of Fire) yang memiliki sistem hidrotermal bawah permukaan.',
  'manfaat_lingkungan', 'Menyediakan pasokan listrik beban dasar rendah karbon yang stabil tanpa ketergantungan pada bahan bakar fosil.',
  'tantangan_lingkungan', 'Banyak prospek berada di kawasan hutan/pegunungan sehingga memerlukan pengelolaan pembukaan lahan, reinjeksi air termal (brine), dan pengendalian gas non-kondensabel (seperti H₂S).',
  'variasi_desain', 'Teknologi PLTP bervariasi antara sistem uap kering (dry steam), uap pemisahan (flash steam), dan siklus biner (binary cycle) sesuai suhu dan tekanan reservoar.'
),
updated_at = now()
where slug = 'geothermal';

update public.energy_categories
set comparison = jsonb_build_object(
  'sumber_energi', 'Bahan organik terbarukan seperti residu pertanian/perkebunan (biomassa padat) atau limbah cair organik (biogas).',
  'karakter_pasokan', 'Umumnya dapat dikendalikan jadwal operasinya (dispatchable) selama pasokan bahan baku organik tersedia.',
  'faktor_kapasitas', 'Umumnya menengah hingga tinggi, bergantung pada kontinuitas rantai pasok bahan baku biomassa atau biogas.',
  'emisi_siklus_hidup', 'Bergantung pada sumber bahan baku; rendah apabila memanfaatkan limbah/residu agroindustri secara berkelanjutan.',
  'kebutuhan_lahan', 'Fasilitas pembangkit umumnya terintegrasi di dekat pabrik pengolahan agroindustri, namun perkebunan bahan baku membutuhkan lahan.',
  'keunggulan_utama', 'Mengubah residu organik menjadi energi sekaligus membantu pengelolaan limbah pertanian/perkebunan.',
  'tantangan_utama', 'Membutuhkan kepastian logistik pengumpulan, transportasi, penyimpanan, dan pengendalian kadar air bahan baku lintas musim.',
  'karakter_lokasi', 'Umumnya cocok di dekat sentra perkebunan, pertanian, atau pabrik pengolahan agroindustri (seperti kelapa sawit, padi, atau tebu).',
  'manfaat_lingkungan', 'Mendukung sirkularitas limbah organik dan pada reaktor biogas (PLTBg) membantu menangkap gas metana dari limbah cair agar tidak lepas ke atmosfer.',
  'tantangan_lingkungan', 'Wajib memastikan bahan baku berasal dari limbah/residu lestari (bukan deforestasi) serta mengendalikan emisi partikulat/gas buang pada pembakaran boiler PLTBm.',
  'variasi_desain', 'Berbeda nyata antara PLTBm (pembakaran termokimia biomassa padat seperti cangkang sawit/sekam) dan PLTBg (fermentasi anaerobik limbah cair menjadi gas metana).'
),
updated_at = now()
where slug = 'bioenergy';

-- ============================================================================
-- BAGIAN 2: MODUL MATERI KE-9 — TRANSISI ENERGI & TRADE-OFF LINGKUNGAN
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
values (
  (select id from public.energy_categories where slug = 'solar'),
  'Transisi Energi Indonesia: Manfaat dan Tantangan Lingkungan Energi Terbarukan',
  'transisi-energi-dan-dampak-lingkungan',
  'Memahami pengertian transisi energi, alasan peralihan dari bahan bakar fosil, serta telaah berimbang manfaat dan tantangan lingkungan (trade-off) dari 5 kategori energi terbarukan di Indonesia.',
  '> **Intisari Konsep:** Transisi energi bertujuan mengurangi emisi gas rumah kaca dari sektor ketenagalistrikan dengan beralih secara bertahap dari bahan bakar fosil ke sumber energi terbarukan, sembari mengelola tantangan teknis dan dampak ekologis lokal setiap jenis pembangkit secara bertanggung jawab.

## 1. Pengertian Transisi Energi & Alasan Peralihan dari Energi Fosil

**Transisi energi** adalah transformasi struktural pada sistem penyediaan dan pemanfaatan energi—dari sistem yang mengandalkan pembakaran bahan bakar fosil (batu bara, minyak bumi, dan gas alam) menuju sistem energi rendah karbon berbasis **Energi Baru dan Terbarukan (EBT)**.

Mengapa peralihan ini penting dipelajari?
1. **Mitigasi Perubahan Iklim:** Berdasarkan laporan ilmiah *Intergovernmental Panel on Climate Change* (**IPCC AR6 WGIII, 2022**), pembakaran bahan bakar fosil pada pembangkit listrik konvensional merupakan salah satu penyumbang terbesar emisi karbon dioksida ($\text{CO}_2$) global yang memicu pemanasan suhu bumi.
2. **Ketahanan Energi Jangka Panjang:** Bahan bakar fosil bersifat tak terbarukan dan cadangannya terbatas, sedangkan potensi energi surya, air, angin, panas bumi, dan bioenergi dapat diperbarui melalui siklus alam jika dikelola secara lestari.
3. **Kesesuaian Potensi Lokal Kepulauan:** Sebagai negara kepulauan, memanfaatkan sumber energi bersih yang tersedia di masing-masing daerah membantu mengurangi ketergantungan pengiriman bahan bakar lintas pulau.

---

## 2. Kontribusi Energi Terbarukan & Konsep Emisi Siklus Hidup

Pembangkit energi terbarukan seperti PLTS, PLTA, PLTB, dan PLTP **umumnya menghasilkan emisi gas rumah kaca yang jauh lebih rendah selama masa operasional** dibandingkan pembangkit listrik berbahan bakar batu bara karena tidak mengandalkan pembakaran bahan bakar fosil.

Namun, dalam ilmu lingkungan modern, evaluasi dampak tidak hanya melihat saat pembangkit beroperasi, melainkan menggunakan pendekatan **Analisis Siklus Hidup (*Life-Cycle Assessment* / LCA)**—mulai dari penambangan material, pembuatan komponen, konstruksi, operasional, hingga pengelolaan limbah di akhir masa pakai (*end-of-life*). Oleh karena itu, **tidak ada teknologi energi yang sepenuhnya bebas dari dampak lingkungan**.

---

## 3. Manfaat vs Tantangan Lingkungan (*Trade-Off*) 5 Kategori EBT

Tabel berikut merangkum dua sisi yang perlu dipahami secara berimbang oleh pelajar:

| Kategori EBT | Kontribusi & Manfaat Lingkungan Umum | Tantangan & Trade-Off Lingkungan yang Harus Dikelola |
| :--- | :--- | :--- |
| **Surya (PLTS)** | Mengubah cahaya matahari menjadi listrik tanpa emisi pembakaran dan tanpa konsumsi air pendingin turbin. | Instalasi darat skala besar membutuhkan lahan luas; memerlukan pengelolaan daur ulang modul surya dan baterai pada akhir masa pakai. |
| **Air (PLTA)** | Menyuplai daya rendah karbon berkapasitas besar serta mampu menstabilkan jaringan listrik dengan cepat. | Bendungan berwaduk besar membutuhkan genangan lahan luas, mengubah ekosistem sungai, dan bergantung pada kelestarian hutan hulu DAS. |
| **Angin (PLTB)** | Menghasilkan listrik tanpa pembakaran bahan bakar; lahan di sekitar kaki menara masih dapat dipakai pertanian. | Pasokan bergantung cuaca angin; penempatan menara harus memperhatikan jalur terbang satwa (burung/kelelawar) dan kebisingan. |
| **Panas Bumi (PLTP)** | Menyuplai listrik beban dasar (*baseload*) stabil 24 jam dengan kebutuhan tapak permukaan per MW yang relatif ringkas. | Banyak lokasi berada di dekat kawasan hutan/pegunungan; wajib mengelola sumur reinjeksi fluida (*brine*) dan gas non-kondensabel. |
| **Bioenergi (PLTBm/g)** | Memanfaatkan residu organik agroindustri secara sirkular; PLTBg menangkap gas metana dari limbah cair. | Bahan baku wajib berasal dari limbah/sumber lestari (bukan deforestasi); pembakaran PLTBm tetap memerlukan pengendali emisi partikulat. |

> **Catatan Penting Variasi Desain:** Karakteristik operasional dan dampak lingkungan setiap pembangkit di lapangan dapat berbeda-beda. Sebagai contoh, **PLTA aliran sungai langsung (*run-of-river*)** tidak membutuhkan genangan waduk seluas **PLTA berwaduk (*reservoir*)**, dan **PLTS terapung** memanfaatkan permukaan waduk buatan sehingga tidak membuka lahan daratan baru.

---

## 4. Contoh Studi Kasus Nyata di Indonesia

Dari 128 data pembangkit tercatat di EduEarth (85 beroperasi, 9 konstruksi, dan 34 rencana), kita dapat mengamati bagaimana inovasi teknis diterapkan untuk menjawab tantangan lingkungan:

1. **Pemanfaatan Ruang Waduk pada PLTS Terapung Cirata (Jawa Barat):** Alih-alih membuka lahan pertanian atau hutan di daratan, modul surya dipasang mengapung di atas permukaan Waduk PLTA Cirata yang sudah ada.
2. **Sistem Kaskade Sungai Citarum (PLTA Saguling, Cirata, Jatiluhur):** Air sungai yang sama dimanfaatkan secara berjenjang oleh tiga pembangkit berurutan dari hulu ke hilir untuk mengoptimalkan potensi energi per satuan aliran sungai.
3. **Reinjeksi Fluida pada PLTP Kamojang & Sarulla:** Fluida panas bumi yang telah memutar turbin diinjeksikan kembali ke dalam sumur injeksi untuk menjaga tekanan reservoar sekaligus mencegah pencemaran air permukaan.
4. **Pengolahan Limbah Cair Sawit (POME) pada PLTBg di Sumatera & Kalimantan:** Limbah cair pabrik kelapa sawit difermentasi di dalam reaktor tertutup (*anaerobic digester*) sehingga gas metana tidak terlepas bebas ke udara melainkan menjadi bahan bakar generator listrik.

---

## 5. Kesimpulan & Pertanyaan Refleksi Siswa

Transisi energi bukan sekadar mengganti satu jenis pembangkit dengan pembangkit lain, melainkan **memilih kombinasi teknologi yang paling sesuai dengan kondisi geografis wilayah** sekaligus **meminimalkan dampak ekologis dan sosialnya**.

**Pertanyaan Refleksi untuk Diskusi Kelas:**
1. Mengapa sebuah provinsi tidak disarankan hanya mengandalkan satu jenis pembangkit intermiten (seperti PLTS tanpa penyimpanan) untuk memenuhi seluruh kebutuhan listriknya?
2. Jika daerahmu memiliki sungai berarus deras di dekat kawasan hutan, desain PLTA seperti apa yang umumnya memiliki dampak genangan lahan lebih kecil?
3. Mengapa kejelasan sumber data dan presisi lokasi sangat penting ketika kita mempelajari perencanaan infrastruktur energi?

---

### Referensi Ilmiah & Sumber Rujukan
- **IPCC (2022):** *Climate Change 2022: Mitigation of Climate Change. Contribution of Working Group III to the Sixth Assessment Report of the Intergovernmental Panel on Climate Change* — Chapter 6 (*Energy Systems*) & Annex III.
- **[IRENA — International Renewable Energy Agency](https://www.irena.org/):** *Renewable Power Generation Costs & Technology Briefs*.
- **[Kementerian ESDM — Direktorat Jenderal EBTKE](https://ebtke.esdm.go.id/):** *Buku Saku Bioenergi 2023 & Publikasi Subsektor EBTKE*.',
  null,
  7,
  'intermediate',
  9,
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
-- BAGIAN 3: PEMBARUAN PUSAT INFORMASI (`notifications`) MENJADI PANDUAN EDUKATIF
-- ============================================================================

insert into public.notifications (
  id,
  title,
  body,
  category,
  is_published,
  created_at
)
values
  (
    '00000000-0000-0000-0000-000000000601',
    'Panduan Alur Belajar 4 Pilar EduEarth',
    'Mulai eksplorasi dari Peta Pembangkit (Explore), pelajari alasan geografis dan cara kerja di Detail Pembangkit & Pusat Edukasi (Learn), bandingkan manfaat serta tantangan lingkungan di Perbandingan Energi (Understand Impact), lalu uji pemahamanmu di Kuis (Evaluate).',
    'info',
    true,
    now() - interval '3 hours'
  ),
  (
    '00000000-0000-0000-0000-000000000602',
    'Modul Baru: Manfaat & Tantangan Lingkungan Transisi Energi',
    'Kini tersedia modul pembelajaran ke-9 yang mengulas mengapa transisi dari energi fosil diperlukan sekaligus tantangan lingkungan (trade-off) dari PLTS, PLTA, PLTB, PLTP, dan Bioenergi berdasarkan literatur IPCC, IRENA, dan ESDM.',
    'content',
    true,
    now() - interval '2 hours'
  ),
  (
    '00000000-0000-0000-0000-000000000603',
    'Catatan Akurasi Data: 128 Pembangkit & Presisi Lokasi',
    'Basis data EduEarth memuat 128 titik pembangkit (85 Beroperasi, 9 Konstruksi, 34 Rencana). Sebanyak 64 titik memiliki koordinat tapak presisi (exact) dan 64 titik berlabel "Lokasi perkiraan" (approximate) yang mewakili wilayah administratif desa/kecamatan/kabupaten menurut sumber.',
    'update',
    true,
    now() - interval '1 hour'
  )
on conflict (id) do update set
  title = excluded.title,
  body = excluded.body,
  category = excluded.category,
  is_published = excluded.is_published;

-- ============================================================================
-- BAGIAN 4: PAKET KUIS KE-6 (TRANSISI ENERGI & TRADE-OFF LINGKUNGAN NUSANTARA)
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
values (
  '11111111-1111-4111-8111-111111111106',
  null,
  'Transisi Energi & Trade-Off Lingkungan Nusantara',
  'Uji pemahamanmu mengenai kajian emisi siklus hidup (LCA), manfaat dekarbonisasi, serta tantangan dan trade-off lingkungan dari 5 kategori energi terbarukan di Indonesia.',
  'intermediate',
  240,
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

insert into public.quiz_questions (
  id,
  quiz_id,
  question,
  options,
  explanation,
  sort_order
)
values
  (
    '22222222-2222-4222-8222-222222222601',
    '11111111-1111-4111-8111-111111111106',
    'Mengapa kajian dampak lingkungan pembangkit listrik menggunakan pendekatan Life-Cycle Assessment (LCA / Siklus Hidup)?',
    '[
      {"id": "a", "text": "Agar seluruh tahapan mulai dari ekstraksi material, manufaktur komponen, konstruksi, operasi, hingga pengelolaan limbah akhir ikut diperhitungkan secara ilmiah"},
      {"id": "b", "text": "Karena pembangkit energi terbarukan sama sekali tidak membutuhkan material logam atau lahan saat dibangun"},
      {"id": "c", "text": "Untuk mengabaikan dampak penggunaan lahan dan hanya menghitung warna panel surya"},
      {"id": "d", "text": "Karena emisi karbon hanya muncul saat kabel listrik diputus"}
    ]'::jsonb,
    'Menurut IPCC AR6 WGIII (2022), pendekatan Life-Cycle Assessment (LCA) menilai jejak lingkungan pembangkit dari hulu ke hilir (ekstraksi mineral, pembuatan komponen, konstruksi, operasi, hingga daur ulang/dekomisioning) sehingga perbandingan antar-teknologi menjadi objektif.',
    1
  ),
  (
    '22222222-2222-4222-8222-222222222602',
    '11111111-1111-4111-8111-111111111106',
    'Mengapa pengembangan PLTS Terapung (Floating Solar PV) di atas waduk PLTA seperti di Waduk Cirata menjadi salah satu solusi trade-off lahan di Indonesia?',
    '[
      {"id": "a", "text": "Karena modul surya hanya dapat menghasilkan arus listrik jika direndam di dasar sungai"},
      {"id": "b", "text": "Mengurangi tekanan alih fungsi lahan daratan produktif dan memanfaatkan gardu/transmisi PLTA yang sudah ada, dengan tetap memantau kualitas ekosistem perairan waduk"},
      {"id": "c", "text": "Menggantikan fungsi turbin air secara permanen agar bendungan dikeringkan"},
      {"id": "d", "text": "Menghilangkan sifat intermiten matahari sehingga PLTS beroperasi penuh di tengah malam tanpa baterai"}
    ]'::jsonb,
    'PLTS skala utilitas membutuhkan ruang permukaan yang luas. Pemanfaatan sebagian kecil permukaan waduk eksisting mengurangi pembebasan lahan darat dan memungkinkan berbagi jaringan transmisi, meskipun cakupan tutupannya tetap diatur agar oksigen terlarut dan biota air terjaga.',
    2
  ),
  (
    '22222222-2222-4222-8222-222222222603',
    '11111111-1111-4111-8111-111111111106',
    'Apa perbedaan dampak ruang dan hidrologi antara PLTA sistem waduk (reservoir) dengan PLTMH / PLTA tipe aliran langsung (run-of-river)?',
    '[
      {"id": "a", "text": "PLTA waduk umumnya membutuhkan area genangan tampungan air yang luas namun alirannya fleksibel diatur, sedangkan run-of-river memiliki jejak genangan jauh lebih kecil tetapi bergantung pada debit alami sungai"},
      {"id": "b", "text": "PLTA run-of-river membutuhkan bendungan raksasa yang menenggelamkan lembah, sedangkan PLTA waduk tidak menggunakan air"},
      {"id": "c", "text": "Keduanya menggunakan pembakaran batu bara untuk memanaskan air sungai"},
      {"id": "d", "text": "PLTA waduk hanya dapat beroperasi saat siang hari"}
    ]'::jsonb,
    'Karakteristik pembangkit air tidak boleh digeneralisasi: PLTA waduk menyimpan cadangan air besar untuk menopang beban puncak namun mengubah lanskap sungai, sementara tipe run-of-river mengalihkan sebagian aliran sungai melalui saluran/pipa pesat dengan genangan minimal.',
    3
  ),
  (
    '22222222-2222-4222-8222-222222222604',
    '11111111-1111-4111-8111-111111111106',
    'Pembangkit Listrik Tenaga Panas Bumi (PLTP) unggul sebagai penyuplai beban dasar (baseload) 24 jam dengan jejak tapak permukaan yang relatif ringkas. Namun, tantangan lingkungan apa yang wajib dikelola secara ketat?',
    '[
      {"id": "a", "text": "Ketergantungan pada kecepatan angin muson pantai setiap sore"},
      {"id": "b", "text": "Perlindungan keanekaragaman hayati di kawasan hutan pegunungan vulkanik, pengendalian gas tidak terkondensasi (seperti H2S), dan kewajiban reinjeksi fluida ke reservoar"},
      {"id": "c", "text": "Kebutuhan impor bahan bakar solar setiap minggu untuk memutar turbin uap"},
      {"id": "d", "text": "Limbah sekam padi yang menumpuk di sekitar sumur produksi"}
    ]'::jsonb,
    'Prospek panas bumi di Indonesia berada di sabuk gunung api yang kerap beririsan dengan kawasan hutan konservasi/lindung, sehingga pembangunannya menuntut pengelolaan pembukaan tapak minimal, pemantauan gas H2S, dan reinjeksi brine secara tertutup.',
    4
  ),
  (
    '22222222-2222-4222-8222-222222222605',
    '11111111-1111-4111-8111-111111111106',
    'Dalam pemanfaatan Bioenergi (PLTBm dan PLTBg), syarat utama apakah yang menentukan agar pembangkit tersebut benar-benar memberikan manfaat lingkungan yang berkelanjutan?',
    '[
      {"id": "a", "text": "Membuka hutan alam primer secara masif khusus untuk diambil kayunya sekali pakai"},
      {"id": "b", "text": "Membuang limbah cair POME langsung ke sungai tanpa reaktor anaerobik"},
      {"id": "c", "text": "Menggunakan residu pertanian/perkebunan atau limbah organik terkelola tanpa memicu deforestasi, disertai pengendalian emisi partikulat pembakaran dan penangkapan metana"},
      {"id": "d", "text": "Mengganti seluruh bahan baku biomassa dengan batu bara kalori rendah"}
    ]'::jsonb,
    'Menurut IPCC AR6 WGIII, manfaat reduksi emisi bioenergi sangat bergantung pada tata kelola rantai pasok bahan baku: pemanfaatan limbah agroindustri (cangkang sawit, sekam, POME) mendukung ekonomi sirkular, sedangkan alih fungsi hutan primer justru meningkatkan utang karbon.',
    5
  ),
  (
    '22222222-2222-4222-8222-222222222606',
    '11111111-1111-4111-8111-111111111106',
    'Mengapa kita tidak dapat menghitung angka penghematan ton CO2 tahunan suatu pembangkit hanya dengan mengalikan kapasitas terpasang (MW) secara sembarangan?',
    '[
      {"id": "a", "text": "Karena kapasitas terpasang (MW) adalah batas daya maksimum nominal, sedangkan reduksi emisi aktual bergantung pada produksi energi tahunan (MWh), faktor kapasitas (capacity factor), dan faktor emisi jaringan listrik setempat"},
      {"id": "b", "text": "Karena satuan Megawatt (MW) adalah satuan berat gas karbon dioksida"},
      {"id": "c", "text": "Karena semua pembangkit di dunia menghasilkan jumlah listrik yang persis sama setiap jam"},
      {"id": "d", "text": "Karena pembangkit listrik tidak pernah terhubung ke jaringan transmisi"}
    ]'::jsonb,
    'Kapasitas terpasang (MW) menunjukkan daya maksimum rancangan, bukan energi yang dihasilkan sepanjang tahun (MWh). Dua pembangkit berkapasitas 50 MW dari kategori berbeda (misalnya PLTS vs PLTP) menghasilkan MWh tahunan yang sangat berbeda karena perbedaan capacity factor.',
    6
  )
on conflict (id) do update set
  quiz_id = excluded.quiz_id,
  question = excluded.question,
  options = excluded.options,
  explanation = excluded.explanation,
  sort_order = excluded.sort_order;

insert into public.quiz_answer_keys (question_id, correct_option_id)
values
  ('22222222-2222-4222-8222-222222222601', 'a'),
  ('22222222-2222-4222-8222-222222222602', 'b'),
  ('22222222-2222-4222-8222-222222222603', 'a'),
  ('22222222-2222-4222-8222-222222222604', 'b'),
  ('22222222-2222-4222-8222-222222222605', 'c'),
  ('22222222-2222-4222-8222-222222222606', 'a')
on conflict (question_id) do update set
  correct_option_id = excluded.correct_option_id;


