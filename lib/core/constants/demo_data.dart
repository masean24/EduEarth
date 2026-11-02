// DEMO DATA — bukan data nyata.
// Hanya digunakan sebagai fallback lokal apabila aplikasi dijalankan tanpa
// kredensial Supabase (AppConfig.isSupabaseConfigured == false).
// PENTING: Sesuai aturan keamanan Fase 4, file ini TIDAK menyimpan kunci jawaban kuis.

import '../../models/energy_category.dart';
import '../../models/learning_material.dart';
import '../../models/power_plant.dart';
import '../../models/quiz.dart';
import '../../models/quiz_question.dart';

class DemoData {
  const DemoData._();

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
}
