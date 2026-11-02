// DEMO DATA — bukan data nyata.
// Hanya digunakan sebagai fallback lokal apabila aplikasi dijalankan tanpa
// kredensial Supabase (--dart-define). Seluruh data pembangkit di sini jelas
// fiktif, diawali "[DEMO]", dan memiliki isDemo = true sesuai docs/06_CODING_STANDARDS.md.

import '../../models/energy_category.dart';
import '../../models/power_plant.dart';

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
}

