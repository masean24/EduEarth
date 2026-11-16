import '../../../models/learning_material.dart';
import '../../../models/power_plant.dart';
import '../../../models/quiz.dart';

/// Hasil pemetaan kuis evaluasi yang direkomendasikan untuk suatu materi pembelajaran.
class QuizRecommendationResult {
  const QuizRecommendationResult({
    required this.isDirectTopicMatch,
    required this.buttonLabel,
    required this.cardTitle,
    required this.cardDescription,
    this.quiz,
  });

  /// Objek [Quiz] yang direkomendasikan apabila ditemukan kecocokan topik yang terverifikasi.
  /// Bernilai `null` apabila harus menggunakan fallback ke daftar kuis umum.
  final Quiz? quiz;

  /// Bernilai `true` hanya jika kuis benar-benar menguji topik materi tersebut.
  /// Bernilai `false` jika tidak ada kuis khusus untuk topik tersebut (fallback umum).
  final bool isDirectTopicMatch;

  /// Label tombol utama pada kartu evaluasi di bawah materi.
  final String buttonLabel;

  /// Judul kartu ajakan evaluasi.
  final String cardTitle;

  /// Penjelasan ringkas mengenai cakupan kuis atau alasan fallback.
  final String cardDescription;

  /// Alias untuk [cardDescription].
  String get reasonLabel => cardDescription;
}

/// Struktur konten edukatif kontekstual untuk halaman Detail Pembangkit (M1).
class PlantEducationalContext {
  const PlantEducationalContext({
    required this.capacityExplanation,
    required this.statusExplanation,
    required this.geographicSuitabilityTitle,
    required this.geographicSuitabilityBody,
    required this.operationalCharacteristicsBody,
    required this.designVariationNote,
    required this.environmentalBenefits,
    required this.environmentalChallenges,
    required this.referenceSources,
    this.plantSpecificHighlight,
    this.highlightSourceLabel,
  });

  final String capacityExplanation;
  final String statusExplanation;
  final String geographicSuitabilityTitle;
  final String geographicSuitabilityBody;
  final String operationalCharacteristicsBody;
  final String designVariationNote;
  final List<String> environmentalBenefits;
  final List<String> environmentalChallenges;
  final List<String> referenceSources;
  final String? plantSpecificHighlight;
  final String? highlightSourceLabel;

  String get capacityAndStatusExplanation =>
      '$capacityExplanation\n\n$statusExplanation';
  String get geographicReasonTitle => geographicSuitabilityTitle;
  String get geographicReasonBody => geographicSuitabilityBody;
  String get operationalCharacteristicsTitle =>
      'Karakteristik Operasional (Umum)';
  String get referenceAttribution =>
      'Sumber rujukan: ${referenceSources.join(" • ")}';
}

/// Helper terpusat untuk mengintegrasikan keempat pilar EduEarth:
/// Explore <-> Learn <-> Understand Impact <-> Evaluate.
class LearningIntegrationHelper {
  const LearningIntegrationHelper._();

  // UUID kuis terverifikasi dari seed database (20261105104501_phase8_curated_materials_and_quizzes.sql)
  static const String quizBasic5EbtId = '11111111-1111-4111-8111-111111111101';
  static const String quizSolarWindStorageId =
      '11111111-1111-4111-8111-111111111102';
  static const String quizHydroGeothermalId =
      '11111111-1111-4111-8111-111111111103';
  static const String quizBioenergyId = '11111111-1111-4111-8111-111111111104';
  static const String quizMasterArchipelagoId =
      '11111111-1111-4111-8111-111111111105';
  static const String quizEnvironmentalTransitionId =
      '11111111-1111-4111-8111-111111111106';

  /// Memetakan materi pembelajaran ke kuis evaluasi yang relevan berdasarkan
  /// verifikasi isi soal di database, bukan sekadar kecocokan naif `categorySlug`.
  ///
  /// Apabila materi belum memiliki kuis khusus yang menguji substansinya secara
  /// langsung (seperti modul ke-9 `transisi-energi-dan-dampak-lingkungan`),
  /// fungsi ini mengembalikan fallback ke daftar kuis umum (`isDirectTopicMatch: false`).
  static QuizRecommendationResult resolveRecommendedQuizForMaterial({
    required LearningMaterial material,
    required List<Quiz> availableQuizzes,
  }) {
    if (availableQuizzes.isEmpty) {
      return const QuizRecommendationResult(
        isDirectTopicMatch: false,
        buttonLabel: 'Lihat Daftar Kuis Evaluasi',
        cardTitle: 'Uji Pemahaman di Menu Kuis',
        cardDescription: 'Buka halaman daftar kuis untuk memilih topik evaluasi energi terbarukan yang tersedia.',
      );
    }

    final slug = material.slug.trim().toLowerCase();
    final catSlug = material.categorySlug?.trim().toLowerCase() ?? '';

    Quiz? findById(String id) {
      for (final q in availableQuizzes) {
        if (q.id == id) return q;
      }
      return null;
    }

    Quiz? findByCategorySlug(String targetCatSlug) {
      for (final q in availableQuizzes) {
        if (q.categorySlug?.trim().toLowerCase() == targetCatSlug) {
          return q;
        }
      }
      return null;
    }

    // 1. Modul ke-9: Transisi Energi & Dampak Lingkungan
    if (slug == 'transisi-energi-dan-dampak-lingkungan') {
      final transitionQuiz = findById(quizEnvironmentalTransitionId);
      if (transitionQuiz != null) {
        return QuizRecommendationResult(
          quiz: transitionQuiz,
          isDirectTopicMatch: true,
          buttonLabel: 'Kerjakan Kuis: ${transitionQuiz.title}',
          cardTitle: 'Uji Pemahaman Transisi & Trade-Off Lingkungan',
          cardDescription:
              'Uji pemahamanmu mengenai kajian emisi siklus hidup (LCA), manfaat dekarbonisasi, dan trade-off lingkungan 5 kategori EBT.',
        );
      }
      return const QuizRecommendationResult(
        isDirectTopicMatch: false,
        buttonLabel: 'Buka Daftar Kuis Evaluasi',
        cardTitle: 'Siap Menguji Pemahamanmu?',
        cardDescription:
            'Pilih berbagai topik kuis energi terbarukan di halaman Kuis untuk menguji pemahaman konsep dan studi kasus di Indonesia.',
      );
    }

    // 2. Modul Baseload/VRE & Smart Grid Kepulauan -> Kuis 5 (Tantangan Master)
    if (slug == 'baseload-vs-intermiten-vre' ||
        slug == 'smart-grid-dan-elektrifikasi-kepulauan') {
      final masterQuiz = findById(quizMasterArchipelagoId);
      if (masterQuiz != null) {
        return QuizRecommendationResult(
          quiz: masterQuiz,
          isDirectTopicMatch: true,
          buttonLabel: 'Kerjakan Kuis: ${masterQuiz.title}',
          cardTitle: 'Uji Pemahaman Peta & Jaringan Nusantara',
          cardDescription: 'Kuis ini menguji pemahaman sebaran geografis pembangkit di Indonesia, kurva beban listrik, dan mikrogrid kepulauan.',
        );
      }
    }

    // 3. Modul Penyimpanan Energi (BESS & Pumped Storage)
    // Soal BESS diuji di Kuis 2 (Q4) dan Pumped Storage di Kuis 3 (Q6).
    if (slug == 'teknologi-penyimpanan-energi-bess-pumped-storage') {
      final storageQuiz =
          findById(quizSolarWindStorageId) ?? findByCategorySlug('solar');
      if (storageQuiz != null) {
        return QuizRecommendationResult(
          quiz: storageQuiz,
          isDirectTopicMatch: true,
          buttonLabel: 'Kerjakan Kuis: ${storageQuiz.title}',
          cardTitle: 'Uji Pemahaman Intermitensi & Penyimpanan Energi',
          cardDescription: 'Kuis gabungan ini mencakup soal mengenai sifat intermiten surya/angin dan peran penyimpanan baterai (BESS).',
        );
      }
    }

    // 4. Pemetaan berdasarkan kategori utama materi (Surya & Angin -> Kuis 2)
    if (catSlug == 'solar' || catSlug == 'wind') {
      final solarWindQuiz =
          findById(quizSolarWindStorageId) ?? findByCategorySlug('solar');
      if (solarWindQuiz != null) {
        return QuizRecommendationResult(
          quiz: solarWindQuiz,
          isDirectTopicMatch: true,
          buttonLabel: 'Kerjakan Kuis: ${solarWindQuiz.title}',
          cardTitle: 'Uji Wawasan Teknologi Surya & Angin',
          cardDescription: 'Uji pemahamanmu mengenai efek fotovoltaik, inverter, aerodinamika turbin angin, dan penyimpanan energi.',
        );
      }
    }

    // 5. Pemetaan Air & Panas Bumi -> Kuis 3
    if (catSlug == 'hydro' || catSlug == 'geothermal') {
      final hydroGeoQuiz =
          findById(quizHydroGeothermalId) ?? findByCategorySlug('geothermal');
      if (hydroGeoQuiz != null) {
        return QuizRecommendationResult(
          quiz: hydroGeoQuiz,
          isDirectTopicMatch: true,
          buttonLabel: 'Kerjakan Kuis: ${hydroGeoQuiz.title}',
          cardTitle: 'Uji Wawasan Air (PLTA) & Panas Bumi (PLTP)',
          cardDescription: 'Uji pemahamanmu mengenai pipa pesat (penstock), waduk vs run-of-river, sistem hidrotermal, dan sumur injeksi.',
        );
      }
    }

    // 6. Pemetaan Bioenergi -> Kuis 4
    if (catSlug == 'bioenergy') {
      final bioQuiz =
          findById(quizBioenergyId) ?? findByCategorySlug('bioenergy');
      if (bioQuiz != null) {
        return QuizRecommendationResult(
          quiz: bioQuiz,
          isDirectTopicMatch: true,
          buttonLabel: 'Kerjakan Kuis: ${bioQuiz.title}',
          cardTitle: 'Uji Wawasan Sirkularitas Bioenergi',
          cardDescription: 'Uji pemahamanmu mengenai perbedaan biomassa padat (PLTBm) dan fermentasi anaerobik biogas (PLTBg).',
        );
      }
    }

    // 7. Fallback aman ke daftar kuis umum jika tidak ada kuis spesifik yang cocok
    return const QuizRecommendationResult(
      isDirectTopicMatch: false,
      buttonLabel: 'Lihat Daftar Kuis Evaluasi',
      cardTitle: 'Siap Menguji Pemahamanmu?',
      cardDescription: 'Buka halaman daftar kuis untuk memilih evaluasi yang sesuai dengan materi yang telah kamu pelajari.',
    );
  }

  /// Memilih maksimal [maxCount] pembangkit tercatat yang relevan dengan materi (M2.D).
  ///
  /// Prioritas pengurutan:
  /// 1. Status operasional `'operating'` (Beroperasi).
  /// 2. Presisi koordinat `'exact'` (`!plant.isApproximate`).
  /// 3. Memiliki `sourceUrl` yang dapat ditelusuri.
  /// 4. Bukan baris demo (`!plant.isDemo`).
  static List<PowerPlant> selectRelevantPlantsForMaterial({
    required LearningMaterial material,
    required List<PowerPlant> allPlants,
    int maxCount = 3,
  }) {
    if (allPlants.isEmpty || maxCount <= 0) return const <PowerPlant>[];

    // Utamakan baris non-demo jika tersedia
    final nonDemo = allPlants.where((p) => !p.isDemo).toList();
    final sourcePool = nonDemo.isNotEmpty ? nonDemo : allPlants;

    final slug = material.slug.trim().toLowerCase();
    final catSlug = material.categorySlug?.trim().toLowerCase() ?? '';

    int comparePriority(PowerPlant a, PowerPlant b) {
      final aOp = a.operationalStatus.trim().toLowerCase() == 'operating'
          ? 0
          : 1;
      final bOp = b.operationalStatus.trim().toLowerCase() == 'operating'
          ? 0
          : 1;
      if (aOp != bOp) return aOp.compareTo(bOp);

      final aExact = a.isApproximate ? 1 : 0;
      final bExact = b.isApproximate ? 1 : 0;
      if (aExact != bExact) return aExact.compareTo(bExact);

      final aHasSource = (a.sourceUrl != null && a.sourceUrl!.trim().isNotEmpty)
          ? 0
          : 1;
      final bHasSource = (b.sourceUrl != null && b.sourceUrl!.trim().isNotEmpty)
          ? 0
          : 1;
      if (aHasSource != bHasSource) return aHasSource.compareTo(bHasSource);

      final aCap = a.capacityMw ?? 0.0;
      final bCap = b.capacityMw ?? 0.0;
      return bCap.compareTo(aCap);
    }

    // Untuk modul lintas-kategori (baseload vs VRE, smart grid, transisi dampak lingkungan),
    // ambil perwakilan lintas kategori agar tidak bias ke satu kategori saja.
    if (slug == 'baseload-vs-intermiten-vre' ||
        slug == 'smart-grid-dan-elektrifikasi-kepulauan' ||
        slug == 'transisi-energi-dan-dampak-lingkungan') {
      final targetCategories = slug == 'smart-grid-dan-elektrifikasi-kepulauan'
          ? const ['wind', 'solar', 'hydro', 'geothermal', 'bioenergy']
          : const ['geothermal', 'hydro', 'solar', 'wind', 'bioenergy'];

      final picked = <PowerPlant>[];
      final pickedIds = <String>{};

      for (final targetCat in targetCategories) {
        final candidates =
            sourcePool
                .where((p) => p.categorySlug?.toLowerCase() == targetCat)
                .toList()
              ..sort(comparePriority);
        if (candidates.isNotEmpty) {
          picked.add(candidates.first);
          pickedIds.add(candidates.first.id);
          if (picked.length >= maxCount) break;
        }
      }

      if (picked.length < maxCount) {
        final remaining =
            sourcePool.where((p) => !pickedIds.contains(p.id)).toList()
              ..sort(comparePriority);
        for (final r in remaining) {
          picked.add(r);
          if (picked.length >= maxCount) break;
        }
      }
      return picked.take(maxCount).toList();
    }

    // Untuk modul penyimpanan energi (BESS & Pumped Storage),
    // ambil kombinasi pembangkit surya dan hidro yang relevan dengan konsep penyimpanan/penyeimbang.
    if (slug == 'teknologi-penyimpanan-energi-bess-pumped-storage') {
      final candidates =
          sourcePool
              .where(
                (p) =>
                    p.categorySlug?.toLowerCase() == 'solar' ||
                    p.categorySlug?.toLowerCase() == 'hydro',
              )
              .toList()
            ..sort(comparePriority);

      // Pastikan ada perwakilan solar dan hydro bila keduanya tersedia
      final solarTop = candidates
          .where((p) => p.categorySlug?.toLowerCase() == 'solar')
          .take(2)
          .toList();
      final hydroTop = candidates
          .where((p) => p.categorySlug?.toLowerCase() == 'hydro')
          .take(2)
          .toList();

      final combined = <PowerPlant>[];
      if (solarTop.isNotEmpty) combined.add(solarTop.first);
      if (hydroTop.isNotEmpty) combined.add(hydroTop.first);
      for (final c in candidates) {
        if (combined.length >= maxCount) break;
        if (!combined.any((item) => item.id == c.id)) {
          combined.add(c);
        }
      }
      return combined.take(maxCount).toList();
    }

    // Untuk modul spesifik 1 kategori energi
    if (catSlug.isNotEmpty) {
      final filtered =
          sourcePool
              .where((p) => p.categorySlug?.trim().toLowerCase() == catSlug)
              .toList()
            ..sort(comparePriority);
      return filtered.take(maxCount).toList();
    }

    final sortedAll = List<PowerPlant>.from(sourcePool)..sort(comparePriority);
    return sortedAll.take(maxCount).toList();
  }

  /// Memilih daftar modul materi yang relevan dengan suatu pembangkit untuk ditampilkan
  /// pada halaman `PlantDetailPage` (M2.B).
  static List<LearningMaterial> selectRelevantMaterialsForPlant({
    required PowerPlant plant,
    required List<LearningMaterial> allMaterials,
  }) {
    if (allMaterials.isEmpty) return const <LearningMaterial>[];
    final slug = plant.categorySlug?.trim().toLowerCase() ?? '';

    final categoryMatches = allMaterials.where((m) {
      final mCat = m.categorySlug?.trim().toLowerCase() ?? '';
      final mSlug = m.slug.trim().toLowerCase();
      // Jangan masukkan modul umum lintas-kategori sebagai modul khusus 1 kategori
      if (mSlug == 'baseload-vs-intermiten-vre' ||
          mSlug == 'smart-grid-dan-elektrifikasi-kepulauan' ||
          mSlug == 'transisi-energi-dan-dampak-lingkungan') {
        return false;
      }
      return mCat == slug;
    }).toList();

    final crossCategoryMatches = allMaterials.where((m) {
      final mSlug = m.slug.trim().toLowerCase();
      return mSlug == 'transisi-energi-dan-dampak-lingkungan' ||
          mSlug == 'baseload-vs-intermiten-vre';
    }).toList();

    return <LearningMaterial>[
      ...categoryMatches,
      ...crossCategoryMatches,
    ].take(3).toList();
  }

  /// Menghasilkan penjelasan edukatif kontekstual yang akurat, berimbang, dan tidak
  /// menggeneralisasi untuk ditampilkan di `PlantDetailPage` (M1.A s.d. M1.D).
  static PlantEducationalContext buildPlantEducationalContext(
    PowerPlant plant,
  ) {
    final slug = plant.categorySlug?.trim().toLowerCase() ?? '';
    final hasCapacity = plant.capacityMw != null && plant.capacityMw! > 0;
    final capString = hasCapacity
        ? '${plant.capacityMw!.toStringAsFixed(2)} MW'
        : 'belum tercantum pada sumber';

    final capacityExplanation = hasCapacity
        ? 'Kapasitas terpasang ($capString) menunjukkan daya listrik maksimum nominal yang dirancang pada fasilitas ini menurut catatan sumber (sebagai gambaran skala daya: 1 MW = 1.000 kW = 1.000.000 Watt, atau setara daya puncak sesaat sekitar 750–1.100 sambungan rumah tangga 900–1.300 VA). Angka ini bukan berarti pembangkit selalu menyuplai listrik sebesar $capString setiap jam, karena produksi aktual bergantung pada faktor kapasitas (capacity factor), ketersediaan sumber energi primer, jadwal pemeliharaan, serta beban jaringan.'
        : 'Kapasitas terpasang (dalam satuan Megawatt / MW, di mana 1 MW = 1.000.000 Watt) menunjukkan batas daya maksimum rancangan pembangkit. Pada baris data ini, nilai kapasitas belum dicantumkan di sumber rujukan.';

    final statusExplanation = _statusExplanationFor(plant.operationalStatus);
    final curatedCase = _curatedPlantStudyCase(plant);

    switch (slug) {
      case 'solar':
        return PlantEducationalContext(
          capacityExplanation: capacityExplanation,
          statusExplanation: statusExplanation,
          plantSpecificHighlight: curatedCase?.note,
          highlightSourceLabel: curatedCase?.source,
          geographicSuitabilityTitle:
              'Mengapa PLTS Umumnya Cocok di Wilayah Ini?',
          geographicSuitabilityBody:
              'Secara umum, wilayah Indonesia berada di sekitar garis khatulistiwa sehingga menerima penyinaran matahari yang relatif konsisten sepanjang tahun. Kelayakan lokasi PLTS di wilayah seperti ${plant.province} umumnya didukung oleh intensitas iradiasi surya harian, ketersediaan lahan terbuka atau permukaan waduk yang minim bayangan, serta akses ke jaringan distribusi listrik setempat.',
          operationalCharacteristicsBody: 'PLTS umumnya menghasilkan daya secara variabel (intermiten) mengikuti siklus siang-malam dan pergerakan awan. Oleh sebab itu, keluaran listriknya mencapai puncak pada siang hari dan turun saat petang.',
          designVariationNote: 'Karakteristik tiap PLTS dapat berbeda-beda: PLTS yang dilengkapi sistem penyimpanan baterai (BESS) mampu menyalurkan daya cadangan saat cuaca mendung atau malam hari, sedangkan PLTS tanpa baterai menyuplai listrik secara langsung saat matahari bersinar. Selain itu, instalasi dapat berupa PLTS darat (ground-mounted) maupun PLTS terapung (floating PV) di atas waduk.',
          environmentalBenefits: const [
            'Mengubah cahaya matahari menjadi listrik tanpa proses pembakaran bahan bakar fosil selama beroperasi.',
            'Tidak membutuhkan konsumsi air pendingin turbin dan tidak menghasilkan kebisingan mekanis.',
            'Pada desain PLTS terapung, pemanfaatan permukaan waduk yang sudah ada dapat mengurangi kebutuhan pembukaan lahan baru di daratan.',
          ],
          environmentalChallenges: const [
            'Instalasi PLTS skala besar di daratan membutuhkan area ruang/lahan yang cukup luas per satuan MW.',
            'Jejak emisi siklus hidup tetap ada pada tahap penambangan silikon, manufaktur modul, dan transportasi.',
            'Memerlukan pengelolaan dan daur ulang limbah panel surya serta baterai secara bertanggung jawab pada akhir masa pakai (end-of-life).',
          ],
          referenceSources: const [
            'IPCC AR6 WGIII (2022), Chapter 6: Energy Systems & Annex III (Life-cycle emissions & VRE integration)',
            'IRENA — Solar Photovoltaic Technology Brief',
            'Kementerian ESDM — Direktorat Jenderal EBTKE',
          ],
        );

      case 'hydro':
        return PlantEducationalContext(
          capacityExplanation: capacityExplanation,
          statusExplanation: statusExplanation,
          plantSpecificHighlight: curatedCase?.note,
          highlightSourceLabel: curatedCase?.source,
          geographicSuitabilityTitle:
              'Mengapa PLTA Umumnya Cocok di Wilayah Ini?',
          geographicSuitabilityBody:
              'Pengembangan PLTA di wilayah seperti ${plant.province} umumnya berkaitan dengan kondisi topografi berbukit/pegunungan yang menciptakan beda tinggi jatuh air (head) serta keberadaan Daerah Aliran Sungai (DAS) atau danau dengan debit air yang memadai.',
          operationalCharacteristicsBody: 'Secara umum, PLTA mampu beroperasi dengan respons yang cepat terhadap perubahan beban listrik di jaringan, sehingga sering berperan menjaga kestabilan frekuensi kelistrikan.',
          designVariationNote: 'Tidak semua PLTA memiliki karakteristik yang sama: PLTA berwaduk (reservoir) mampu menyimpan cadangan air untuk diatur saat beban puncak, PLTA aliran sungai langsung (run-of-river) sangat bergantung pada debit sungai saat itu tanpa tampungan besar, sedangkan Pumped Storage berfungsi menyimpan energi dengan memompa air kembali ke waduk atas.',
          environmentalBenefits: const [
            'Menghasilkan listrik rendah emisi karbon selama masa operasi tanpa membakar bahan bakar fosil.',
            'Infrastruktur sipil memiliki masa pakai jangka panjang dan pada sistem berwaduk dapat mendukung pengendalian banjir serta irigasi.',
            'Mampu menyeimbangkan jaringan listrik ketika pembangkit surya atau angin mengalami fluktuasi cuaca.',
          ],
          environmentalChallenges: const [
            'Pembangunan bendungan berwaduk besar membutuhkan genangan lahan yang luas dan dapat mengubah ekosistem sungai serta pola migrasi biota air.',
            'Keandalan produksi listrik sensitif terhadap kemarau panjang dan laju sedimentasi apabila hutan di hulu DAS terdegradasi.',
            'Pada waduk tertentu, pembusukan biomassa yang tergenang di awal operasional dapat menghasilkan emisi gas rumah kaca biogenik.',
          ],
          referenceSources: const [
            'IPCC AR6 WGIII (2022), Chapter 6: Energy Systems (Hydropower characteristics & ecological trade-offs)',
            'IRENA — Hydropower Technology Brief',
            'Kementerian ESDM — Direktorat Jenderal EBTKE',
          ],
        );

      case 'wind':
        return PlantEducationalContext(
          capacityExplanation: capacityExplanation,
          statusExplanation: statusExplanation,
          plantSpecificHighlight: curatedCase?.note,
          highlightSourceLabel: curatedCase?.source,
          geographicSuitabilityTitle:
              'Mengapa PLTB Umumnya Cocok di Wilayah Ini?',
          geographicSuitabilityBody:
              'Meskipun kecepatan angin rata-rata di daerah khatulistiwa umumnya sedang, wilayah tertentu seperti kawasan pesisir, punggung perbukitan, atau celah pegunungan di ${plant.province} dapat memiliki koridor angin lokal dan angin monsun yang cukup kuat untuk memutar turbin angin skala utilitas.',
          operationalCharacteristicsBody: 'PLTB umumnya bersifat variabel (intermiten) karena daya yang dibangkitkan sangat bergantung pada kecepatan angin dari waktu ke waktu (baik siang maupun malam hari).',
          designVariationNote: 'Kinerja tiap PLTB bergantung pada profil angin musiman wilayah setempat, tinggi menara (hub height), diameter bilah rotor, serta kesiapan sistem gardu induk dan penyeimbang frekuensi pada jaringan listrik daerah tersebut.',
          environmentalBenefits: const [
            'Membangkitkan listrik dari energi kinetik angin tanpa pembakaran bahan bakar dan tanpa konsumsi air pendingin.',
            'Lahan di sekitar kaki menara turbin umumnya masih dapat dimanfaatkan bersama untuk pertanian atau penggembalaan.',
          ],
          environmentalChallenges: const [
            'Sifat pasokan yang berfluktuasi mengikuti hembusan angin memerlukan pembangkit penyeimbang atau penyimpanan energi di jaringan.',
            'Membutuhkan kajian penempatan lokasi yang cermat untuk meminimalkan risiko terhadap jalur terbang burung/kelelawar serta kebisingan mekanis di dekat permukiman.',
            'Pengangkutan bilah turbin berukuran panjang membutuhkan akses infrastruktur jalan dan logistik khusus.',
          ],
          referenceSources: const [
            'IPCC AR6 WGIII (2022), Chapter 6: Energy Systems (Wind energy integration & environmental considerations)',
            'IRENA — Wind Power Technology Brief',
            'Kementerian ESDM — Direktorat Jenderal EBTKE',
          ],
        );

      case 'geothermal':
        return PlantEducationalContext(
          capacityExplanation: capacityExplanation,
          statusExplanation: statusExplanation,
          plantSpecificHighlight: curatedCase?.note,
          highlightSourceLabel: curatedCase?.source,
          geographicSuitabilityTitle:
              'Mengapa PLTP Umumnya Cocok di Wilayah Ini?',
          geographicSuitabilityBody:
              'Kepulauan Indonesia dilalui jalur sabuk vulkanik aktif (Ring of Fire). Wilayah seperti ${plant.province} umumnya memiliki aktivitas tektonik dan magmatik bawah permukaan yang membentuk sistem hidrotermal (batuan pemanas, reservoar air/uap, dan batuan penudung) yang dibutuhkan oleh PLTP.',
          operationalCharacteristicsBody: 'PLTP umumnya beroperasi sebagai pembangkit beban dasar (baseload) yang menyuplai listrik secara stabil sepanjang hari (24 jam) karena sumber panas di dalam bumi tidak terpengaruh cuaca hujan atau pergantian siang-malam.',
          designVariationNote: 'Karakteristik teknis tiap PLTP dapat berbeda tergantung kondisi reservoarnya: sistem uap kering (dry steam), uap pemisahan (flash steam), atau siklus biner (binary cycle) untuk fluida bersuhu menengah. Keberlanjutan jangka panjangnya sangat bergantung pada disiplin injeksi ulang (reinjection) fluida ke dalam sumur.',
          environmentalBenefits: const [
            'Menghasilkan listrik beban dasar yang stabil dengan emisi karbon per kWh yang umumnya jauh lebih rendah dibandingkan pembangkit batu bara.',
            'Kebutuhan luas tapak lahan di permukaan per satuan MW relatif ringkas dibandingkan ladang surya atau waduk air.',
          ],
          environmentalChallenges: const [
            'Banyak potensi panas bumi berada di sekitar kawasan pegunungan atau hutan, sehingga pembukaan akses jalan dan tapak sumur harus dijaga ketat agar tidak merusak ekosistem.',
            'Memerlukan pengelolaan fluida termal (brine) melalui sumur reinjeksi serta pengendalian gas tidak terkondensasi (seperti H₂S dan CO₂ alami dari reservoar).',
            'Memiliki risiko ketidakpastian geologi pada tahap pengeboran eksplorasi awal.',
          ],
          referenceSources: const [
            'IPCC AR6 WGIII (2022), Chapter 6: Energy Systems (Geothermal energy & reservoir management)',
            'IRENA — Geothermal Power Technology Brief',
            'Kementerian ESDM — Direktorat Jenderal EBTKE',
          ],
        );

      case 'bioenergy':
      default:
        return PlantEducationalContext(
          capacityExplanation: capacityExplanation,
          statusExplanation: statusExplanation,
          plantSpecificHighlight: curatedCase?.note,
          highlightSourceLabel: curatedCase?.source,
          geographicSuitabilityTitle:
              'Mengapa Pembangkit Bioenergi Umumnya Cocok di Wilayah Ini?',
          geographicSuitabilityBody:
              'Pengembangan bioenergi di wilayah seperti ${plant.province} umumnya didukung oleh keberadaan aktivitas perkebunan, pertanian, atau industri pengolahan hasil bumi yang menghasilkan residu organik (seperti cangkang/serat sawit, sekam, ampas tebu, atau limbah cair organik).',
          operationalCharacteristicsBody: 'Pembangkit bioenergi umumnya bersifat dapat dikendalikan jadwal operasinya (dispatchable) selama bahan baku organik tersedia dan tersimpan dengan baik di lokasi fasilitas.',
          designVariationNote: 'Karakteristik bioenergi sangat beragam: PLTBm (biomassa padat) menggunakan pembakaran boiler uap atau gasifikasi, sedangkan PLTBg (biogas) menggunakan reaktor kedap udara (anaerobic digester) untuk memfermentasi limbah cair organik (seperti POME kelapa sawit) menjadi gas metana.',
          environmentalBenefits: const [
            'Mendukung ekonomi sirkular dengan memanfaatkan limbah pertanian/agroindustri menjadi energi listrik.',
            'Pada sistem PLTBg pengolah limbah cair (seperti POME), penangkapan gas metana (CH₄) di reaktor tertutup membantu mencegah lepasnya gas rumah kaca metana ke atmosfer.',
          ],
          environmentalChallenges: const [
            'Keberlanjutan lingkungan sangat bergantung pada sumber bahan baku: harus berasal dari limbah/residu atau tanaman energi yang dikelola lestari, bukan dari pembukaan hutan alami.',
            'Proses pembakaran biomassa padat pada PLTBm tetap menghasilkan emisi gas buang dan abu sehingga wajib dilengkapi sistem pengendali partikulat.',
            'Memerlukan manajemen rantai pasok (pengumpulan, transportasi, dan pengeringan bahan baku) yang konsisten lintas musim.',
          ],
          referenceSources: const [
            'IPCC AR6 WGIII (2022), Chapter 6 & Chapter 7 (Bioenergy sustainability, feedstock & lifecycle considerations)',
            'Kementerian ESDM — Ditjen EBTKE: Buku Saku Bioenergi 2023',
            'IRENA — Bioenergy for Power Generation Technology Brief',
          ],
        );
    }
  }

  static String _statusExplanationFor(String rawStatus) {
    switch (rawStatus.trim().toLowerCase()) {
      case 'operating':
        return 'Status Beroperasi menunjukkan bahwa fasilitas pembangkit ini tercatat telah aktif membangkitkan listrik pada waktu pencatatan sumber data.';
      case 'construction':
        return 'Status Konstruksi menunjukkan bahwa proyek ini tercatat sedang dalam tahap pembangunan fisik dan belum beroperasi penuh secara komersial.';
      case 'planned':
        return 'Status Rencana menunjukkan bahwa proyek ini masih berada pada tahap perencanaan, pengumuman, atau studi kelayakan menurut sumber (belum dibangun/beroperasi).';
      default:
        return 'Status operasional spesifik untuk titik ini belum tercatat secara pasti pada sumber rujukan.';
    }
  }

  /// Ringkasan singkat 1 kalimat alasan geografis untuk pratinjau cepat di peta.
  static String shortGeographicSummaryForPlant(PowerPlant plant) {
    switch (plant.categorySlug?.trim().toLowerCase()) {
      case 'solar':
        return 'Wilayah ${plant.province} umumnya menerima penyinaran matahari tropis yang mendukung konversi fotovoltaik siang hari.';
      case 'hydro':
        return 'Topografi perbukitan dan Daerah Aliran Sungai (DAS) di ${plant.province} umumnya menyediakan beda tinggi (head) dan debit air bagi turbin.';
      case 'wind':
        return 'Koridor pesisir atau punggungan bukit di ${plant.province} umumnya memiliki hembusan angin muson yang konsisten untuk memutar rotor.';
      case 'geothermal':
        return 'Berada pada jalur vulkanik aktif di ${plant.province} yang umumnya menyimpan reservoar uap panas bumi untuk pasokan beban dasar 24 jam.';
      case 'bioenergy':
      default:
        return 'Didukung ketersediaan residu biomassa perkebunan/pertanian atau limbah organik cair di wilayah ${plant.province}.';
    }
  }

  /// Rekomendasi materi bacaan & kategori perbandingan untuk tindak lanjut hasil kuis (`QuizResultPage`).
  static ({
    String materialSlug,
    String materialTitle,
    String? comparisonCategorySlug,
  }) remedialInfoForQuiz(String quizId) {
    switch (quizId.trim()) {
      case quizSolarWindStorageId:
        return (
          materialSlug: 'draf-konsep-dasar-plts',
          materialTitle: 'Teknologi PLTS, PLTB, & Penyimpanan Baterai',
          comparisonCategorySlug: 'solar',
        );
      case quizHydroGeothermalId:
        return (
          materialSlug: 'draf-konsep-dasar-pltp',
          materialTitle: 'Sistem Hidrotermal PLTP & Penyeimbang PLTA',
          comparisonCategorySlug: 'geothermal',
        );
      case quizBioenergyId:
        return (
          materialSlug: 'draf-konsep-dasar-bioenergi',
          materialTitle: 'Sirkularitas Bioenergi: Biomassa & Biogas',
          comparisonCategorySlug: 'bioenergy',
        );
      case quizMasterArchipelagoId:
        return (
          materialSlug: 'smart-grid-dan-elektrifikasi-kepulauan',
          materialTitle: 'Smart Grid & Elektrifikasi Kepulauan Nusantara',
          comparisonCategorySlug: null,
        );
      case quizEnvironmentalTransitionId:
        return (
          materialSlug: 'transisi-energi-dan-dampak-lingkungan',
          materialTitle: 'Transisi Energi & Trade-off Lingkungan',
          comparisonCategorySlug: null,
        );
      case quizBasic5EbtId:
      default:
        return (
          materialSlug: 'transisi-energi-dan-dampak-lingkungan',
          materialTitle: 'Pengantar 5 Kategori EBT & Transisi Energi',
          comparisonCategorySlug: 'solar',
        );
    }
  }

  /// Catatan studi kasus khusus untuk 13 pembangkit ikonik lintas 5 kategori.
  /// Seluruh fakta dirangkum murni dari `source_notes` & `source_url` terverifikasi di dataset.
  static ({String note, String source})? _curatedPlantStudyCase(
    PowerPlant plant,
  ) {
    final key = '${plant.name} ${plant.externalRef ?? ''}'.toLowerCase();
    final catSlug = plant.categorySlug?.trim().toLowerCase() ?? '';

    if (key.contains('cirata') && catSlug == 'solar') {
      return (
        note:
            'Studi kasus PLTS Terapung pertama berskala besar di Indonesia (diresmikan 9 November 2023) oleh konsorsium PT PLN Nusantara Power (51%) dan Masdar (49%). Modul surya dipasang mengapung di permukaan Waduk Cirata untuk menghemat alih fungsi lahan darat, dengan kapasitas tercatat 145 MWac (192 MWp DC).',
        source: 'Global Energy Monitor (Global Solar Power Tracker) & catatan sumber proyek',
      );
    }
    if (key.contains('ibu kota nusantara') || key.contains('nusantara sembcorp')) {
      return (
        note:
            'Proyek PLTS skala utilitas 50 MW oleh joint venture PT PLN Nusantara Renewables dan Sembcorp Utilities Pte. Ltd. yang terintegrasi sistem penyimpanan baterai (BESS) untuk menstabilkan pasokan surya di kawasan IKN (Fase 1 berkapasitas 10 MW telah beroperasi komersial).',
        source: 'Global Energy Monitor (Global Solar Power Tracker)',
      );
    }
    if (key.contains('likupang') || key.contains('minut solar')) {
      return (
        note:
            'PLTS Likupang (Minut Solar Farm) berkapasitas 21 MWac di Minahasa Utara, Sulawesi Utara, beroperasi komersial sejak 2019 (Vena Energy) untuk memperkuat pasokan listrik sistem jaringan PLN Sulutenggo.',
        source: 'Global Energy Monitor (Global Solar Power Tracker)',
      );
    }
    if (key.contains('pltp kamojang') || key.contains('kamojang_geothermal')) {
      return (
        note:
            'Salah satu lapangan panas bumi uap komersial utama di Jawa Barat yang dikelola PT Pertamina Geothermal Energy Tbk dengan total kapasitas 235 MW (terbagi atas Unit 1: 30 MW, Unit 2: 55 MW, Unit 3: 55 MW, Unit 4: 60 MW, dan Unit 5: 35 MW) untuk sistem Jawa–Madura–Bali.',
        source: 'Global Energy Monitor (Mar 2026), profil resmi PGE & Ditjen EBTKE ESDM',
      );
    }
    if (key.contains('sarulla')) {
      return (
        note:
            'PLTP Sarulla (330 MW) di Tapanuli Utara memanfaatkan teknologi siklus biner dan dua reservoir — Silangkitang (SIL 110 MW) serta Namora-I-Langit (NIL-1 110 MW & NIL-2 110 MW) oleh Sarulla Operations Ltd. (catatan: titik koordinat berstatus perkiraan).',
        source: 'Global Energy Monitor (Mar 2026), Sarulla Operations Ltd. & Ditjen EBTKE ESDM',
      );
    }
    if (key.contains('dieng')) {
      return (
        note:
            'PLTP Dieng (60 MW) di Dataran Tinggi Dieng, Wonosobo, menggunakan teknologi single flash yang dikelola BUMN PT Geo Dipa Energi (Persero), menunjukkan pemanfaatan energi panas bumi dataran tinggi vulkanik sebagai pembangkit beban dasar.',
        source: 'Global Energy Monitor (Mar 2026), PT Geo Dipa Energi & Ditjen EBTKE ESDM',
      );
    }
    if (key.contains('plta cirata') || key.contains('cirata_hydroelectric')) {
      return (
        note:
            'PLTA Cirata (1.008 MW) di Purwakarta yang dioperasikan PT PLN Nusantara Power adalah komponen tengah dari rangkaian kaskade tiga PLTA besar di aliran Sungai Citarum (Saguling → Cirata → Jatiluhur) sekaligus lokasi bersama proyek PLTS Terapung Cirata.',
        source: 'Global Energy Monitor (Apr 2024), OSM way/797077394 & PT PLN Nusantara Power',
      );
    }
    if (key.contains('saguling')) {
      return (
        note:
            'PLTA Saguling (701 MW, 4 x 175,18 MW) di Bandung Barat menempati posisi hulu dari sistem kaskade Sungai Citarum yang dioperasikan PT PLN Indonesia Power, memanfaatkan beda tinggi (head) sungai di dataran tinggi Bandung.',
        source: 'Global Energy Monitor (Apr 2024) & PT PLN Indonesia Power',
      );
    }
    if (key.contains('upper cisokan')) {
      return (
        note:
            'PLTA Upper Cisokan Pumped Storage (1.040 MW, tahap konstruksi oleh PT PLN Persero) di Bandung Barat dirancang sebagai pembangkit pompa bertingkat (dua waduk atas-bawah) untuk menyimpan energi saat beban rendah dan menopang beban puncak sistem Jawa–Bali.',
        source: 'Global Energy Monitor Global Hydropower Tracker (Apr 2024)',
      );
    }
    if (key.contains('sidrap')) {
      return (
        note:
            'PLTB Sidrap I (75 MW) di Kab. Sidenreng Rappang adalah pembangkit listrik tenaga bayu komersial pertama di Indonesia dengan 30 turbin angin (PT UPC Sidrap Bayu Energi), beroperasi sejak Juli 2018 memanfaatkan koridor angin Sulawesi Selatan.',
        source: 'Global Energy Monitor (Feb 2026) & Ditjen EBTKE Kementerian ESDM',
      );
    }
    if (key.contains('tolo')) {
      return (
        note:
            'PLTB Tolo I (72 MW) di Kab. Jeneponto, Sulawesi Selatan (PT Energi Bayu Jeneponto / Vena Energy), beroperasi komersial sejak 2019 mendampingi PLTB Sidrap dalam memasok sistem kelistrikan Sulselrabar.',
        source: 'Global Energy Monitor (Feb 2026) & Kementerian ESDM',
      );
    }
    if (key.contains('jangkang')) {
      return (
        note:
            'PLTBg Jangkang di Belitung Timur adalah IPP biogas komersial pertama di Indonesia yang mengonversi limbah cair kelapa sawit (POME) menjadi listrik jaringan PLN (PPA sejak 2013). Catatan sumber: publikasi ESDM 2017 mencatat peningkatan ke 1,8 MW sementara Buku Saku Bioenergi 2023 mencatat 0,6 MW; titik peta berupa sentroid Desa Jangkang (Lokasi perkiraan).',
        source: 'Publikasi Kementerian ESDM (2017) & Buku Saku Bioenergi 2023',
      );
    }
    if (key.contains('siantan')) {
      return (
        note:
            'PLTBm Siantan di Mempawah adalah pembangkit biomassa swasta pertama di Kalimantan Barat (COD April 2018) yang membakar limbah pertanian dan serbuk kayu untuk Sistem Khatulistiwa PLN. Catatan sumber: siaran pers EBTKE 2018 mencatat 15 MW sedangkan Buku Saku Bioenergi 2023 mencatat 10 MW; titik peta berupa sentroid Desa Wajok Hulu (Lokasi perkiraan).',
        source: 'Siaran Pers Ditjen EBTKE ESDM (2018) & Buku Saku Bioenergi 2023',
      );
    }

    return null;
  }
}
