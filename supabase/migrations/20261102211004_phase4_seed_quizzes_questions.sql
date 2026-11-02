-- ============================================================================
-- Fase 4 (4/5): Seed Kuis & Soal Konsep Dasar (TANPA Kunci Jawaban)
-- ============================================================================
-- PENTING: Judul kuis diawali "[DRAF]", seluruh soal hanya memuat prinsip fisika
-- dan konsep dasar energi terbarukan tanpa angka/statistik tanpa sumber.
-- Tabel quiz_questions TIDAK menyimpan kunci jawaban.

-- 1. Seed 2 Kuis Konsep Dasar
insert into public.quizzes (
  id,
  category_id,
  title,
  description,
  difficulty,
  time_limit_seconds,
  is_published
)
values
  (
    '11111111-1111-4111-8111-111111111101',
    null,
    '[DRAF] Dasar-Dasar Energi Terbarukan',
    '[DRAF - Perlu Review] Uji pemahaman konsep fundamental tentang cara kerja PLTS, PLTA, PLTB, PLTP, dan Bioenergi.',
    'beginner',
    180,
    true
  ),
  (
    '11111111-1111-4111-8111-111111111102',
    (select id from public.energy_categories where slug = 'solar'),
    '[DRAF] Prinsip Kerja Surya & Panas Bumi',
    '[DRAF - Perlu Review] Kuis singkat tanpa batas waktu mengenai karakteristik operasional pembangkit surya dan panas bumi.',
    'intermediate',
    null,
    true
  )
on conflict (id) do update set
  category_id = excluded.category_id,
  title = excluded.title,
  description = excluded.description,
  difficulty = excluded.difficulty,
  time_limit_seconds = excluded.time_limit_seconds,
  is_published = excluded.is_published,
  updated_at = now();

-- 2. Seed 5 Soal untuk Kuis 1 ([DRAF] Dasar-Dasar Energi Terbarukan)
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
    '22222222-2222-4222-8222-222222222101',
    '11111111-1111-4111-8111-111111111101',
    'Fenomena fisika apa yang dimanfaatkan oleh sel surya pada PLTS untuk mengubah cahaya matahari secara langsung menjadi listrik?',
    '[
      {"id": "a", "text": "Efek fotovoltaik pada material semikonduktor"},
      {"id": "b", "text": "Pembakaran termokimia biomassa padat"},
      {"id": "c", "text": "Fermentasi anaerobik mikroorganisme"},
      {"id": "d", "text": "Tekanan hidrostatik air pada pipa pesat"}
    ]'::jsonb,
    'Sel surya (solar cell) bekerja menggunakan efek fotovoltaik, di mana foton cahaya matahari melepaskan elektron pada semikonduktor sehingga menghasilkan arus listrik searah (DC).',
    1
  ),
  (
    '22222222-2222-4222-8222-222222222102',
    '11111111-1111-4111-8111-111111111101',
    'Komponen apakah pada sistem PLTS yang berfungsi mengubah arus listrik searah (DC) dari panel surya menjadi arus bolak-balik (AC)?',
    '[
      {"id": "a", "text": "Penstock (pipa pesat)"},
      {"id": "b", "text": "Inverter"},
      {"id": "c", "text": "Kondensor uap"},
      {"id": "d", "text": "Anaerobic digester"}
    ]'::jsonb,
    'Panel surya menghasilkan arus searah (DC), sedangkan sebagian besar peralatan listrik dan jaringan listrik menggunakan arus bolak-balik (AC). Inverter bertugas melakukan konversi DC ke AC tersebut.',
    2
  ),
  (
    '22222222-2222-4222-8222-222222222103',
    '11111111-1111-4111-8111-111111111101',
    'Pada Pembangkit Listrik Tenaga Air (PLTA), bagaimana urutan konversi energi utama yang terjadi?',
    '[
      {"id": "a", "text": "Energi radiasi cahaya -> energi kimia -> energi listrik"},
      {"id": "b", "text": "Energi potensial/kinetik air -> energi mekanik turbin -> energi listrik generator"},
      {"id": "c", "text": "Energi panas perut bumi -> energi foton -> energi listrik"},
      {"id": "d", "text": "Energi angin -> energi biogas -> energi listrik"}
    ]'::jsonb,
    'Aliran atau terjunan air memiliki energi potensial dan kinetik yang memutar sudu turbin (energi mekanik), lalu poros turbin memutar generator untuk menghasilkan energi listrik.',
    3
  ),
  (
    '22222222-2222-4222-8222-222222222104',
    '11111111-1111-4111-8111-111111111101',
    'Mengapa Pembangkit Listrik Tenaga Panas Bumi (PLTP) sering dikategorikan sebagai pembangkit beban dasar (baseload)?',
    '[
      {"id": "a", "text": "Karena hanya dapat menghasilkan listrik saat matahari bersinar terik"},
      {"id": "b", "text": "Karena sumber panas bumi tersedia kontinu tanpa bergantung pada cuaca harian maupun siang-malam"},
      {"id": "c", "text": "Karena turbinnya digerakkan oleh hembusan angin pesisir"},
      {"id": "d", "text": "Karena tidak menggunakan turbin maupun generator"}
    ]'::jsonb,
    'Berbeda dengan energi surya dan angin yang bersifat intermiten terhadap cuaca, panas dari reservoir bumi bersifat stabil sepanjang hari sehingga cocok memikul beban dasar jaringan listrik.',
    4
  ),
  (
    '22222222-2222-4222-8222-222222222105',
    '11111111-1111-4111-8111-111111111101',
    'Apa perbedaan utama antara jalur PLTBm (Biomassa) dan PLTBg (Biogas) dalam menghasilkan energi?',
    '[
      {"id": "a", "text": "PLTBm memanfaatkan bahan organik padat (mis. pembakaran/gasifikasi), sedangkan PLTBg memanfaatkan gas hasil penguraian anaerobik bahan organik"},
      {"id": "b", "text": "PLTBm menggunakan panel silikon, sedangkan PLTBg menggunakan kincir angin"},
      {"id": "c", "text": "PLTBm hanya bekerja di laut, sedangkan PLTBg di gunung berapi"},
      {"id": "d", "text": "Keduanya sama sekali tidak menggunakan bahan organik"}
    ]'::jsonb,
    'PLTBm mengolah biomassa padat (seperti residu pertanian/perkebunan) secara termokimia, sementara PLTBg mengolah limbah organik dalam reaktor kedap udara (anaerobic digester) menjadi gas metana.',
    5
  )
on conflict (id) do update set
  quiz_id = excluded.quiz_id,
  question = excluded.question,
  options = excluded.options,
  explanation = excluded.explanation,
  sort_order = excluded.sort_order;

-- 3. Seed 5 Soal untuk Kuis 2 ([DRAF] Prinsip Kerja Surya & Panas Bumi)
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
    '22222222-2222-4222-8222-222222222201',
    '11111111-1111-4111-8111-111111111102',
    'Apa yang dimaksud dengan sifat intermiten pada pembangkit energi surya (PLTS) dan angin (PLTB)?',
    '[
      {"id": "a", "text": "Output daya listrik berfluktuasi mengikuti ketersediaan sinar matahari atau kecepatan angin"},
      {"id": "b", "text": "Pembangkit dapat memproduksi listrik tanpa batas melebihi kapasitas terpasang"},
      {"id": "c", "text": "Pembangkit membutuhkan bahan bakar batu bara sebagai pemicu utama"},
      {"id": "d", "text": "Sistem tidak memerlukan jaringan kabel listrik"}
    ]'::jsonb,
    'Intermiten berarti pasokan energi tidak konstan sepanjang waktu karena bergantung pada kondisi alam seperti tutupan awan, pergantian siang-malam, atau perubahan hembusan angin.',
    1
  ),
  (
    '22222222-2222-4222-8222-222222222202',
    '11111111-1111-4111-8111-111111111102',
    'Mengapa pada operasional PLTP dilakukan proses injeksi kembali (reinjection) fluida yang telah dikondensasikan ke dalam sumur injeksi?',
    '[
      {"id": "a", "text": "Untuk menjaga tekanan dan keberlanjutan fluida di dalam reservoir panas bumi"},
      {"id": "b", "text": "Untuk mendinginkan panel fotovoltaik di permukaan"},
      {"id": "c", "text": "Untuk meningkatkan kecepatan angin di sekitar menara"},
      {"id": "d", "text": "Untuk menghasilkan biji silikon baru"}
    ]'::jsonb,
    'Fluida panas bumi yang telah diambil panasnya dan dikondensasikan diinjeksikan kembali ke reservoir bawah permukaan agar tekanan dan cadangan fluida panas bumi tetap terjaga secara berkelanjutan.',
    2
  ),
  (
    '22222222-2222-4222-8222-222222222203',
    '11111111-1111-4111-8111-111111111102',
    'Solusi teknis apa yang umum dipadukan dengan PLTS agar energi listrik yang dihasilkan pada siang hari dapat digunakan pada malam hari?',
    '[
      {"id": "a", "text": "Sistem penyimpanan energi baterai (Battery Energy Storage System)"},
      {"id": "b", "text": "Penambahan kaca pembesar di malam hari"},
      {"id": "c", "text": "Pelepasan uap ke atmosfer"},
      {"id": "d", "text": "Penghentian fungsi inverter secara permanen"}
    ]'::jsonb,
    'Sistem penyimpanan energi seperti baterai menyimpan kelebihan energi listrik yang diproduksi panel surya pada siang hari untuk disalurkan kembali saat matahari telah terbenam.',
    3
  ),
  (
    '22222222-2222-4222-8222-222222222204',
    '11111111-1111-4111-8111-111111111102',
    'Bagaimana cara kerja sistem siklus biner (binary cycle) pada pembangkit panas bumi?',
    '[
      {"id": "a", "text": "Fluida panas bumi memanaskan fluida kerja sekunder bertitik didih lebih rendah melalui penukar panas untuk memutar turbin"},
      {"id": "b", "text": "Menggunakan dua bilah kincir angin pada satu menara"},
      {"id": "c", "text": "Menggabungkan dua bendungan sungai menjadi satu"},
      {"id": "d", "text": "Membakar biomassa di dalam sumur produksi"}
    ]'::jsonb,
    'Pada sistem siklus biner, fluida panas bumi tidak langsung memutar turbin, melainkan melewati penukar panas (heat exchanger) untuk menguapkan fluida sekunder dalam siklus tertutup.',
    4
  ),
  (
    '22222222-2222-4222-8222-222222222205',
    '11111111-1111-4111-8111-111111111102',
    'Manakah dari pernyataan berikut yang merupakan salah satu tantangan utama pengembangan proyek PLTP pada tahap awal?',
    '[
      {"id": "a", "text": "Ketidakpastian dan biaya teknis pada tahap eksplorasi geosains serta pengeboran sumur awal"},
      {"id": "b", "text": "Ketergantungan penuh pada cahaya matahari siang hari"},
      {"id": "c", "text": "Kebutuhan pasokan sekam padi setiap hari"},
      {"id": "d", "text": "Hanya dapat beroperasi ketika musim hujan"}
    ]'::jsonb,
    'Tahap awal pengembangan panas bumi memerlukan survei geosains mendalam dan pengeboran eksplorasi untuk memastikan ketersediaan suhu serta permeabilitas reservoir di bawah permukaan bumi.',
    5
  )
on conflict (id) do update set
  quiz_id = excluded.quiz_id,
  question = excluded.question,
  options = excluded.options,
  explanation = excluded.explanation,
  sort_order = excluded.sort_order;
