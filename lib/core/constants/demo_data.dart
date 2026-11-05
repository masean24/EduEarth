// DEMO DATA — bukan data nyata.
// Hanya digunakan sebagai fallback lokal apabila aplikasi dijalankan tanpa
// kredensial Supabase (AppConfig.isSupabaseConfigured == false).
// PENTING: Sesuai aturan keamanan Fase 4, file ini TIDAK menyimpan kunci jawaban kuis.

import '../../models/achievement.dart';
import '../../models/app_notification.dart';
import '../../models/energy_category.dart';
import '../../models/learning_material.dart';
import '../../models/power_plant.dart';
import '../../models/quiz.dart';
import '../../models/quiz_question.dart';

class DemoData {
  const DemoData._();

  static const Map<String, Map<String, dynamic>> comparisonBySlug = {
    'solar': {
      'sumber_energi':
          'Radiasi cahaya matahari yang dikonversi melalui efek fotovoltaik pada sel surya',
      'karakter_pasokan':
          'Intermiten; berproduksi optimal pada siang hari dan bergantung pada cuaca serta tutupan awan',
      'faktor_kapasitas':
          'Relatif rendah hingga menengah karena siklus penyinaran harian matahari',
      'emisi_siklus_hidup':
          'Sangat rendah saat beroperasi; jejak emisi terutama berasal dari proses manufaktur modul surya',
      'kebutuhan_lahan':
          'Fleksibel; dapat memanfaatkan atap bangunan, lahan terbuka, maupun permukaan waduk (PLTS terapung)',
      'keunggulan_utama':
          'Bersifat modular, waktu pemasangan relatif cepat, serta pemeliharaan harian sederhana',
      'tantangan_utama':
          'Memerlukan penyimpan energi (baterai) atau penyeimbang jaringan saat malam dan cuaca mendung',
      'karakter_lokasi':
          'Daerah terbuka dengan paparan radiasi matahari konsisten dan minim bayangan penghalang',
    },
    'hydro': {
      'sumber_energi':
          'Energi potensial dan kinetik dari aliran sungai atau terjunan air waduk',
      'karakter_pasokan':
          'Stabil dan fleksibel; dapat dioperasikan untuk memikul beban dasar maupun beban puncak',
      'faktor_kapasitas':
          'Menengah hingga tinggi, mengikuti ketersediaan debit air sepanjang musim',
      'emisi_siklus_hidup':
          'Sangat rendah selama masa operasi pembangkitan listrik',
      'kebutuhan_lahan':
          'Luas untuk sistem bendungan berwaduk; relatif ringkas untuk sistem aliran sungai langsung (run-of-river)',
      'keunggulan_utama':
          'Umur teknis infrastruktur panjang dan mampu merespons perubahan beban jaringan dengan cepat',
      'tantangan_utama':
          'Kebutuhan investasi konstruksi sipil awal besar serta sensitif terhadap musim kemarau',
      'karakter_lokasi':
          'Wilayah dengan daerah aliran sungai berdebit stabil dan topografi berlembah atau berbukit',
    },
    'wind': {
      'sumber_energi':
          'Energi kinetik hembusan massa udara yang memutar bilah rotor turbin angin',
      'karakter_pasokan':
          'Variabel / intermiten; mengikuti fluktuasi kecepatan angin harian dan musiman',
      'faktor_kapasitas':
          'Menengah pada koridor angin yang memiliki hembusan konsisten',
      'emisi_siklus_hidup':
          'Sangat rendah; tidak menghasilkan emisi pembakaran selama turbin beroperasi',
      'kebutuhan_lahan':
          'Area di sekitar menara turbin masih dapat dimanfaatkan bersama untuk pertanian atau penggembalaan',
      'keunggulan_utama':
          'Tidak memerlukan air pendingin dan dapat membangkitkan listrik baik siang maupun malam hari',
      'tantangan_utama':
          'Terbatas pada wilayah dengan profil kecepatan angin yang memadai serta membutuhkan manajemen kestabilan frekuensi',
      'karakter_lokasi':
          'Kawasan pesisir, perbukitan terbuka, atau celah pegunungan dengan hembusan angin terarah',
    },
    'geothermal': {
      'sumber_energi':
          'Panas alami dan uap dari reservoar hidrotermal di dalam kerak bumi',
      'karakter_pasokan':
          'Beban dasar (baseload) yang beroperasi kontinu tanpa bergantung pada cuaca atau pergantian musim',
      'faktor_kapasitas':
          'Sangat tinggi dibandingkan pembangkit energi terbarukan berbasis cuaca',
      'emisi_siklus_hidup':
          'Rendah, terlebih dengan penerapan sistem reinjeksi fluida kembali ke dalam reservoar',
      'kebutuhan_lahan':
          'Kompak per satuan kapasitas pembangkitan dibandingkan energi surya atau bendungan air',
      'keunggulan_utama':
          'Keluaran daya sangat stabil sepanjang tahun sehingga andal sebagai penopang utama jaringan listrik',
      'tantangan_utama':
          'Risiko geologi pada tahap eksplorasi sumur awal serta waktu pengembangan proyek yang bertahap',
      'karakter_lokasi':
          'Kawasan sabuk vulkanik aktif yang memiliki manifestasi dan reservoar panas bumi',
    },
    'bioenergy': {
      'sumber_energi':
          'Bahan organik terbarukan seperti residu pertanian, perkebunan, limbah cair organik, atau biogas',
      'karakter_pasokan':
          'Dapat dikendalikan (dispatchable) selama rantai pasok bahan baku organik terjaga',
      'faktor_kapasitas':
          'Menengah hingga tinggi, bergantung pada kontinuitas suplai bahan baku biomassa atau biogas',
      'emisi_siklus_hidup':
          'Rendah dalam siklus karbon tertutup apabila memanfaatkan limbah organik secara berkelanjutan',
      'kebutuhan_lahan':
          'Umumnya terintegrasi dengan fasilitas pengolahan agroindustri atau instalasi pengolah limbah',
      'keunggulan_utama':
          'Membantu mengelola limbah organik dan mengurangi pelepasan gas metana sekaligus menghasilkan energi',
      'tantangan_utama':
          'Memerlukan pengelolaan logistik pengumpulan, penyimpanan, dan pengendalian kadar air bahan baku',
      'karakter_lokasi':
          'Sentra perkebunan, pertanian, atau fasilitas pengolahan produk agroindustri',
    },
  };

  static const List<EnergyCategory> categories = [
    EnergyCategory(
      id: 'demo-cat-solar',
      slug: 'solar',
      name: 'Solar Energy',
      shortCode: 'PLTS',
      description:
          'Energi surya memanfaatkan radiasi matahari melalui sel fotovoltaik untuk menghasilkan listrik bersih.',
      icon: 'wb_sunny_rounded',
      colorHex: '#FACC15',
      comparison: {
        'sumber_energi':
            'Radiasi cahaya matahari yang dikonversi melalui efek fotovoltaik pada sel surya',
        'karakter_pasokan':
            'Intermiten; berproduksi optimal pada siang hari dan bergantung pada cuaca serta tutupan awan',
        'faktor_kapasitas':
            'Relatif rendah hingga menengah karena siklus penyinaran harian matahari',
        'emisi_siklus_hidup':
            'Sangat rendah saat beroperasi; jejak emisi terutama berasal dari proses manufaktur modul surya',
        'kebutuhan_lahan':
            'Fleksibel; dapat memanfaatkan atap bangunan, lahan terbuka, maupun permukaan waduk (PLTS terapung)',
        'keunggulan_utama':
            'Bersifat modular, waktu pemasangan relatif cepat, serta pemeliharaan harian sederhana',
        'tantangan_utama':
            'Memerlukan penyimpan energi (baterai) atau penyeimbang jaringan saat malam dan cuaca mendung',
        'karakter_lokasi':
            'Daerah terbuka dengan paparan radiasi matahari konsisten dan minim bayangan penghalang',
      },
      sortOrder: 1,
    ),
    EnergyCategory(
      id: 'demo-cat-hydro',
      slug: 'hydro',
      name: 'Hydropower',
      shortCode: 'PLTA',
      description:
          'Energi air memanfaatkan aliran sungai atau terjunan air waduk untuk memutar turbin pembangkit.',
      icon: 'water_drop_rounded',
      colorHex: '#38A6C8',
      comparison: {
        'sumber_energi':
            'Energi potensial dan kinetik dari aliran sungai atau terjunan air waduk',
        'karakter_pasokan':
            'Stabil dan fleksibel; dapat dioperasikan untuk memikul beban dasar maupun beban puncak',
        'faktor_kapasitas':
            'Menengah hingga tinggi, mengikuti ketersediaan debit air sepanjang musim',
        'emisi_siklus_hidup':
            'Sangat rendah selama masa operasi pembangkitan listrik',
        'kebutuhan_lahan':
            'Luas untuk sistem bendungan berwaduk; relatif ringkas untuk sistem aliran sungai langsung (run-of-river)',
        'keunggulan_utama':
            'Umur teknis infrastruktur panjang dan mampu merespons perubahan beban jaringan dengan cepat',
        'tantangan_utama':
            'Kebutuhan investasi konstruksi sipil awal besar serta sensitif terhadap musim kemarau',
        'karakter_lokasi':
            'Wilayah dengan daerah aliran sungai berdebit stabil dan topografi berlembah atau berbukit',
      },
      sortOrder: 2,
    ),
    EnergyCategory(
      id: 'demo-cat-wind',
      slug: 'wind',
      name: 'Wind Energy',
      shortCode: 'PLTB',
      description:
          'Energi angin mengubah energi kinetik hembusan angin menjadi energi listrik melalui bilah turbin.',
      icon: 'air_rounded',
      colorHex: '#0EA5E9',
      comparison: {
        'sumber_energi':
            'Energi kinetik hembusan massa udara yang memutar bilah rotor turbin angin',
        'karakter_pasokan':
            'Variabel / intermiten; mengikuti fluktuasi kecepatan angin harian dan musiman',
        'faktor_kapasitas':
            'Menengah pada koridor angin yang memiliki hembusan konsisten',
        'emisi_siklus_hidup':
            'Sangat rendah; tidak menghasilkan emisi pembakaran selama turbin beroperasi',
        'kebutuhan_lahan':
            'Area di sekitar menara turbin masih dapat dimanfaatkan bersama untuk pertanian atau penggembalaan',
        'keunggulan_utama':
            'Tidak memerlukan air pendingin dan dapat membangkitkan listrik baik siang maupun malam hari',
        'tantangan_utama':
            'Terbatas pada wilayah dengan profil kecepatan angin yang memadai serta membutuhkan manajemen kestabilan frekuensi',
        'karakter_lokasi':
            'Kawasan pesisir, perbukitan terbuka, atau celah pegunungan dengan hembusan angin terarah',
      },
      sortOrder: 3,
    ),
    EnergyCategory(
      id: 'demo-cat-geothermal',
      slug: 'geothermal',
      name: 'Geothermal Energy',
      shortCode: 'PLTP',
      description:
          'Energi panas bumi memanfaatkan uap dan panas alami dari perut bumi sebagai pembangkit beban dasar.',
      icon: 'thermostat_rounded',
      colorHex: '#F97316',
      comparison: {
        'sumber_energi':
            'Panas alami dan uap dari reservoar hidrotermal di dalam kerak bumi',
        'karakter_pasokan':
            'Beban dasar (baseload) yang beroperasi kontinu tanpa bergantung pada cuaca atau pergantian musim',
        'faktor_kapasitas':
            'Sangat tinggi dibandingkan pembangkit energi terbarukan berbasis cuaca',
        'emisi_siklus_hidup':
            'Rendah, terlebih dengan penerapan sistem reinjeksi fluida kembali ke dalam reservoar',
        'kebutuhan_lahan':
            'Kompak per satuan kapasitas pembangkitan dibandingkan energi surya atau bendungan air',
        'keunggulan_utama':
            'Keluaran daya sangat stabil sepanjang tahun sehingga andal sebagai penopang utama jaringan listrik',
        'tantangan_utama':
            'Risiko geologi pada tahap eksplorasi sumur awal serta waktu pengembangan proyek yang bertahap',
        'karakter_lokasi':
            'Kawasan sabuk vulkanik aktif yang memiliki manifestasi dan reservoar panas bumi',
      },
      sortOrder: 4,
    ),
    EnergyCategory(
      id: 'demo-cat-bioenergy',
      slug: 'bioenergy',
      name: 'Bioenergy',
      shortCode: 'PLTBm / PLTBg',
      description:
          'Bioenergi mengolah biomassa organik dan biogas menjadi energi listrik maupun bahan bakar bersih.',
      icon: 'eco_rounded',
      colorHex: '#22C55E',
      comparison: {
        'sumber_energi':
            'Bahan organik terbarukan seperti residu pertanian, perkebunan, limbah cair organik, atau biogas',
        'karakter_pasokan':
            'Dapat dikendalikan (dispatchable) selama rantai pasok bahan baku organik terjaga',
        'faktor_kapasitas':
            'Menengah hingga tinggi, bergantung pada kontinuitas suplai bahan baku biomassa atau biogas',
        'emisi_siklus_hidup':
            'Rendah dalam siklus karbon tertutup apabila memanfaatkan limbah organik secara berkelanjutan',
        'kebutuhan_lahan':
            'Umumnya terintegrasi dengan fasilitas pengolahan agroindustri atau instalasi pengolah limbah',
        'keunggulan_utama':
            'Membantu mengelola limbah organik dan mengurangi pelepasan gas metana sekaligus menghasilkan energi',
        'tantangan_utama':
            'Memerlukan pengelolaan logistik pengumpulan, penyimpanan, dan pengendalian kadar air bahan baku',
        'karakter_lokasi':
            'Sentra perkebunan, pertanian, atau fasilitas pengolahan produk agroindustri',
      },
      sortOrder: 5,
    ),
  ];

  // DEMO DATA — bukan data nyata
  static const List<PowerPlant> plants = [
    PowerPlant(
      id: 'demo-plant-1',
      categoryId: 'demo-cat-solar',
      categorySlug: 'solar',
      categoryName: 'Solar Energy',
      categoryShortCode: 'PLTS',
      name: '[DEMO] Titik Simulasi Energi Surya A',
      description:
          'Data simulasi fiktif untuk menguji tampilan marker dan kartu kategori Solar Energy (PLTS) pada peta pengembangan EduEarth.',
      province: 'Wilayah Simulasi Barat',
      city: 'Zona Uji 01',
      latitude: -2.0000,
      longitude: 105.0000,
      operationalStatus: 'unknown',
      isDemo: true,
      isPublished: true,
    ),
    PowerPlant(
      id: 'demo-plant-2',
      categoryId: 'demo-cat-hydro',
      categorySlug: 'hydro',
      categoryName: 'Hydropower',
      categoryShortCode: 'PLTA',
      name: '[DEMO] Titik Simulasi Energi Air B',
      description:
          'Data simulasi fiktif untuk menguji tampilan marker dan kartu kategori Hydropower (PLTA) pada peta pengembangan EduEarth.',
      province: 'Wilayah Simulasi Tengah',
      city: 'Zona Uji 02',
      latitude: -3.0000,
      longitude: 112.0000,
      operationalStatus: 'unknown',
      isDemo: true,
      isPublished: true,
    ),
    PowerPlant(
      id: 'demo-plant-3',
      categoryId: 'demo-cat-wind',
      categorySlug: 'wind',
      categoryName: 'Wind Energy',
      categoryShortCode: 'PLTB',
      name: '[DEMO] Titik Simulasi Energi Angin C',
      description:
          'Data simulasi fiktif untuk menguji tampilan marker dan kartu kategori Wind Energy (PLTB) pada peta pengembangan EduEarth.',
      province: 'Wilayah Simulasi Selatan',
      city: 'Zona Uji 03',
      latitude: -5.0000,
      longitude: 118.0000,
      operationalStatus: 'unknown',
      isDemo: true,
      isPublished: true,
    ),
    PowerPlant(
      id: 'demo-plant-4',
      categoryId: 'demo-cat-geothermal',
      categorySlug: 'geothermal',
      categoryName: 'Geothermal Energy',
      categoryShortCode: 'PLTP',
      name: '[DEMO] Titik Simulasi Panas Bumi D',
      description:
          'Data simulasi fiktif untuk menguji tampilan marker dan kartu kategori Geothermal Energy (PLTP) pada peta pengembangan EduEarth.',
      province: 'Wilayah Simulasi Tengah',
      city: 'Zona Uji 04',
      latitude: -7.0000,
      longitude: 110.0000,
      operationalStatus: 'unknown',
      isDemo: true,
      isPublished: true,
    ),
    PowerPlant(
      id: 'demo-plant-5',
      categoryId: 'demo-cat-bioenergy',
      categorySlug: 'bioenergy',
      categoryName: 'Bioenergy',
      categoryShortCode: 'PLTBm / PLTBg',
      name: '[DEMO] Titik Simulasi Bioenergi E',
      description:
          'Data simulasi fiktif untuk menguji tampilan marker dan kartu kategori Bioenergy (PLTBm/PLTBg) pada peta pengembangan EduEarth.',
      province: 'Wilayah Simulasi Timur',
      city: 'Zona Uji 05',
      latitude: -4.0000,
      longitude: 125.0000,
      operationalStatus: 'unknown',
      isDemo: true,
      isPublished: true,
    ),
  ];

  // DEMO DATA — materi konsep dasar draf untuk mode lokal tanpa Supabase
  static const List<LearningMaterial> materials = [
    LearningMaterial(
      id: 'demo-mat-solar',
      categoryId: 'demo-cat-solar',
      categorySlug: 'solar',
      categoryName: 'Energi Surya',
      categoryShortCode: 'PLTS',
      title: 'Konsep Dasar Pembangkit Listrik Tenaga Surya (PLTS)',
      slug: 'draf-konsep-dasar-plts',
      summary:
          'Pengenalan prinsip efek fotovoltaik, komponen utama sistem PLTS, serta kelebihan dan keterbatasan energi surya secara umum.',
      contentMd:
          '## Pengertian Umum\n\n**Pembangkit Listrik Tenaga Surya (PLTS)** mengubah radiasi cahaya matahari menjadi energi listrik melalui sel fotovoltaik.\n\n## Cara Kerja\n1. Penyerapan foton oleh semikonduktor.\n2. Timbul arus searah (DC).\n3. Konversi DC ke AC oleh inverter.',
      readMinutes: 4,
      difficulty: 'beginner',
      sortOrder: 1,
      isDraft: true,
    ),
    LearningMaterial(
      id: 'demo-mat-hydro',
      categoryId: 'demo-cat-hydro',
      categorySlug: 'hydro',
      categoryName: 'Energi Air',
      categoryShortCode: 'PLTA',
      title: 'Konsep Dasar Pembangkit Listrik Tenaga Air (PLTA)',
      slug: 'draf-konsep-dasar-plta',
      summary:
          'Penjelasan konversi energi potensial dan kinetik air menjadi energi mekanik turbin dan listrik.',
      contentMd:
          '## Pengertian Umum\n\n**Pembangkit Listrik Tenaga Air (PLTA)** memanfaatkan aliran atau terjunan air untuk memutar turbin dan generator listrik.',
      readMinutes: 5,
      difficulty: 'beginner',
      sortOrder: 1,
      isDraft: true,
    ),
  ];

  // DEMO DATA — daftar kuis & soal TANPA kunci jawaban
  static const List<Quiz> quizzes = [
    Quiz(
      id: '11111111-1111-4111-8111-111111111101',
      title: 'Dasar-Dasar Energi Terbarukan',
      description:
          'Uji pemahaman konsep fundamental tentang cara kerja PLTS, PLTA, PLTB, PLTP, dan Bioenergi.',
      difficulty: 'beginner',
      timeLimitSeconds: 180,
      isPublished: true,
      isDraft: true,
    ),
  ];

  static const List<QuizQuestion> quizQuestions = [
    QuizQuestion(
      id: '22222222-2222-4222-8222-222222222101',
      quizId: '11111111-1111-4111-8111-111111111101',
      question:
          'Fenomena fisika apa yang dimanfaatkan oleh sel surya pada PLTS untuk mengubah cahaya matahari secara langsung menjadi listrik?',
      options: [
        QuizOption(
          id: 'a',
          text: 'Efek fotovoltaik pada material semikonduktor',
        ),
        QuizOption(
          id: 'b',
          text: 'Pembakaran termokimia biomassa padat',
        ),
        QuizOption(
          id: 'c',
          text: 'Fermentasi anaerobik mikroorganisme',
        ),
        QuizOption(
          id: 'd',
          text: 'Tekanan hidrostatik air pada pipa pesat',
        ),
      ],
      explanation:
          'Sel surya bekerja menggunakan efek fotovoltaik pada material semikonduktor.',
      sortOrder: 1,
    ),
  ];

  static const List<Achievement> achievements = [
    Achievement(
      id: 'demo-ach-1',
      code: 'first_bookmark',
      title: 'Penjelajah Ingin Tahu',
      description:
          'Menyimpan materi pembelajaran atau pembangkit pertama ke Daftar Tersimpan.',
      icon: 'bookmark_added_rounded',
      points: 10,
      sortOrder: 1,
    ),
    Achievement(
      id: 'demo-ach-2',
      code: 'avid_learner',
      title: 'Pembelajar Energi Bersih',
      description:
          'Menyimpan minimal 2 materi pembelajaran energi terbarukan untuk dipelajari.',
      icon: 'menu_book_rounded',
      points: 20,
      sortOrder: 2,
    ),
    Achievement(
      id: 'demo-ach-3',
      code: 'library_guardian',
      title: 'Kolektor Pustaka Hijau',
      description:
          'Menyimpan minimal 5 materi pembelajaran energi terbarukan di Daftar Tersimpan.',
      icon: 'auto_stories_rounded',
      points: 35,
      sortOrder: 3,
    ),
    Achievement(
      id: 'demo-ach-4',
      code: 'plant_collector',
      title: 'Pemeta Nusantara',
      description:
          'Menyimpan minimal 2 lokasi pembangkit energi terbarukan di Indonesia.',
      icon: 'map_rounded',
      points: 20,
      sortOrder: 4,
    ),
    Achievement(
      id: 'demo-ach-5',
      code: 'grid_explorer',
      title: 'Penjelajah Jaringan EBT',
      description:
          'Menyimpan minimal 5 lokasi pembangkit energi terbarukan dari peta Nusantara.',
      icon: 'explore_rounded',
      points: 35,
      sortOrder: 5,
    ),
    Achievement(
      id: 'demo-ach-6',
      code: 'all_rounder_saver',
      title: 'Kolektor Seimbang',
      description:
          'Menyimpan setidaknya 1 materi pembelajaran sekaligus 1 lokasi pembangkit.',
      icon: 'stars_rounded',
      points: 25,
      sortOrder: 6,
    ),
    Achievement(
      id: 'demo-ach-7',
      code: 'first_quiz',
      title: 'Langkah Pertama Kuis',
      description:
          'Menyelesaikan percobaan kuis energi terbarukan pertama hingga tuntas.',
      icon: 'quiz_rounded',
      points: 15,
      sortOrder: 7,
    ),
    Achievement(
      id: 'demo-ach-8',
      code: 'quiz_enthusiast',
      title: 'Pejuang Kuis Tangguh',
      description:
          'Menyelesaikan minimal 3 percobaan kuis evaluasi di EduEarth.',
      icon: 'bolt_rounded',
      points: 30,
      sortOrder: 8,
    ),
    Achievement(
      id: 'demo-ach-9',
      code: 'multi_quiz_explorer',
      title: 'Penakluk Lintas Topik',
      description:
          'Menyelesaikan minimal 3 topik kuis yang berbeda di EduEarth.',
      icon: 'military_tech_rounded',
      points: 40,
      sortOrder: 9,
    ),
    Achievement(
      id: 'demo-ach-10',
      code: 'quiz_master',
      title: 'Juara Energi Terbarukan',
      description:
          'Meraih skor minimal 80 pada salah satu kuis evaluasi EduEarth.',
      icon: 'workspace_premium_rounded',
      points: 30,
      sortOrder: 10,
    ),
    Achievement(
      id: 'demo-ach-11',
      code: 'consistent_scholar',
      title: 'Cendekiawan Konsisten',
      description:
          'Meraih skor tinggi (minimal 80) sebanyak 3 kali atau lebih pada kuis EduEarth.',
      icon: 'school_rounded',
      points: 45,
      sortOrder: 11,
    ),
    Achievement(
      id: 'demo-ach-12',
      code: 'perfect_score',
      title: 'Master Skor Sempurna 100',
      description:
          'Menjawab seluruh pertanyaan dengan benar (skor 100) pada kuis EduEarth.',
      icon: 'emoji_events_rounded',
      points: 60,
      sortOrder: 12,
    ),
  ];

  // DEMO DATA — 1 pengumuman contoh untuk mode lokal tanpa Supabase
  static final List<AppNotification> notifications = [
    AppNotification(
      id: '00000000-0000-0000-0000-000000000601',
      title: '[CONTOH] Selamat Datang di Pusat Informasi EduEarth',
      body:
          'Ini adalah pengumuman contoh untuk menguji fitur Notification Center pada aplikasi EduEarth. Pengumuman resmi mengenai pembaruan materi dan peta pembangkit akan ditampilkan di halaman ini.',
      category: 'info',
      isPublished: true,
      createdAt: DateTime.utc(2026, 11, 3, 1, 0),
    ),
  ];
}
