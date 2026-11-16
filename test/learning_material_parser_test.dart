import 'package:eduearth/features/learning/domain/learning_material_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LearningMaterialParser', () {
    test(
      'parses Solar-style module with key takeaway, 4 chapters, table, segmented innovation tabs, Pro/Con, and clickable references',
      () {
        const solarMd = '''
> **Intisari Konsep:** Modul surya mengubah foton cahaya matahari langsung menjadi listrik DC via efek fotovoltaik, lalu dikonversi ke AC oleh inverter.

Indonesia terletak di garis khatulistiwa sehingga memiliki paparan radiasi matahari konsisten sepanjang tahun.

## 1. Prinsip Kerja Efek Fotovoltaik
Semikonduktor silikon P-N melepaskan elektron ketika terkena foton sinar matahari.

## 2. Komponen Utama & Contoh Penerapan
| Komponen | Peran Utama |
|---|---|
| **Panel Surya** | Menangkap foton menjadi arus searah (DC). |
| **Inverter** | Mengubah arus DC ke AC 50 Hz. |
| **Mounting** | Menopang orientasi modul sesuai sudut optimal. |
| **Proteksi DC/AC** | Melindungi sistem dari lonjakan arus. |

Inovasi penerapan PLTS modern:
- **PLTS Terapung:** Dipasang di waduk untuk menjaga suhu sel tetap dingin sekaligus menekan penguapan air.
- **Agrivoltaik:** Memadukan panel surya tinggi dengan budidaya tanaman di bawah naungan parsial.

## 3. Kelebihan, Tantangan, & Mitigasi
- **Kelebihan:** Emisi operasional mendekati nol dan instalasi sangat modular dari atap rumah hingga skala utilitas.
- **Tantangan & Mitigasi:** Produksi bergantung pada cuaca (intermiten); dimitigasi melalui integrasi baterai BESS atau PLTA waduk.

Catatan tambahan pasca evaluasi teknis tetap dipertahankan.

## 4. Peran Strategis di Indonesia
PLTS Waduk Cirata 145 MWac menjadi tonggak penting bauran EBT nasional.

### Referensi Pembelajaran
- [RUPTL PLN — Energi Terbarukan](https://web.pln.co.id)
- [IRENA — Solar Energy Data](https://www.irena.org)
''';

        final parsed = LearningMaterialParser.parse(solarMd);

        expect(
          parsed.keyTakeaway,
          contains('efek fotovoltaik'),
        );
        expect(
          parsed.introMd,
          contains('garis khatulistiwa'),
        );
        expect(parsed.chapters, hasLength(4));

        // Bagian 1: prose + short nav label
        expect(parsed.chapters[0].numberLabel, 'BAGIAN 1');
        expect(parsed.chapters[0].navLabel, isNotEmpty);
        expect(parsed.chapters[0].leadMd, contains('Semikonduktor silikon'));

        // Chapter 2: 2-column 4-row table + 2 innovation tabs
        final ch2 = parsed.chapters[1];
        expect(ch2.table, isNotNull);
        expect(ch2.table!.headers, ['Komponen', 'Peran Utama']);
        expect(ch2.table!.rows, hasLength(4));
        expect(ch2.table!.rows.first.first, 'Panel Surya');
        expect(ch2.segmentedTabs, hasLength(2));
        expect(ch2.segmentedTabs[0].label, contains('PLTS Terapung'));
        expect(ch2.segmentedTabs[1].label, contains('Agrivoltaik'));

        // Chapter 3: Pro/Con split + extra trailing note preserved
        final ch3 = parsed.chapters[2];
        expect(ch3.proConPair, isNotNull);
        expect(ch3.proConPair!.proBodyMd, contains('modular'));
        expect(ch3.proConPair!.conBodyMd, contains('intermiten'));
        expect(ch3.proConPair!.extraMd, contains('Catatan tambahan'));

        // Chapter 4: normal prose without trailing references leaking into body
        expect(parsed.chapters[3].rawBodyMd, isNot(contains('RUPTL PLN')));

        // References extracted separately
        expect(parsed.referencesHeading, 'Referensi Pembelajaran');
        expect(parsed.references, hasLength(2));
        expect(parsed.references[0].isLink, isTrue);
        expect(parsed.references[0].label, contains('RUPTL PLN'));
        expect(parsed.references[0].url, 'https://web.pln.co.id');
      },
    );

    test(
      'parses Bioenergi / BESS / Smart Grid A & B subsections into segmentedTabs',
      () {
        const bessMd = '''
> **Intisari Konsep:** Penyimpanan energi menjembatani selisih waktu antara puncak produksi EBT dan beban malam.

## 1. Perbandingan Teknologi Penyimpanan
### A. Battery Energy Storage System (BESS)
Baterai elektrokimia LiFePO4 merespons fluktuasi frekuensi dalam hitungan milidetik.
- Cocok untuk integrasi cepat di gardu induk PLTS.

### B. PLTA Pumped Storage
Memompa air ke waduk atas saat listrik surplus dan melepaskannya lewat turbin saat beban puncak.
- Kapasitas energi skala gigawatt-jam untuk durasi panjang.
''';

        final parsed = LearningMaterialParser.parse(bessMd);

        expect(parsed.chapters, hasLength(1));
        final ch1 = parsed.chapters.first;
        expect(ch1.segmentedTabs, hasLength(2));
        expect(ch1.segmentedTabs[0].label, 'BESS (Battery)');
        expect(
          ch1.segmentedTabs[0].bodyMd,
          contains('Battery Energy Storage System'),
        );
        expect(ch1.segmentedTabs[0].bodyMd, contains('LiFePO4'));
        expect(ch1.segmentedTabs[1].label, contains('Pumped Storage'));
        expect(ch1.segmentedTabs[1].bodyMd, contains('gigawatt-jam'));
      },
    );

    test(
      'parses Module 9 Transisi Energi 3-column table, post-table blockquote, and non-URL academic references',
      () {
        const mod9Md = '''
> **Intisari Konsep:** Penilaian transisi energi memerlukan Analisis Siklus Hidup (LCA) agar dampak lahan, material, dan limbah ikut terkelola.

## 1. Perbandingan Dampak Lingkungan (*Trade-Off*) 5 EBT Utama
| Jenis EBT | Peran Sistem | Keunggulan & Tantangan Ekologis |
|---|---|---|
| **Surya (PLTS)** | VRE Siang | Nol emisi operasi, namun butuh tata kelola daur ulang panel. |
| **Air (PLTA)** | Penyeimbang | Fleksibel, tetapi waduk besar memengaruhi ekosistem sungai. |
| **Angin (PLTB)** | VRE Musiman | Jejak lahan bawah masih produktif, perlu mitigasi jalur burung. |
| **Panas Bumi (PLTP)** | Baseload 24 Jam | Andal tanpa cuaca, wajib disiplin reinjeksi brine. |
| **Bioenergi (PLTBm)** | Terkendali | Ekonomi sirkular limbah, wajib kendalikan emisi partikulat. |

> **Catatan LCA:** Evaluasi dampak selalu mencakup fase hulu hingga pasca-operasi.

### Referensi
- IPCC Fifth Assessment Report — Life-Cycle Emissions of Electricity Supply Technologies.
- IRENA (2024) — * Renewable Power Generation Costs & Energy Transition Outlook*.
''';

        final parsed = LearningMaterialParser.parse(mod9Md);

        expect(parsed.chapters, hasLength(1));
        final ch1 = parsed.chapters.first;
        expect(ch1.title, isNot(contains('*')));
        expect(ch1.title, contains('(Trade-Off)'));
        expect(ch1.table, isNotNull);
        expect(ch1.table!.headers, hasLength(3));
        expect(ch1.table!.rows, hasLength(5));
        expect(ch1.afterTableMd, contains('Catatan LCA'));

        expect(parsed.referencesHeading, 'Referensi');
        expect(parsed.references, hasLength(2));
        expect(parsed.references[0].isLink, isFalse);
        expect(parsed.references[0].url, isNull);
        expect(parsed.references[0].label, contains('IPCC'));
        expect(parsed.references[1].label, isNot(contains('*')));
      },
    );

    test(
      'handles plain or draft markdown gracefully without chapter headings',
      () {
        const draftMd =
            'Ini adalah draf ringkas mengenai efisiensi turbin air mikrohidro tanpa heading bagian.';

        final parsed = LearningMaterialParser.parse(draftMd);

        expect(parsed.keyTakeaway, isNull);
        expect(parsed.introMd, draftMd);
        expect(parsed.chapters, isEmpty);
        expect(parsed.references, isEmpty);
      },
    );
  });
}
