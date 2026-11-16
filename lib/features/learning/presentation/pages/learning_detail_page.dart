import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/category_chip.dart';
import '../../../../core/widgets/common/empty_view.dart';
import '../../../../core/widgets/common/error_view.dart';
import '../../../../core/widgets/common/loading_view.dart';
import '../../../../core/widgets/common/screen_header.dart';
import '../../../../models/learning_material.dart';
import '../../../../models/power_plant.dart';
import '../../../../routes/route_names.dart';
import '../../../../services/external_map_service.dart';
import '../../../achievement/presentation/providers/achievement_providers.dart';
import '../../../achievement/presentation/widgets/achievement_unlock_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookmark/presentation/providers/bookmark_providers.dart';
import '../../../plants/presentation/providers/plants_providers.dart';
import '../../../quiz/presentation/providers/quiz_providers.dart';
import '../../domain/learning_integration_helper.dart';
import '../../domain/learning_material_parser.dart';
import '../providers/learning_providers.dart';
import '../providers/reading_progress_provider.dart';
import '../widgets/learning_detail_sections.dart';

/// Halaman detail materi pembelajaran dengan tata letak editorial interaktif:
/// - Header sticky terpadu: tombol kembali, judul materi, bookmark, bar progres 5dp,
///   banner lanjutkan posisi terakhir, dan pil navigasi bagian ScrollSpy
/// - Kartu Hero topik, Intisari Konsep (callout hijau hutan), dan prosa editorial
/// - Simulasi interaktif 3 tahap atau eksplorasi 5 EBT lintas kategori
/// - Komponen/spesifikasi sebagai grid kartu, sub-bagian segmented tabs, Pro/Kontra,
///   contoh pembangkit nyata di Indonesia, flashcard flip 3D, referensi, dan ajakan kuis
class LearningDetailPage extends ConsumerStatefulWidget {
  const LearningDetailPage({super.key, required this.materialSlug});

  final String materialSlug;

  @override
  ConsumerState<LearningDetailPage> createState() => _LearningDetailPageState();
}

class _LearningDetailPageState extends ConsumerState<LearningDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _viewportKey = GlobalKey();
  final Map<String, GlobalKey> _sectionKeys = <String, GlobalKey>{};
  final Map<String, GlobalKey> _navItemKeys = <String, GlobalKey>{};

  List<MaterialNavItem> _currentNavItems = const <MaterialNavItem>[];
  String? _activeNavId;
  double _readingProgress = 0.0;
  bool _hasDismissedResumeBanner = false;
  int _selectedExplorerIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initReadingProgress();
  }

  @override
  void didUpdateWidget(covariant LearningDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.materialSlug != widget.materialSlug) {
      _sectionKeys.clear();
      _navItemKeys.clear();
      _currentNavItems = const <MaterialNavItem>[];
      setState(() {
        _activeNavId = null;
        _readingProgress = 0.0;
        _hasDismissedResumeBanner = false;
        _selectedExplorerIndex = 0;
      });
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      _initReadingProgress();
    }
  }

  void _initReadingProgress() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(isGuestSessionProvider)) return;
      final saved = ref
          .read(readingProgressProvider)
          .progressFor(widget.materialSlug);
      if (saved > _readingProgress) {
        setState(() => _readingProgress = saved);
      }
      ref
          .read(readingProgressProvider.notifier)
          .markMaterialOpened(widget.materialSlug);
    });
  }

  GlobalKey _keyForSection(String id) =>
      _sectionKeys.putIfAbsent(id, GlobalKey.new);

  GlobalKey _keyForNavItem(String id) =>
      _navItemKeys.putIfAbsent(id, GlobalKey.new);

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;

    if (offset > 100 && !_hasDismissedResumeBanner) {
      setState(() => _hasDismissedResumeBanner = true);
    }

    final isGuestSession = ref.read(isGuestSessionProvider);

    if (maxScroll <= 0) {
      if (_readingProgress != 1.0) {
        setState(() => _readingProgress = 1.0);
      }
      if (!isGuestSession) {
        ref.read(readingProgressProvider.notifier).updateReadingProgress(
              slug: widget.materialSlug,
              scrollFraction: 1.0,
              scrollOffset: 0.0,
            );
      }
    } else {
      final rawCurrent = (offset / maxScroll).clamp(0.0, 1.0);
      final current = rawCurrent >= 0.96 ? 1.0 : rawCurrent;
      final savedMax = isGuestSession
          ? 0.0
          : ref.read(readingProgressProvider).progressFor(widget.materialSlug);

      // High-water mark: progres tersimpan pengguna tidak turun saat scroll ke atas
      final nextMax = math.max(math.max(_readingProgress, savedMax), current);

      if ((nextMax - _readingProgress).abs() > 0.005 ||
          (nextMax == 1.0 && _readingProgress < 1.0)) {
        setState(() => _readingProgress = nextMax);
      }

      if (!isGuestSession) {
        ref.read(readingProgressProvider.notifier).updateReadingProgress(
              slug: widget.materialSlug,
              scrollFraction: nextMax,
              scrollOffset: offset,
            );
      }
    }

    _updateScrollSpySelection(offset: offset, maxScroll: maxScroll);
  }

  void _updateScrollSpySelection({
    required double offset,
    required double maxScroll,
  }) {
    if (_currentNavItems.isEmpty) return;

    String nextId = _currentNavItems.first.id;
    if (maxScroll > 0 && offset >= maxScroll - 28) {
      nextId = _currentNavItems.last.id;
    } else {
      final viewportBox =
          _viewportKey.currentContext?.findRenderObject() as RenderBox?;
      final cutoffY =
          (viewportBox?.localToGlobal(Offset.zero).dy ?? 160.0) + 64.0;

      for (final item in _currentNavItems) {
        final box =
            item.sectionKey.currentContext?.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) continue;
        final dy = box.localToGlobal(Offset.zero).dy;
        if (dy <= cutoffY) {
          nextId = item.id;
        } else {
          break;
        }
      }
    }

    if (nextId != _activeNavId) {
      setState(() => _activeNavId = nextId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final pillContext = _navItemKeys[nextId]?.currentContext;
        if (pillContext != null) {
          Scrollable.ensureVisible(
            pillContext,
            alignment: 0.5,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  Future<void> _scrollToNavItem(MaterialNavItem item) async {
    setState(() => _activeNavId = item.id);
    final pillContext = _navItemKeys[item.id]?.currentContext;
    if (pillContext != null && pillContext.mounted) {
      Scrollable.ensureVisible(
        pillContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
    final sectionContext = item.sectionKey.currentContext;
    if (sectionContext != null && sectionContext.mounted) {
      await Scrollable.ensureVisible(
        sectionContext,
        alignment: 0.02,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _resumeLastScrollOffset(double targetOffset) async {
    setState(() => _hasDismissedResumeBanner = true);
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final clampedTarget = targetOffset.clamp(
      0.0,
      maxScroll > 0 ? maxScroll : targetOffset,
    );
    await _scrollController.animateTo(
      clampedTarget,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _handleOpenLink(
    BuildContext context,
    ExternalMapService externalMapService,
    String? href,
  ) async {
    if (href == null || href.trim().isEmpty) return;

    final uri = Uri.tryParse(href.trim());
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tautan tidak didukung atau tidak aman untuk dibuka.',
            ),
          ),
        );
      }
      return;
    }

    final launched = await externalMapService.openExternalUrl(href);
    if (!context.mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuka tautan referensi di browser.'),
        ),
      );
    }
  }

  Future<void> _handleToggleBookmark(
    BuildContext context,
    String materialId,
    bool currentlyBookmarked,
  ) async {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masuk (login) untuk menyimpan bookmark.'),
        ),
      );
      context.push(RouteNames.loginPath);
      return;
    }

    final success = await ref
        .read(bookmarkControllerProvider.notifier)
        .toggleMaterial(materialId);

    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentlyBookmarked
                ? 'Materi dihapus dari Bookmark.'
                : 'Materi disimpan ke Bookmark.',
          ),
        ),
      );
      if (!currentlyBookmarked) {
        try {
          final award = await ref
              .read(achievementRepositoryProvider)
              .evaluateAchievements();
          ref.invalidate(achievementsListProvider);
          if (context.mounted && award.newlyAwardedTitles.isNotEmpty) {
            await showAchievementUnlockDialog(
              context,
              badgeTitles: award.newlyAwardedTitles,
            );
          }
        } catch (_) {}
      }
    } else {
      final err = ref.read(bookmarkControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err?.toString() ?? 'Gagal memperbarui bookmark.'),
        ),
      );
    }
  }

  void _openEnergyComparison(BuildContext context, String categorySlug) {
    if (categorySlug.isNotEmpty) {
      context.push('${RouteNames.energyComparisonPath}?category=$categorySlug');
    } else {
      context.push(RouteNames.energyComparisonPath);
    }
  }

  ({String question, String answer}) _flashcardForMaterial(
    LearningMaterial material,
  ) {
    final matSlug = material.slug.toLowerCase().trim();
    if (matSlug.contains('transisi-energi')) {
      return (
        question:
            'Mengapa evaluasi dampak lingkungan pembangkit listrik modern menggunakan pendekatan Analisis Siklus Hidup (LCA)?',
        answer:
            'Karena meskipun pembangkit EBT hampir bebas emisi saat beroperasi, proses penambangan material, pembuatan komponen, penggunaan lahan, dan daur ulang limbah tetap menimbulkan jejak ekologis yang harus dikelola.',
      );
    }
    if (matSlug.contains('baseload-vs-intermiten')) {
      return (
        question:
            'Apa perbedaan peran PLTP (beban dasar/baseload), PLTA waduk (penyeimbang), dan PLTS/PLTB (intermiten/VRE) di jaringan listrik?',
        answer:
            'PLTP beroperasi stabil 24 jam sebagai tulang punggung beban dasar, PLTA waduk merespons cepat saat lonjakan beban sore hari, sedangkan keluaran PLTS/PLTB mengikuti cuaca matahari dan angin.',
      );
    }
    if (matSlug.contains('penyimpanan-energi') || matSlug.contains('bess')) {
      return (
        question:
            'Apa fungsi utama sistem BESS dan PLTA Pumped Storage ketika dipadukan dengan PLTS atau PLTB?',
        answer:
            'Menyimpan surplus energi saat matahari terik atau angin kencang, lalu melepaskannya kembali saat beban puncak malam atau cuaca mendung untuk meredam intermitensi (VRE).',
      );
    }
    if (matSlug.contains('smart-grid')) {
      return (
        question:
            'Apa keuntungan sistem Microgrid Hibrida Surya–Baterai pada program Dedieselisasi di pulau-pulau terluar Indonesia?',
        answer:
            'Mengurangi ketergantungan pengiriman BBM solar lintas laut yang mahal dan beremisi tinggi dengan mengoptimalkan pembangkit surya lokal dan baterai pintar.',
      );
    }

    switch (material.categorySlug?.toLowerCase().trim()) {
      case 'solar':
        return (
          question:
              'Mengapa arus listrik dari modul surya harus melewati Inverter sebelum masuk ke jaringan rumah/PLN?',
          answer:
              'Karena sel fotovoltaik membangkitkan arus searah (DC), sedangkan jaringan listrik PLN dan peralatan rumah tangga beroperasi menggunakan arus bolak-balik (AC).',
        );
      case 'hydro':
        return (
          question:
              'Apa keunggulan utama PLTA berwaduk (reservoir) saat disandingkan dengan pembangkit surya atau angin?',
          answer:
              'Debit air dari waduk dapat diatur buka-tutupnya dengan sangat cepat sehingga mampu menstabilkan frekuensi jaringan ketika cuaca mendung atau beban malam melonjak.',
        );
      case 'wind':
        return (
          question:
              'Bagaimana cara sistem Pitch Control melindungi turbin angin saat terjadi angin badai?',
          answer:
              'Dengan memutar sudut kemiringan bilah (feathering) agar tidak menangkap gaya angkat berlebih sehingga putaran rotor tetap berada di batas aman.',
        );
      case 'geothermal':
        return (
          question:
              'Mengapa air kondensat dan brine pada PLTP wajib diinjeksikan kembali melalui sumur injeksi?',
          answer:
              'Untuk menjaga tekanan hidrotermal dan cadangan fluida di dalam reservoar bawah bumi agar pembangkit tetap lestari dalam jangka panjang.',
        );
      case 'bioenergy':
        return (
          question:
              'Apa perbedaan bahan baku dan proses antara PLTBm dan PLTBg?',
          answer:
              'PLTBm mengolah biomassa padat melalui pembakaran boiler/gasifikasi, sedangkan PLTBg memfermentasi limbah organik cair tanpa oksigen (anaerobik) menjadi gas metana.',
        );
      default:
        return (
          question:
              'Apa perbedaan mendasar antara pembangkit beban dasar (baseload) dan pembangkit intermiten (VRE)?',
          answer:
              'Pembangkit baseload (seperti PLTP) menyuplai daya stabil 24 jam, sedangkan pembangkit VRE (seperti PLTS & PLTB) berfluktuasi mengikuti kondisi cuaca alami.',
        );
    }
  }

  ({
    String label,
    IconData icon,
    Color softBg,
    Color fgColor,
  }) _topicMetaForMaterial(LearningMaterial material) {
    final slug = material.slug.toLowerCase().trim();
    if (slug.contains('transisi-energi')) {
      return (
        label: 'Transisi & Dampak 5 EBT',
        icon: Icons.balance_rounded,
        softBg: AppColors.mintGreen,
        fgColor: AppColors.actionGreen,
      );
    }
    if (slug.contains('baseload-vs-intermiten')) {
      return (
        label: 'Baseload vs VRE',
        icon: Icons.timeline_rounded,
        softBg: const Color(0xFFE0F2FE),
        fgColor: const Color(0xFF0369A1),
      );
    }
    if (slug.contains('penyimpanan-energi') || slug.contains('bess')) {
      return (
        label: 'BESS & Pumped Storage',
        icon: Icons.battery_charging_full_rounded,
        softBg: const Color(0xFFE0F2FE),
        fgColor: const Color(0xFF0E7490),
      );
    }
    if (slug.contains('smart-grid')) {
      return (
        label: 'Smart Grid Kepulauan',
        icon: Icons.hub_rounded,
        softBg: const Color(0xFFFEF9C3),
        fgColor: AppColors.warningFg,
      );
    }

    final catSlug = material.categorySlug ?? '';
    return (
      label: shortDisplayLabelForSlug(catSlug, 'Energi Bersih'),
      icon: iconForCategorySlug(catSlug),
      softBg: AppColors.softBackgroundForCategorySlug(catSlug),
      fgColor: AppColors.foregroundColorForCategorySlug(catSlug),
    );
  }

  @override
  Widget build(BuildContext context) {
    final materialAsync = ref.watch(
      learningMaterialDetailProvider(widget.materialSlug),
    );
    final externalMapService = ref.watch(externalMapServiceProvider);
    final bookmarkController = ref.watch(bookmarkControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        bottom: false,
        child: materialAsync.when(
          loading: () => const Column(
            children: [
              ScreenHeaderBar(
                title: 'Materi Pembelajaran',
                subtitle: 'Memuat modul...',
              ),
              Expanded(
                child: LoadingView(
                  message: 'Memuat isi materi pembelajaran...',
                ),
              ),
            ],
          ),
          error: (error, _) => Column(
            children: [
              const ScreenHeaderBar(
                title: 'Materi Pembelajaran',
                subtitle: 'Gagal memuat materi',
              ),
              Expanded(
                child: ErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(
                    learningMaterialDetailProvider(widget.materialSlug),
                  ),
                ),
              ),
            ],
          ),
          data: (material) {
            if (material.contentMd.trim().isEmpty) {
              return Column(
                children: [
                  ScreenHeaderBar(
                    title: material.title,
                    subtitle: 'Konten belum tersedia',
                  ),
                  Expanded(
                    child: EmptyView(
                      title: 'Konten Materi Kosong',
                      description:
                          'Isi materi pembelajaran ini belum ditulis pada database.',
                      actionLabel: 'Kembali',
                      onAction: () => context.pop(),
                    ),
                  ),
                ],
              );
            }

            final topicMeta = _topicMetaForMaterial(material);
            final flashcard = _flashcardForMaterial(material);
            final parsed = LearningMaterialParser.parse(material.contentMd);
            final markdownStyleSheet = _buildMarkdownStyleSheet();
            final isBookmarked = ref.watch(
              isMaterialBookmarkedProvider(material.id),
            );
            final isGuestSession = ref.watch(isGuestSessionProvider);
            final readingState = ref.watch(readingProgressProvider);

            final effectiveProgress = math
                .max(
                  _readingProgress,
                  isGuestSession ? 0.0 : readingState.progressFor(material.slug),
                )
                .clamp(0.05, 1.0);
            final percentRead = (effectiveProgress * 100).round();
            final savedOffset =
                isGuestSession ? 0.0 : readingState.lastOffsetFor(material.slug);
            final canResumeOffset =
                !isGuestSession && savedOffset > 140 && !_hasDismissedResumeBanner;

            final slugLower = material.slug.toLowerCase().trim();
            final isCrossFiveCategory =
                slugLower.contains('transisi-energi') ||
                slugLower.contains('baseload-vs-intermiten');

            final navItems = <MaterialNavItem>[];
            final sectionWidgets = <Widget>[];

            // 1. Kartu Hero Editorial (identitas topik, chip, ringkasan, indikator tamu)
            sectionWidgets.add(
              MaterialEditorialHeroCard(
                material: material,
                topicLabel: topicMeta.label,
                topicIcon: topicMeta.icon,
                softCategoryBg: topicMeta.softBg,
                iconColor: topicMeta.fgColor,
                isGuestSession: isGuestSession,
                onLoginTap: () => context.push(RouteNames.loginPath),
              ),
            );

            // 2. Callout Intisari Konsep (hijau hutan)
            if (parsed.keyTakeaway != null &&
                parsed.keyTakeaway!.trim().isNotEmpty) {
              sectionWidgets.add(const SizedBox(height: 16));
              sectionWidgets.add(
                MaterialTakeawayCallout(
                  takeawayMd: parsed.keyTakeaway!,
                  markdownStyleSheet: markdownStyleSheet,
                ),
              );
            }

            // 3. Paragraf Pembuka (tanpa box ganda di atas kanvas editorial)
            if (parsed.introMd != null && parsed.introMd!.trim().isNotEmpty) {
              sectionWidgets.add(const SizedBox(height: 18));
              sectionWidgets.add(
                MarkdownBody(
                  data: parsed.introMd!,
                  selectable: true,
                  onTapLink: (_, href, _) =>
                      _handleOpenLink(context, externalMapService, href),
                  styleSheet: markdownStyleSheet,
                ),
              );
            }

            // Siapkan blok simulasi / eksplorasi interaktif
            final flowKey = _keyForSection('interactive_flow');
            final flowNavItem = MaterialNavItem(
              id: 'interactive_flow',
              label: isCrossFiveCategory ? '5 EBT' : 'Simulasi',
              sectionKey: flowKey,
            );
            final flowWidget = Container(
              key: flowKey,
              child: isCrossFiveCategory
                  ? _buildInteractiveConceptExplorer(material: material)
                  : MaterialFlowStepperCard(
                      stages: _stagesForMaterial(material),
                      selectedIndex: _selectedExplorerIndex,
                      onSelectIndex: (idx) =>
                          setState(() => _selectedExplorerIndex = idx),
                    ),
            );

            // Jika materi belum memakai heading "## Bagian", tetap sisipkan simulasi
            if (parsed.chapters.isEmpty) {
              navItems.add(flowNavItem);
              sectionWidgets.add(const SizedBox(height: 22));
              sectionWidgets.add(flowWidget);
            }

            // 4. Bagian Bernomor + Blok Interaktif Terstruktur
            var hasRenderedProCon = false;
            for (var i = 0; i < parsed.chapters.length; i++) {
              final chapter = parsed.chapters[i];
              final chapterId = 'ch_$i';
              final chapterKey = _keyForSection(chapterId);

              navItems.add(
                MaterialNavItem(
                  id: chapterId,
                  label: chapter.navLabel,
                  sectionKey: chapterKey,
                ),
              );

              if (chapter.proConPair != null) {
                hasRenderedProCon = true;
              }

              sectionWidgets.add(const SizedBox(height: 26));
              sectionWidgets.add(
                Container(
                  key: chapterKey,
                  child: _buildEditorialChapterSection(
                    context: context,
                    chapter: chapter,
                    softCategoryBg: topicMeta.softBg,
                    iconColor: topicMeta.fgColor,
                    markdownStyleSheet: markdownStyleSheet,
                    externalMapService: externalMapService,
                    categorySlug: material.categorySlug?.trim() ?? '',
                  ),
                ),
              );

              // Sisipkan simulasi alur sistem tepat setelah Bagian 1
              if (i == 0) {
                navItems.add(flowNavItem);
                sectionWidgets.add(const SizedBox(height: 20));
                sectionWidgets.add(flowWidget);
              }
            }

            // 5. Contoh Pembangkit Nyata di Indonesia (Learn -> Explore & Impact)
            final plantsKey = _keyForSection('plants');
            navItems.add(
              MaterialNavItem(
                id: 'plants',
                label: 'Pembangkit',
                sectionKey: plantsKey,
              ),
            );
            sectionWidgets.add(const SizedBox(height: 26));
            sectionWidgets.add(
              Container(
                key: plantsKey,
                child: _buildRelevantPlantsSection(
                  context: context,
                  material: material,
                  showCompareFallback: !hasRenderedProCon,
                ),
              ),
            );

            // 6. Kartu Flashcard Flip 3D (Uji Kilat Pemahamanmu)
            final flashKey = _keyForSection('flashcard');
            navItems.add(
              MaterialNavItem(
                id: 'flashcard',
                label: 'Flashcard',
                sectionKey: flashKey,
              ),
            );
            sectionWidgets.add(const SizedBox(height: 26));
            sectionWidgets.add(
              Container(
                key: flashKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionEyebrow('UJI KILAT'),
                    const SizedBox(height: 4),
                    Text(
                      'Uji kilat pemahamanmu',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 19,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    MaterialFlipFlashcard(
                      question: flashcard.question,
                      answer: flashcard.answer,
                    ),
                  ],
                ),
              ),
            );

            // 7. Referensi & Bacaan Lanjutan (jika tersedia)
            if (parsed.references.isNotEmpty) {
              final refsKey = _keyForSection('refs');
              navItems.add(
                MaterialNavItem(
                  id: 'refs',
                  label: 'Referensi',
                  sectionKey: refsKey,
                ),
              );
              sectionWidgets.add(const SizedBox(height: 26));
              sectionWidgets.add(
                Container(
                  key: refsKey,
                  child: _buildReferencesSection(
                    context: context,
                    heading: parsed.referencesHeading,
                    references: parsed.references,
                    externalMapService: externalMapService,
                  ),
                ),
              );
            }

            // 8. Kartu Ajakan ke Kuis Interaktif (Learn -> Evaluate)
            final quizKey = _keyForSection('quiz');
            navItems.add(
              MaterialNavItem(
                id: 'quiz',
                label: 'Kuis',
                sectionKey: quizKey,
              ),
            );
            sectionWidgets.add(const SizedBox(height: 26));
            sectionWidgets.add(
              Container(
                key: quizKey,
                child: _buildQuizRecommendationCard(
                  context: context,
                  material: material,
                ),
              ),
            );

            _currentNavItems = navItems;
            for (final item in navItems) {
              _keyForNavItem(item.id);
            }
            final activeNavId = (_activeNavId != null &&
                    navItems.any((item) => item.id == _activeNavId))
                ? _activeNavId
                : (navItems.isNotEmpty ? navItems.first.id : null);

            return Column(
              children: [
                MaterialTopHeaderBar(
                  title: material.title,
                  categoryLabel: topicMeta.label,
                  isBookmarked: isBookmarked,
                  isBookmarkBusy: bookmarkController.isLoading,
                  onBack: () => context.pop(),
                  onToggleBookmark: () => _handleToggleBookmark(
                    context,
                    material.id,
                    isBookmarked,
                  ),
                  progressFraction: effectiveProgress,
                  navItems: navItems,
                  activeNavId: activeNavId,
                  navItemKeys: _navItemKeys,
                  onSelectNav: _scrollToNavItem,
                  resumePercent: canResumeOffset ? percentRead : null,
                  onResumeOffset: canResumeOffset
                      ? () => _resumeLastScrollOffset(savedOffset)
                      : null,
                ),
                Expanded(
                  key: _viewportKey,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: sectionWidgets,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionEyebrow(String text) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.caption.copyWith(
        color: AppColors.actionGreen,
        fontWeight: FontWeight.w800,
        fontSize: 11,
        letterSpacing: 0.7,
      ),
    );
  }

  Widget _buildEditorialChapterSection({
    required BuildContext context,
    required MaterialChapterContent chapter,
    required Color softCategoryBg,
    required Color iconColor,
    required MarkdownStyleSheet markdownStyleSheet,
    required ExternalMapService externalMapService,
    required String categorySlug,
  }) {
    final hasStructuredBlocks = chapter.table != null ||
        chapter.segmentedTabs.isNotEmpty ||
        chapter.proConPair != null;

    final leadText = (chapter.leadMd != null && chapter.leadMd!.trim().isNotEmpty)
        ? chapter.leadMd!
        : (!hasStructuredBlocks && chapter.rawBodyMd.trim().isNotEmpty
            ? chapter.rawBodyMd
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionEyebrow(chapter.numberLabel),
        const SizedBox(height: 4),
        Text(
          chapter.title,
          style: AppTextStyles.title.copyWith(
            fontSize: 20,
            color: AppColors.forestGreen,
            height: 1.25,
          ),
        ),
        if (leadText != null) ...[
          const SizedBox(height: 10),
          MarkdownBody(
            data: leadText,
            selectable: true,
            onTapLink: (_, href, _) =>
                _handleOpenLink(context, externalMapService, href),
            styleSheet: markdownStyleSheet,
          ),
        ],
        if (chapter.table != null) ...[
          const SizedBox(height: 12),
          MaterialTableCardsSection(
            table: chapter.table!,
            softCategoryBg: softCategoryBg,
            iconColor: iconColor,
          ),
        ],
        if (chapter.afterTableMd != null &&
            chapter.afterTableMd!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          MarkdownBody(
            data: chapter.afterTableMd!,
            selectable: true,
            onTapLink: (_, href, _) =>
                _handleOpenLink(context, externalMapService, href),
            styleSheet: markdownStyleSheet,
          ),
        ],
        if (chapter.segmentedTabs.isNotEmpty) ...[
          const SizedBox(height: 12),
          MaterialSegmentedTabsCard(
            tabs: chapter.segmentedTabs,
            markdownStyleSheet: markdownStyleSheet,
            onTapLink: (_, href, _) =>
                _handleOpenLink(context, externalMapService, href),
          ),
        ],
        if (chapter.proConPair != null) ...[
          const SizedBox(height: 12),
          MaterialProConSection(
            pair: chapter.proConPair!,
            markdownStyleSheet: markdownStyleSheet,
            onComparePressed: () => _openEnergyComparison(context, categorySlug),
          ),
          if (chapter.proConPair!.extraMd != null &&
              chapter.proConPair!.extraMd!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            MarkdownBody(
              data: chapter.proConPair!.extraMd!,
              selectable: true,
              onTapLink: (_, href, _) =>
                  _handleOpenLink(context, externalMapService, href),
              styleSheet: markdownStyleSheet,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildRelevantPlantsSection({
    required BuildContext context,
    required LearningMaterial material,
    required bool showCompareFallback,
  }) {
    final plantsAsync = ref.watch(allPlantsListProvider);
    final relevantPlants = plantsAsync.maybeWhen(
      data: (plants) =>
          LearningIntegrationHelper.selectRelevantPlantsForMaterial(
            material: material,
            allPlants: plants,
            maxCount: 3,
          ),
      orElse: () => const <PowerPlant>[],
    );

    final categorySlug = material.categorySlug?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionEyebrow('DI INDONESIA'),
        const SizedBox(height: 4),
        Text(
          'Contoh Pembangkit Tercatat',
          style: AppTextStyles.title.copyWith(
            fontSize: 19,
            color: AppColors.forestGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Lihat penerapan nyata materi ini pada titik pembangkit yang tercatat di Indonesia:',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        if (plantsAsync.isLoading && relevantPlants.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              'Memuat contoh pembangkit terkait...',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else if (relevantPlants.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              'Belum ada titik pembangkit tercatat khusus untuk topik ini.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          ...relevantPlants.map(
            (plant) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MaterialPlantLinkTile(
                plant: plant,
                onTap: () => context.push('/plants/${plant.id}'),
              ),
            ),
          ),
        if (showCompareFallback) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                foregroundColor: AppColors.forestGreen,
                side: const BorderSide(color: AppColors.sageGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _openEnergyComparison(context, categorySlug),
              icon: const Icon(Icons.compare_arrows_rounded, size: 18),
              label: const Text('Bandingkan dengan energi lain'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReferencesSection({
    required BuildContext context,
    required String heading,
    required List<MaterialReferenceItem> references,
    required ExternalMapService externalMapService,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionEyebrow('SUMBER & BACAAN'),
        const SizedBox(height: 4),
        Text(
          heading,
          style: AppTextStyles.title.copyWith(
            fontSize: 19,
            color: AppColors.forestGreen,
          ),
        ),
        const SizedBox(height: 12),
        ...references.map((item) {
          final isClickable = item.isLink && item.url != null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: isClickable
                    ? () => _handleOpenLink(
                        context,
                        externalMapService,
                        item.url,
                      )
                    : null,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isClickable
                              ? AppColors.mintGreen
                              : AppColors.offWhite,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isClickable
                              ? Icons.open_in_new_rounded
                              : Icons.menu_book_outlined,
                          size: 17,
                          color: AppColors.forestGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 13.5,
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (item.subtitle != null &&
                                item.subtitle!.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle!,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isClickable) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuizRecommendationCard({
    required BuildContext context,
    required LearningMaterial material,
  }) {
    final recommendationAsync = ref.watch(
      recommendedQuizForMaterialProvider(material),
    );
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return recommendationAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => MaterialQuizCtaCard(
        headline: 'Siap Uji Wawasanmu?',
        subtitle:
            'Uji pemahamanmu mengenai energi terbarukan lewat paket kuis interaktif.',
        primaryLabel: 'Buka Daftar Kuis Interaktif',
        primaryIcon: Icons.quiz_rounded,
        onPrimaryTap: () => context.go(RouteNames.quizPath),
        onAllQuizzesTap: () => context.go(RouteNames.quizPath),
      ),
      data: (recommendation) {
        final quiz = recommendation.quiz;
        final hasDirectQuiz = recommendation.isDirectTopicMatch && quiz != null;

        final headline = hasDirectQuiz
            ? 'Uji Pemahaman Materi Ini'
            : 'Siap Uji Wawasanmu?';
        final subtitle = hasDirectQuiz
            ? '${quiz.title} — ${recommendation.reasonLabel}'
            : recommendation.reasonLabel;
        final primaryLabel = hasDirectQuiz
            ? (isAuthenticated
                ? 'Mulai Kuis Topik Ini'
                : 'Masuk untuk Mulai Kuis')
            : 'Lihat Semua Tantangan Kuis';
        final primaryIcon = (hasDirectQuiz && !isAuthenticated)
            ? Icons.login_rounded
            : Icons.quiz_rounded;

        return MaterialQuizCtaCard(
          headline: headline,
          subtitle: subtitle,
          primaryLabel: primaryLabel,
          primaryIcon: primaryIcon,
          onPrimaryTap: () {
            if (hasDirectQuiz) {
              if (!isAuthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Silakan masuk (login) terlebih dahulu untuk mengerjakan kuis.',
                    ),
                  ),
                );
                context.push(RouteNames.loginPath);
                return;
              }
              context.push('/quiz/${quiz.id}/play');
            } else {
              context.go(RouteNames.quizPath);
            }
          },
          onAllQuizzesTap: () => context.go(RouteNames.quizPath),
        );
      },
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet() {
    return MarkdownStyleSheet(
      h1: AppTextStyles.display.copyWith(fontSize: 20),
      h2: AppTextStyles.title.copyWith(
        fontSize: 18,
        color: AppColors.forestGreen,
      ),
      h3: AppTextStyles.subtitle.copyWith(
        fontSize: 15,
        color: AppColors.forestGreen,
      ),
      p: AppTextStyles.body.copyWith(
        fontSize: 15,
        height: 1.65,
        color: AppColors.forestGreen,
      ),
      listBullet: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.actionGreen,
        fontWeight: FontWeight.w700,
      ),
      strong: AppTextStyles.bodyMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.forestGreen,
      ),
      blockquotePadding: const EdgeInsets.all(14),
      blockquoteDecoration: BoxDecoration(
        color: AppColors.mintGreen.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: AppColors.actionGreen, width: 4),
        ),
      ),
      tableHead: AppTextStyles.caption.copyWith(
        color: AppColors.forestGreen,
        fontWeight: FontWeight.w800,
      ),
      tableBody: AppTextStyles.caption.copyWith(
        color: AppColors.textPrimary,
        height: 1.4,
      ),
      tableCellsPadding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      tableBorder: TableBorder.all(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(10),
      ),
      a: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.skyBlue,
        decoration: TextDecoration.underline,
      ),
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      blockSpacing: 12,
    );
  }

  Widget _buildInteractiveConceptExplorer({
    required LearningMaterial material,
  }) {
    const ebtItems = <({
      String label,
      IconData icon,
      String categorySlug,
      String supplyRole,
      String regionPotential,
      String benefit,
      String challenge,
    })>[
      (
        label: 'Surya (PLTS)',
        icon: Icons.wb_sunny_rounded,
        categorySlug: 'solar',
        supplyRole: 'Intermiten Siang Hari (VRE)',
        regionPotential: 'Nusa Tenggara, Bali, Jawa, & Kalimantan',
        benefit:
            'Emisi operasional nyaris nol & modular (bisa di atap maupun terapung di waduk).',
        challenge:
            'Hanya aktif siang hari, butuh lahan/permukaan luas & pengelolaan limbah panel di akhir masa pakai.',
      ),
      (
        label: 'Air (PLTA)',
        icon: Icons.water_drop_rounded,
        categorySlug: 'hydro',
        supplyRole: 'Penyeimbang Fleksibel & Beban Puncak',
        regionPotential: 'Pegunungan Sumatera, Jawa Barat, & Sulawesi',
        benefit:
            'Mampu merespons lonjakan beban dengan cepat & bendungan berfungsi ganda untuk irigasi.',
        challenge:
            'Waduk skala besar mengubah ekosistem sungai serta rentan sedimentasi dan kemarau panjang.',
      ),
      (
        label: 'Angin (PLTB)',
        icon: Icons.air_rounded,
        categorySlug: 'wind',
        supplyRole: 'Intermiten Musiman (VRE)',
        regionPotential: 'Pesisir Selatan Sulawesi, NTT, & Selatan Jawa',
        benefit:
            'Tidak membutuhkan bahan bakar maupun air pendingin; lahan bawah menara tetap bisa dipakai tani/ternak.',
        challenge:
            'Kecepatan angin musiman berubah-ubah, deru mekanis bilah, dan risiko jalur burung lokal.',
      ),
      (
        label: 'Panas Bumi (PLTP)',
        icon: Icons.local_fire_department_rounded,
        categorySlug: 'geothermal',
        supplyRole: 'Beban Dasar Stabil 24 Jam (Baseload)',
        regionPotential: 'Jalur Cincin Api Sumatera, Jawa, Bali, Flores, Sulut',
        benefit:
            'Menyuplai listrik stabil 24 jam penuh tanpa terpengaruh cuaca dengan jejak lahan permukaan ringkas.',
        challenge:
            'Berada di lereng gunung/hutan lindung, butuh reinjeksi brine disiplin & investasi eksplorasi tinggi.',
      ),
      (
        label: 'Bioenergi (PLTBm)',
        icon: Icons.eco_rounded,
        categorySlug: 'bioenergy',
        supplyRole: 'Terkendali (Dispatchable) & Ekonomi Sirkular',
        regionPotential: 'Sentra Agroindustri Sumatera, Kalimantan, & Jawa',
        benefit:
            'Mengubah limbah organik agroindustri menjadi energi sekaligus menekan pelepasan metana.',
        challenge:
            'Kontinuitas pasokan bahan baku musiman & wajib menyaring emisi partikulat pembakaran.',
      ),
    ];

    final safeIdx = _selectedExplorerIndex.clamp(0, ebtItems.length - 1);
    final selected = ebtItems[safeIdx];
    final selectedSoftBg = AppColors.softBackgroundForCategorySlug(
      selected.categorySlug,
    );
    final selectedFg = AppColors.foregroundColorForCategorySlug(
      selected.categorySlug,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.mintGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.touch_app_rounded,
                  size: 18,
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eksplorasi Interaktif: 5 Energi Terbarukan',
                      style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                    ),
                    Text(
                      'Ketuk tiap jenis energi untuk membandingkan peran & trade-off lingkungannya:',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(ebtItems.length, (index) {
                final item = ebtItems[index];
                final isSelected = index == safeIdx;
                final itemFg = AppColors.foregroundColorForCategorySlug(
                  item.categorySlug,
                );
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    onTap: () =>
                        setState(() => _selectedExplorerIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      constraints: const BoxConstraints(minHeight: 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.forestGreen
                            : AppColors.offWhite,
                        borderRadius: BorderRadius.circular(
                          AppTheme.pillRadius,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.forestGreen
                              : AppColors.divider,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            size: 15,
                            color: isSelected ? AppColors.surfaceWhite : itemFg,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.label,
                            style: AppTextStyles.caption.copyWith(
                              color: isSelected
                                  ? AppColors.surfaceWhite
                                  : AppColors.forestGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Container(
              key: ValueKey<int>(safeIdx),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selectedSoftBg.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selectedFg.withValues(alpha: 0.28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded, size: 13, color: selectedFg),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Peran: ${selected.supplyRole}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.forestGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: selectedFg,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Wilayah: ${selected.regionPotential}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.forestGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: AppColors.actionGreen,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Manfaat: ${selected.benefit}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 12.5,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.warningFg.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: AppColors.warningFg,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tantangan Lokal: ${selected.challenge}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 12.5,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<MaterialWorkflowStage> _stagesForMaterial(LearningMaterial material) {
    final slug = material.slug.toLowerCase().trim();
    if (slug.contains('penyimpanan-energi') || slug.contains('bess')) {
      return const [
        (
          shortTitle: 'Surplus Siang',
          icon: Icons.wb_sunny_rounded,
          headline: 'Tahap 1 — Penyerapan Surplus Daya (Charging / Pumping)',
          detail:
              'Saat produksi PLTS/PLTB melimpah di siang hari, kelebihan listrik disimpan ke baterai LiFePO4 (BESS) atau dipakai memompa air dari waduk bawah ke waduk atas (Pumped Storage).',
          tag: 'Energi Surplus',
        ),
        (
          shortTitle: 'Penyimpanan',
          icon: Icons.battery_charging_full_rounded,
          headline: 'Tahap 2 — Cadangan Energi Siaga Berkapasitas Besar',
          detail:
              'Energi tersimpan sebagai energi elektrokimia di dalam modul baterai atau energi potensial gravitasi air di reservoar atas dengan efisiensi siklus 75–90%.',
          tag: 'Efisiensi 75–90%',
        ),
        (
          shortTitle: 'Beban Puncak',
          icon: Icons.bolt_rounded,
          headline: 'Tahap 3 — Pelepasan Cepat Saat Beban Puncak Malam',
          detail:
              'Saat matahari terbenam dan konsumsi listrik rumah tangga melonjak (18.00–22.00), sistem melepaskan daya dalam hitungan milidetik hingga menit untuk menjaga kestabilan frekuensi jaringan.',
          tag: 'Puncak 18.00–22.00',
        ),
      ];
    }
    if (slug.contains('smart-grid')) {
      return const [
        (
          shortTitle: 'Pembangkit Lokal',
          icon: Icons.solar_power_rounded,
          headline: 'Tahap 1 — Integrasi Pembangkit Terbarukan Kepulauan',
          detail:
              'PLTS Hibrida, mikrohidro, atau turbin angin lokal membangkitkan listrik bersih langsung di pulau setempat tanpa menunggu pengiriman kapal tanker BBM solar.',
          tag: 'Sumber Lokal',
        ),
        (
          shortTitle: 'Kendali EMS',
          icon: Icons.memory_rounded,
          headline: 'Tahap 2 — Penyeimbangan Otomatis Smart Microgrid',
          detail:
              'Energy Management System (EMS) dan sensor digital memantau cuaca serta beban pulau secara real-time, mengatur kapan daya masuk ke baterai dan kapan disalurkan ke warga.',
          tag: 'Kontrol Real-Time',
        ),
        (
          shortTitle: 'Listrik 24 Jam',
          icon: Icons.home_work_rounded,
          headline: 'Tahap 3 — Kemandirian Energi Sekolah, Puskesmas, & UMKM',
          detail:
              'Masyarakat kepulauan menikmati listrik bersih 24 jam yang andal dengan biaya pokok penyediaan dan emisi karbon yang jauh lebih rendah dibanding PLTD murni.',
          tag: 'Akses 24 Jam',
        ),
      ];
    }

    switch (material.categorySlug?.toLowerCase().trim()) {
      case 'solar':
        return const [
          (
            shortTitle: 'Efek PV',
            icon: Icons.wb_sunny_rounded,
            headline: 'Tahap 1 — Penangkapan Foton pada Sel Silikon (DC)',
            detail:
                'Foton cahaya matahari menumbuk sambungan semikonduktor P-N pada panel surya, memicu aliran elektron searah (arus DC) tanpa bagian mesin yang berputar.',
            tag: 'Arus DC Murni',
          ),
          (
            shortTitle: 'Inverter AC',
            icon: Icons.sync_alt_rounded,
            headline: 'Tahap 2 — Konversi DC ke AC & Optimasi MPPT',
            detail:
                'Inverter mengubah arus searah (DC) menjadi arus bolak-balik (AC) yang sinkron dengan frekuensi jaringan 50 Hz sekaligus mengoptimalkan titik daya maksimum.',
            tag: 'Sinkron 50 Hz',
          ),
          (
            shortTitle: 'Jaringan PLN',
            icon: Icons.electrical_services_rounded,
            headline: 'Tahap 3 — Suplai Siang Hari & Mitigasi Intermitensi',
            detail:
                'Listrik disalurkan ke beban siang hari; saat awan melintas atau malam tiba, sistem dikombinasikan dengan PLTA waduk atau baterai BESS agar tegangan tetap stabil.',
            tag: 'Beban Siang',
          ),
        ];
      case 'hydro':
        return const [
          (
            shortTitle: 'Tinggi Jatuh',
            icon: Icons.water_rounded,
            headline: 'Tahap 1 — Energi Potensial Air (Head & Debit)',
            detail:
                'Air sungai atau waduk pada ketinggian tertentu dialirkan melalui pipa pesat (penstock) bertekanan tinggi menuju rumah pembangkit.',
            tag: 'Tekanan Penstock',
          ),
          (
            shortTitle: 'Turbin Air',
            icon: Icons.cyclone_rounded,
            headline: 'Tahap 2 — Putaran Turbin Francis/Pelton & Generator',
            detail:
                'Dorongan air memutar sudu turbin yang terhubung dengan poros generator elektromagnetik dengan efisiensi konversi mencapai 85–90%.',
            tag: 'Efisiensi 85–90%',
          ),
          (
            shortTitle: 'Penyeimbang',
            icon: Icons.balance_rounded,
            headline: 'Tahap 3 — Penopang Fleksibel Jaringan & Beban Puncak',
            detail:
                'Debit air dapat diatur dengan cepat sehingga PLTA waduk menjadi tulang punggung penyeimbang saat pembangkit surya/angin mengalami fluktuasi cuaca.',
            tag: 'Respon Cepat',
          ),
        ];
      case 'wind':
        return const [
          (
            shortTitle: 'Gaya Angkat',
            icon: Icons.air_rounded,
            headline: 'Tahap 1 — Aerodinamika Bilah Rotor & Sistem Yaw',
            detail:
                'Hembusan angin di pesisir/perbukitan (>6 m/s) melewati profil aerodinamis bilah turbin, menciptakan gaya angkat (lift) yang memutar rotor utama.',
            tag: 'Angin > 6 m/s',
          ),
          (
            shortTitle: 'Nacelle',
            icon: Icons.settings_suggest_rounded,
            headline: 'Tahap 2 — Gearbox / Direct-Drive & Pitch Control',
            detail:
                'Di dalam rumah turbin (nacelle), putaran rotor menggerakkan generator listrik, sementara sistem Pitch Control menjaga kecepatan tetap aman saat angin kencang.',
            tag: 'Kendali Pitch',
          ),
          (
            shortTitle: 'Gardu Induk',
            icon: Icons.bolt_rounded,
            headline: 'Tahap 3 — Injeksi Daya Musiman ke Sistem Transmisi',
            detail:
                'Tegangan dinaikkan melalui transformator menuju jaringan transmisi regional (seperti sistem Sulawesi Bagian Selatan pada PLTB Sidrap & Jeneponto).',
            tag: 'Sistem Transmisi',
          ),
        ];
      case 'geothermal':
        return const [
          (
            shortTitle: 'Sumur Uap',
            icon: Icons.local_fire_department_rounded,
            headline: 'Tahap 1 — Ekstraksi Fluida Hidrotermal Bawah Bumi',
            detail:
                'Uap panas dan air bertekanan tinggi dari batuan reservoar vulkanik (1,5–3 km di bawah tanah) dialirkan melalui sumur produksi ke separator uap.',
            tag: 'Kedalaman 1,5–3 km',
          ),
          (
            shortTitle: 'Turbin Uap',
            icon: Icons.precision_manufacturing_rounded,
            headline: 'Tahap 2 — Ekspansi Turbin Uap & Siklus Binary ORC',
            detail:
                'Uap kering memutar turbin generator nonstop 24 jam, sementara sisa panas air brine dimanfaatkan kembali melalui fluida kerja bertitik didih rendah.',
            tag: 'Operasi 24 Jam',
          ),
          (
            shortTitle: 'Reinjeksi',
            icon: Icons.recycling_rounded,
            headline: 'Tahap 3 — Sumur Reinjeksi untuk Keberlanjutan Reservoar',
            detail:
                'Air kondensat dan brine wajib dipompakan kembali ke dalam perut bumi melalui sumur injeksi agar tekanan reservoar tetap lestari dan bebas pencemaran permukaan.',
            tag: 'Siklus Tertutup',
          ),
        ];
      default:
        return const [
          (
            shortTitle: 'Biomassa',
            icon: Icons.grass_rounded,
            headline: 'Tahap 1 — Pengumpulan Residu Pertanian & Limbah Organik',
            detail:
                'Cangkang sawit, sekam padi, tongkol jagung, atau limbah cair pabrik sawit (POME) dikumpulkan sebagai bahan baku energi sirkular.',
            tag: 'Ekonomi Sirkular',
          ),
          (
            shortTitle: 'Konversi',
            icon: Icons.science_rounded,
            headline: 'Tahap 2 — Termal (Boiler) atau Biokimia (Biogas Metana)',
            detail:
                'Biomassa padat dibakar/digasifikasi untuk menghasilkan uap (PLTBm), sedangkan limbah cair difermentasi bakteri anaerob menjadi gas metana CH4 (PLTBg).',
            tag: 'Termal / Anaerob',
          ),
          (
            shortTitle: 'Listrik Desa',
            icon: Icons.offline_bolt_rounded,
            headline: 'Tahap 3 — Listrik Terkendali & Reduksi Emisi Metana',
            detail:
                'Generator menyuplai listrik stabil bagi pabrik dan desa sekitar sekaligus mencegah pelepasan gas metana liar dari kolam limbah terbuka.',
            tag: 'Kendali Emisi',
          ),
        ];
    }
  }
}
