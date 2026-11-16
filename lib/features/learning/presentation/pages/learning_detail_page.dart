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
import '../../../../core/widgets/common/primary_button.dart';
import '../../../../core/widgets/common/screen_header.dart';
import '../../../../core/widgets/common/soft_image_placeholder.dart';
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
import '../providers/learning_providers.dart';
import '../providers/reading_progress_provider.dart';

/// Halaman Baca Materi Pembelajaran (Learning Detail) yang dilengkapi:
/// - Indikator progres baca persisten berbasis *high-water mark* (tidak turun ke 0% saat scroll ke atas)
/// - Tombol "Lanjutkan posisi terakhir" apabila pengguna pernah membaca sebagian materi
/// - Render Markdown kaya (tabel terformat, kutipan/callout berbingkai hijau)
/// - Kartu Flashcard interaktif ("Uji Kilat Konsep"), contoh pembangkit nyata, & ajakan kuis
class LearningDetailPage extends ConsumerStatefulWidget {
  const LearningDetailPage({super.key, required this.materialSlug});

  final String materialSlug;

  @override
  ConsumerState<LearningDetailPage> createState() => _LearningDetailPageState();
}

class _LearningDetailPageState extends ConsumerState<LearningDetailPage> {
  final ScrollController _scrollController = ScrollController();
  double _readingProgress = 0.0;
  bool _isFlashcardRevealed = false;
  bool _hasDismissedResumeBanner = false;
  int _selectedExplorerIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
      return;
    }

    final rawCurrent = (offset / maxScroll).clamp(0.0, 1.0);
    final current = rawCurrent >= 0.96 ? 1.0 : rawCurrent;
    final savedMax = isGuestSession
        ? 0.0
        : ref.read(readingProgressProvider).progressFor(widget.materialSlug);

    // High-water mark: progres hanya bisa bertambah, tidak pernah berkurang saat scroll ke atas
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

  Future<void> _resumeLastScrollOffset(double targetOffset) async {
    setState(() => _hasDismissedResumeBanner = true);
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final clampedTarget = targetOffset.clamp(0.0, maxScroll > 0 ? maxScroll : targetOffset);
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

  ({String label, IconData icon, Color color, String? assetPath})
  _topicMetaForMaterial(LearningMaterial material) {
    final slug = material.slug.toLowerCase().trim();
    if (slug.contains('transisi-energi')) {
      return (
        label: 'Transisi & Dampak 5 EBT',
        icon: Icons.balance_rounded,
        color: AppColors.freshGreen,
        assetPath: 'assets/images/mascot/eco_reading.png',
      );
    }
    if (slug.contains('baseload-vs-intermiten')) {
      return (
        label: 'Baseload vs VRE',
        icon: Icons.timeline_rounded,
        color: AppColors.skyBlue,
        assetPath: null,
      );
    }
    if (slug.contains('penyimpanan-energi') || slug.contains('bess')) {
      return (
        label: 'BESS & Pumped Storage',
        icon: Icons.battery_charging_full_rounded,
        color: AppColors.categoryHydro,
        assetPath: null,
      );
    }
    if (slug.contains('smart-grid')) {
      return (
        label: 'Smart Grid Kepulauan',
        icon: Icons.hub_rounded,
        color: AppColors.categorySolar,
        assetPath: null,
      );
    }

    final catSlug = material.categorySlug ?? '';
    return (
      label: shortDisplayLabelForSlug(catSlug, 'Energi Bersih'),
      icon: iconForCategorySlug(catSlug),
      color: AppColors.colorForCategorySlug(catSlug),
      assetPath: categoryAssetForSlug(catSlug) ??
          'assets/images/mascot/eco_reading.png',
    );
  }

  String? categoryAssetForSlug(String? slug) => null;

  ({
    String? keyTakeaway,
    String? introMd,
    List<({String numberLabel, String title, String bodyMd})> chapters,
  }) _parseMarkdownStructure(String rawMd) {
    final normalized = rawMd.replaceAll('\r\n', '\n').trim();
    final parts = normalized.split(RegExp(r'\n(?=##\s+)'));

    String? keyTakeaway;
    String? introMd;
    final chapters = <({String numberLabel, String title, String bodyMd})>[];

    for (var i = 0; i < parts.length; i++) {
      final chunk = parts[i].trim();
      if (chunk.isEmpty) continue;

      if (i == 0 && !chunk.startsWith('## ')) {
        final lines = chunk.split('\n');
        final quoteLines = <String>[];
        final otherLines = <String>[];

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('>')) {
            quoteLines.add(trimmed.replaceFirst(RegExp(r'^>\s*'), ''));
          } else {
            otherLines.add(line);
          }
        }

        if (quoteLines.isNotEmpty) {
          keyTakeaway = quoteLines
              .join(' ')
              .replaceAll('**Intisari Konsep:**', '')
              .replaceAll('**Intisari Konsep**:', '')
              .replaceAll('Intisari Konsep:', '')
              .trim();
        }
        final remaining = otherLines.join('\n').trim();
        if (remaining.isNotEmpty) {
          introMd = remaining;
        }
      } else {
        final lines = chunk.split('\n');
        final rawHeading = lines.first.replaceFirst(RegExp(r'^##\s+'), '').trim();
        final numberMatch = RegExp(r'^(\d+)\.\s*(.+)$').firstMatch(rawHeading);
        final chapterIndex = chapters.length + 1;
        final numberLabel = numberMatch != null
            ? 'BAB ${numberMatch.group(1)}'
            : 'BAB $chapterIndex';
        final cleanTitle =
            numberMatch != null ? numberMatch.group(2)!.trim() : rawHeading;
        final bodyMd = lines.skip(1).join('\n').trim();

        chapters.add((
          numberLabel: numberLabel,
          title: cleanTitle,
          bodyMd: bodyMd,
        ));
      }
    }

    return (
      keyTakeaway: keyTakeaway,
      introMd: introMd,
      chapters: chapters,
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
      appBar: ScreenHeaderBar(
        title: 'Materi Pembelajaran',
        subtitle: materialAsync.asData != null
            ? _topicMetaForMaterial(materialAsync.asData!.value).label
            : 'Konsep energi terbarukan',
        actions: [
          if (materialAsync.asData != null)
            Builder(
              builder: (context) {
                final material = materialAsync.asData!.value;
                final isBookmarked = ref.watch(
                  isMaterialBookmarkedProvider(material.id),
                );
                return ScreenHeaderAction(
                  tooltip: isBookmarked
                      ? 'Hapus dari Bookmark'
                      : 'Simpan ke Bookmark',
                  icon: isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  iconColor: isBookmarked
                      ? AppColors.freshGreen
                      : AppColors.forestGreen,
                  onTap: bookmarkController.isLoading
                      ? null
                      : () => _handleToggleBookmark(
                          context,
                          material.id,
                          isBookmarked,
                        ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: materialAsync.when(
          loading: () =>
              const LoadingView(message: 'Memuat isi materi pembelajaran...'),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(
              learningMaterialDetailProvider(widget.materialSlug),
            ),
          ),
          data: (material) {
            if (material.contentMd.trim().isEmpty) {
              return EmptyView(
                title: 'Konten Materi Kosong',
                description:
                    'Isi materi pembelajaran ini belum ditulis pada database.',
                actionLabel: 'Kembali',
                onAction: () => context.pop(),
              );
            }

            final topicMeta = _topicMetaForMaterial(material);
            final categoryColor = topicMeta.color;
            final flashcard = _flashcardForMaterial(material);
            final parsedContent = _parseMarkdownStructure(material.contentMd);
            final totalChapters = parsedContent.chapters.length;
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

            return Column(
              children: [
                // Bar Progres Baca Persisten (High-Water Mark)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceWhite,
                    border: Border(
                      bottom: BorderSide(color: AppColors.divider),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            percentRead >= 100
                                ? Icons.check_circle_rounded
                                : Icons.auto_stories_outlined,
                            size: 15,
                            color: AppColors.forestGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppTheme.pillRadius,
                              ),
                              child: LinearProgressIndicator(
                                value: isGuestSession ? 0.0 : effectiveProgress,
                                minHeight: 6,
                                backgroundColor: AppColors.offWhite,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.actionGreen,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isGuestSession
                                ? 'Pratinjau Tamu'
                                : percentRead >= 100
                                ? '100% Selesai dibaca'
                                : '$percentRead% dibaca',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      if (canResumeOffset) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Kamu pernah membaca materi ini hingga $percentRead%.',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () =>
                                  _resumeLastScrollOffset(savedOffset),
                              icon: const Icon(
                                Icons.restore_rounded,
                                size: 14,
                              ),
                              label: const Text(
                                'Lanjutkan posisi terakhir',
                                style: TextStyle(fontSize: 11.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
                    children: [
                      if (material.isDraft) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.warmYellow.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.warmYellow),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.edit_note_rounded,
                                color: AppColors.forestGreen,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Materi ini berstatus DRAF konsep dasar untuk direview.',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.forestGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 1. Kartu Hero Bergambar dengan Badge Topik Akurat & Jumlah Bab
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              categoryColor.withValues(alpha: 0.2),
                              AppColors.mintGreen.withValues(alpha: 0.65),
                              AppColors.surfaceWhite,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.cardRadius,
                          ),
                          border: Border.all(color: AppColors.sageGreen),
                          boxShadow: AppTheme.softCardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceWhite,
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.pillRadius,
                                          ),
                                          border: Border.all(
                                            color: categoryColor,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              topicMeta.icon,
                                              size: 14,
                                              color: AppColors.forestGreen,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              topicMeta.label,
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                    color:
                                                        AppColors.forestGreen,
                                                    fontWeight: FontWeight.w700,
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
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.pillRadius,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.schedule_rounded,
                                              size: 13,
                                              color: AppColors.forestGreen,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${material.readMinutes} mnt • ${material.difficultyLabel}',
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                    color:
                                                        AppColors.forestGreen,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (totalChapters > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.forestGreen,
                                            borderRadius: BorderRadius.circular(
                                              AppTheme.pillRadius,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.view_carousel_rounded,
                                                size: 13,
                                                color: AppColors.surfaceWhite,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$totalChapters Bab Terstruktur',
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                      color: AppColors
                                                          .surfaceWhite,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SoftImagePlaceholder(
                                  width: 60,
                                  height: 60,
                                  borderRadius: 16,
                                  assetPath: topicMeta.assetPath,
                                  backgroundColor: AppColors.surfaceWhite,
                                  fallbackIcon: topicMeta.icon,
                                  iconColor: AppColors.forestGreen,
                                  iconSize: 28,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              material.title,
                              style: AppTextStyles.display.copyWith(
                                fontSize: 20.5,
                                height: 1.28,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              material.summary,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 2. Kartu "Intisari Konsep Utama" (Key Takeaway Callout)
                      if (parsedContent.keyTakeaway != null &&
                          parsedContent.keyTakeaway!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.mintGreen.withValues(alpha: 0.9),
                                AppColors.surfaceWhite,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.cardRadius,
                            ),
                            border: Border.all(
                              color: AppColors.freshGreen.withValues(
                                alpha: 0.45,
                              ),
                              width: 1.3,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: AppColors.forestGreen,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.tips_and_updates_rounded,
                                      size: 16,
                                      color: AppColors.warmYellow,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Intisari Konsep Utama',
                                      style: AppTextStyles.subtitle.copyWith(
                                        fontSize: 14.5,
                                        color: AppColors.forestGreen,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceWhite,
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.pillRadius,
                                      ),
                                    ),
                                    child: Text(
                                      'Ringkasan 30 Detik',
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 10.5,
                                        color: AppColors.forestGreen,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              MarkdownBody(
                                data: parsedContent.keyTakeaway!,
                                selectable: true,
                                styleSheet: _buildMarkdownStyleSheet().copyWith(
                                  p: AppTextStyles.body.copyWith(
                                    color: AppColors.forestGreen,
                                    fontWeight: FontWeight.w600,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // 3. Eksplorasi Visual Interaktif (Membuat Belajar Tidak Monoton!)
                      _buildInteractiveConceptExplorer(
                        material: material,
                        accentColor: categoryColor,
                      ),
                      const SizedBox(height: 16),

                      // 4. Baris Status Bab & Kartu-Kartu Bab Bernomor (Chunked Learning)
                      if (parsedContent.introMd != null &&
                          parsedContent.introMd!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(
                              AppTheme.cardRadius,
                            ),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: MarkdownBody(
                            data: parsedContent.introMd!,
                            selectable: true,
                            onTapLink: (text, href, title) => _handleOpenLink(
                              context,
                              externalMapService,
                              href,
                            ),
                            styleSheet: _buildMarkdownStyleSheet(),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      if (parsedContent.chapters.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(
                              AppTheme.cardRadius,
                            ),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: MarkdownBody(
                            data: material.contentMd,
                            selectable: true,
                            onTapLink: (text, href, title) => _handleOpenLink(
                              context,
                              externalMapService,
                              href,
                            ),
                            styleSheet: _buildMarkdownStyleSheet(),
                          ),
                        )
                      else ...[
                        // Header Peta Bab
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.menu_book_rounded,
                                size: 18,
                                color: AppColors.forestGreen,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pembahasan Per Bab ($totalChapters Bab)',
                                style: AppTextStyles.subtitle.copyWith(
                                  fontSize: 15.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (var idx = 0;
                            idx < parsedContent.chapters.length;
                            idx++) ...[
                          _buildChapterCard(
                            context: context,
                            chapterIndex: idx,
                            numberLabel:
                                parsedContent.chapters[idx].numberLabel,
                            title: parsedContent.chapters[idx].title,
                            bodyMd: parsedContent.chapters[idx].bodyMd,
                            accentColor: categoryColor,
                            externalMapService: externalMapService,
                          ),
                          const SizedBox(height: 14),
                        ],
                      ],
                      const SizedBox(height: 4),

                      // Flashcard Interaktif "Uji Kilat Konsep"
                      GestureDetector(
                        onTap: () {
                          setState(
                            () => _isFlashcardRevealed = !_isFlashcardRevealed,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _isFlashcardRevealed
                                ? AppColors.mintGreen.withValues(alpha: 0.75)
                                : AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(
                              AppTheme.cardRadius,
                            ),
                            border: Border.all(
                              color: _isFlashcardRevealed
                                  ? AppColors.freshGreen
                                  : AppColors.sageGreen,
                              width: 1.4,
                            ),
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
                                      color: _isFlashcardRevealed
                                          ? AppColors.forestGreen
                                          : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _isFlashcardRevealed
                                          ? Icons.check_circle_outline_rounded
                                          : Icons.lightbulb_rounded,
                                      size: 18,
                                      color: _isFlashcardRevealed
                                          ? AppColors.surfaceWhite
                                          : const Color(0xFFD97706),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _isFlashcardRevealed
                                          ? 'Jawaban Konsep Kunci'
                                          : 'Flashcard: Uji Kilat Pemahamanmu!',
                                      style: AppTextStyles.subtitle.copyWith(
                                        fontSize: 15,
                                        color: AppColors.forestGreen,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceWhite,
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.pillRadius,
                                      ),
                                      border: Border.all(
                                        color: AppColors.divider,
                                      ),
                                    ),
                                    child: Text(
                                      _isFlashcardRevealed
                                          ? 'Tutup'
                                          : 'Ketuk Buka',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.forestGreen,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                flashcard.question,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.forestGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (_isFlashcardRevealed) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(height: 1),
                                ),
                                Text(
                                  flashcard.answer,
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.forestGreen,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Kartu Contoh Pembangkit Tercatat di Indonesia (Learn -> Explore & Impact)
                      _buildRelevantPlantsSection(
                        context: context,
                        material: material,
                        categoryColor: categoryColor,
                      ),
                      const SizedBox(height: 16),

                      // Kartu Ajakan ke Kuis Interaktif (Learn -> Evaluate)
                      _buildQuizRecommendationCard(
                        context: context,
                        material: material,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRelevantPlantsSection({
    required BuildContext context,
    required LearningMaterial material,
    required Color categoryColor,
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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: AppColors.forestGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Contoh Pembangkit Tercatat di Indonesia',
                  style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Lihat penerapan nyata materi ini pada titik pembangkit yang tercatat di Indonesia:',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          if (relevantPlants.isEmpty)
            Text(
              'Memuat contoh pembangkit terkait...',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...relevantPlants.map(
              (plant) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.push('/plants/${plant.id}'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.offWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.colorForCategorySlug(
                              plant.categorySlug ?? categorySlug,
                            ).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            iconForCategorySlug(
                              plant.categorySlug ?? categorySlug,
                            ),
                            size: 19,
                            color: AppColors.forestGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plant.name,
                                style: AppTextStyles.subtitle.copyWith(
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${plant.locationLabel} • ${plant.capacityMw != null ? "${plant.capacityMw!.toStringAsFixed(1)} MW" : "Kapasitas -"} • ${plant.operationalStatusLabel}',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (plant.isApproximate) ...[
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.pillRadius,
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFFF59E0B)
                                          .withValues(alpha: 0.45),
                                    ),
                                  ),
                                  child: Text(
                                    'Lokasi perkiraan',
                                    style: AppTextStyles.caption.copyWith(
                                      color: const Color(0xFFB45309),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                if (categorySlug.isNotEmpty) {
                  context.push(
                    '${RouteNames.energyComparisonPath}?category=$categorySlug',
                  );
                } else {
                  context.push(RouteNames.energyComparisonPath);
                }
              },
              icon: const Icon(Icons.compare_arrows_rounded, size: 18),
              label: const Text(
                'Bandingkan Manfaat & Tantangan Lingkungan',
              ),
            ),
          ),
        ],
      ),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: recommendationAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Column(
          children: [
            PrimaryButton(
              label: 'Buka Daftar Kuis Interaktif',
              icon: Icons.quiz_rounded,
              onPressed: () => context.go(RouteNames.quizPath),
            ),
          ],
        ),
        data: (recommendation) {
          final quiz = recommendation.quiz;
          final hasDirectQuiz =
              recommendation.isDirectTopicMatch && quiz != null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const SoftImagePlaceholder(
                    width: 52,
                    height: 52,
                    borderRadius: 26,
                    assetPath: 'assets/images/mascot/eco_excited.png',
                    backgroundColor: AppColors.mintGreen,
                    fallbackIcon: Icons.emoji_events_rounded,
                    iconColor: AppColors.forestGreen,
                    iconSize: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasDirectQuiz
                              ? 'Uji Pemahaman Materi Ini'
                              : 'Siap Uji Wawasanmu?',
                          style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          recommendation.reasonLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (hasDirectQuiz) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.mintGreen.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.freshGreen.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        size: 18,
                        color: AppColors.forestGreen,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          quiz.title,
                          style: AppTextStyles.subtitle.copyWith(
                            fontSize: 13.5,
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              PrimaryButton(
                label: hasDirectQuiz
                    ? (isAuthenticated
                          ? 'Mulai Kuis Topik Ini'
                          : 'Masuk untuk Mulai Kuis')
                    : 'Lihat Semua Tantangan Kuis',
                icon: hasDirectQuiz && !isAuthenticated
                    ? Icons.login_rounded
                    : Icons.quiz_rounded,
                onPressed: () {
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
              ),
              if (hasDirectQuiz) ...[
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: () => context.go(RouteNames.quizPath),
                    child: const Text('Lihat Semua Paket Kuis Lainnya'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet() {
    return MarkdownStyleSheet(
      h1: AppTextStyles.display.copyWith(fontSize: 20),
      h2: AppTextStyles.title.copyWith(
        fontSize: 17,
        color: AppColors.forestGreen,
      ),
      h3: AppTextStyles.subtitle.copyWith(
        fontSize: 14.5,
        color: AppColors.forestGreen,
      ),
      p: AppTextStyles.body.copyWith(height: 1.62),
      listBullet: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.forestGreen,
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
          left: BorderSide(
            color: AppColors.freshGreen,
            width: 4,
          ),
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
          top: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      blockSpacing: 12,
    );
  }

  Widget _buildInteractiveConceptExplorer({
    required LearningMaterial material,
    required Color accentColor,
  }) {
    final slug = material.slug.toLowerCase().trim();
    final isCrossFiveCategory =
        slug.contains('transisi-energi') ||
        slug.contains('baseload-vs-intermiten');

    if (isCrossFiveCategory) {
      const ebtItems = <({
        String label,
        IconData icon,
        Color color,
        String supplyRole,
        String regionPotential,
        String benefit,
        String challenge,
      })>[
        (
          label: 'Surya (PLTS)',
          icon: Icons.wb_sunny_rounded,
          color: AppColors.categorySolar,
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
          color: AppColors.categoryHydro,
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
          color: AppColors.categoryWind,
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
          color: AppColors.categoryGeothermal,
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
          color: AppColors.categoryBioenergy,
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

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: AppColors.sageGreen),
          boxShadow: AppTheme.softCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.mintGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.touch_app_rounded,
                    size: 17,
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
                        style: AppTextStyles.subtitle.copyWith(fontSize: 14.5),
                      ),
                      Text(
                        'Ketuk tiap jenis energi untuk membandingkan peran & trade-off lingkungannya:',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
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
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                      onTap: () =>
                          setState(() => _selectedExplorerIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
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
                                : item.color.withValues(alpha: 0.65),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              size: 14,
                              color: isSelected
                                  ? AppColors.surfaceWhite
                                  : AppColors.forestGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.label,
                              style: AppTextStyles.caption.copyWith(
                                color: isSelected
                                    ? AppColors.surfaceWhite
                                    : AppColors.forestGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
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
                  color: selected.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected.color.withValues(alpha: 0.45),
                  ),
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
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '⚡ Peran: ${selected.supplyRole}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '📍 Wilayah: ${selected.regionPotential}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
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
                            color: AppColors.freshGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Manfaat: ${selected.benefit}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textPrimary,
                                height: 1.4,
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
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tantangan Lokal: ${selected.challenge}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textPrimary,
                                height: 1.4,
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

    final stages = _stagesForMaterial(material);
    final safeStageIdx = _selectedExplorerIndex.clamp(0, stages.length - 1);
    final activeStage = stages[safeStageIdx];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.sageGreen),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_tree_rounded,
                  size: 17,
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Simulasi Alur Kerja Sistem (3 Tahap)',
                      style: AppTextStyles.subtitle.copyWith(fontSize: 14.5),
                    ),
                    Text(
                      'Ketuk tahap 1, 2, atau 3 untuk menelusuri proses konversi energi:',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(stages.length, (index) {
              final item = stages[index];
              final isSelected = index == safeStageIdx;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < stages.length - 1 ? 8 : 0,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () =>
                        setState(() => _selectedExplorerIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.forestGreen
                            : AppColors.offWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.forestGreen
                              : AppColors.divider,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            item.icon,
                            size: 18,
                            color: isSelected
                                ? AppColors.warmYellow
                                : AppColors.forestGreen,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tahap ${index + 1}',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              color: isSelected
                                  ? AppColors.mintGreen
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.shortTitle,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                              color: isSelected
                                  ? AppColors.surfaceWhite
                                  : AppColors.forestGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Container(
              key: ValueKey<int>(safeStageIdx),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.mintGreen.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.freshGreen.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeStage.headline,
                    style: AppTextStyles.subtitle.copyWith(
                      fontSize: 13.5,
                      color: AppColors.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    activeStage.detail,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                      height: 1.45,
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

  List<({
    String shortTitle,
    IconData icon,
    String headline,
    String detail,
  })> _stagesForMaterial(LearningMaterial material) {
    final slug = material.slug.toLowerCase().trim();
    if (slug.contains('penyimpanan-energi') || slug.contains('bess')) {
      return const [
        (
          shortTitle: 'Surplus Siang',
          icon: Icons.wb_sunny_rounded,
          headline: 'Tahap 1 — Penyerapan Surplus Daya (Charging / Pumping)',
          detail:
              'Saat produksi PLTS/PLTB melimpah di siang hari, kelebihan listrik disimpan ke baterai LiFePO4 (BESS) atau dipakai memompa air dari waduk bawah ke waduk atas (Pumped Storage).',
        ),
        (
          shortTitle: 'Penyimpanan',
          icon: Icons.battery_charging_full_rounded,
          headline: 'Tahap 2 — Cadangan Energi Siaga Berkapasitas Besar',
          detail:
              'Energi tersimpan sebagai energi elektrokimia di dalam modul baterai atau energi potensial gravitasi air di reservoar atas dengan efisiensi siklus 75–90%.',
        ),
        (
          shortTitle: 'Beban Puncak',
          icon: Icons.bolt_rounded,
          headline: 'Tahap 3 — Pelepasan Cepat Saat Beban Puncak Malam',
          detail:
              'Saat matahari terbenam dan konsumsi listrik rumah tangga melonjak (18.00–22.00), sistem melepaskan daya dalam hitungan milidetik hingga menit untuk menjaga kestabilan frekuensi jaringan.',
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
        ),
        (
          shortTitle: 'Kendali EMS',
          icon: Icons.memory_rounded,
          headline: 'Tahap 2 — Penyeimbangan Otomatis Smart Microgrid',
          detail:
              'Energy Management System (EMS) dan sensor digital memantau cuaca serta beban pulau secara real-time, mengatur kapan daya masuk ke baterai dan kapan disalurkan ke warga.',
        ),
        (
          shortTitle: 'Listrik 24 Jam',
          icon: Icons.home_work_rounded,
          headline: 'Tahap 3 — Kemandirian Energi Sekolah, Puskesmas, & UMKM',
          detail:
              'Masyarakat kepulauan menikmati listrik bersih 24 jam yang andal dengan biaya pokok penyediaan dan emisi karbon yang jauh lebih rendah dibanding PLTD murni.',
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
          ),
          (
            shortTitle: 'Inverter AC',
            icon: Icons.sync_alt_rounded,
            headline: 'Tahap 2 — Konversi DC ke AC & Optimasi MPPT',
            detail:
                'Inverter mengubah arus searah (DC) menjadi arus bolak-balik (AC) yang sinkron dengan frekuensi jaringan 50 Hz sekaligus mengoptimalkan titik daya maksimum.',
          ),
          (
            shortTitle: 'Jaringan PLN',
            icon: Icons.electrical_services_rounded,
            headline: 'Tahap 3 — Suplai Siang Hari & Mitigasi Intermitensi',
            detail:
                'Listrik disalurkan ke beban siang hari; saat awan melintas atau malam tiba, sistem dikombinasikan dengan PLTA waduk atau baterai BESS agar tegangan tetap stabil.',
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
          ),
          (
            shortTitle: 'Turbin Air',
            icon: Icons.cyclone_rounded,
            headline: 'Tahap 2 — Putaran Turbin Francis/Pelton & Generator',
            detail:
                'Dorongan air memutar sudu turbin yang terhubung dengan poros generator elektromagnetik dengan efisiensi konversi mencapai 85–90%.',
          ),
          (
            shortTitle: 'Penyeimbang',
            icon: Icons.balance_rounded,
            headline: 'Tahap 3 — Penopang Fleksibel Jaringan & Beban Puncak',
            detail:
                'Debit air dapat diatur dengan cepat sehingga PLTA waduk menjadi tulang punggung penyeimbang saat pembangkit surya/angin mengalami fluktuasi cuaca.',
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
          ),
          (
            shortTitle: 'Nacelle',
            icon: Icons.settings_suggest_rounded,
            headline: 'Tahap 2 — Gearbox / Direct-Drive & Pitch Control',
            detail:
                'Di dalam rumah turbin (nacelle), putaran rotor menggerakkan generator listrik, sementara sistem Pitch Control menjaga kecepatan tetap aman saat angin kencang.',
          ),
          (
            shortTitle: 'Gardu Induk',
            icon: Icons.bolt_rounded,
            headline: 'Tahap 3 — Injeksi Daya Musiman ke Sistem Transmisi',
            detail:
                'Tegangan dinaikkan melalui transformator menuju jaringan transmisi regional (seperti sistem Sulawesi Bagian Selatan pada PLTB Sidrap & Jeneponto).',
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
          ),
          (
            shortTitle: 'Turbin Uap',
            icon: Icons.precision_manufacturing_rounded,
            headline: 'Tahap 2 — Ekspansi Turbin Uap & Siklus Binary ORC',
            detail:
                'Uap kering memutar turbin generator nonstop 24 jam, sementara sisa panas air brine dimanfaatkan kembali melalui fluida kerja bertitik didih rendah.',
          ),
          (
            shortTitle: 'Reinjeksi',
            icon: Icons.recycling_rounded,
            headline: 'Tahap 3 — Sumur Reinjeksi untuk Keberlanjutan Reservoar',
            detail:
                'Air kondensat dan brine wajib dipompakan kembali ke dalam perut bumi melalui sumur injeksi agar tekanan reservoar tetap lestari dan bebas pencemaran permukaan.',
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
          ),
          (
            shortTitle: 'Konversi',
            icon: Icons.science_rounded,
            headline: 'Tahap 2 — Termal (Boiler) atau Biokimia (Biogas Metana)',
            detail:
                'Biomassa padat dibakar/digasifikasi untuk menghasilkan uap (PLTBm), sedangkan limbah cair difermentasi bakteri anaerob menjadi gas metana CH4 (PLTBg).',
          ),
          (
            shortTitle: 'Listrik Desa',
            icon: Icons.offline_bolt_rounded,
            headline: 'Tahap 3 — Listrik Terkendali & Reduksi Emisi Metana',
            detail:
                'Generator menyuplai listrik stabil bagi pabrik dan desa sekitar sekaligus mencegah pelepasan gas metana liar dari kolam limbah terbuka.',
          ),
        ];
    }
  }

  Widget _buildChapterCard({
    required BuildContext context,
    required int chapterIndex,
    required String numberLabel,
    required String title,
    required String bodyMd,
    required Color accentColor,
    required ExternalMapService externalMapService,
  }) {
    const chapterIcons = <IconData>[
      Icons.explore_rounded,
      Icons.settings_suggest_rounded,
      Icons.eco_rounded,
      Icons.fact_check_rounded,
      Icons.menu_book_rounded,
    ];
    final chapterIcon = chapterIcons[chapterIndex % chapterIcons.length];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bab berwarna lembut
          Container(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.11),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.cardRadius - 1),
              ),
              border: const Border(
                bottom: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    numberLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.surfaceWhite,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.subtitle.copyWith(
                      fontSize: 15,
                      color: AppColors.forestGreen,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  chapterIcon,
                  size: 19,
                  color: AppColors.forestGreen.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),

          // Isi Bab (Markdown terformat)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: MarkdownBody(
              data: bodyMd,
              selectable: true,
              onTapLink: (text, href, linkTitle) {
                _handleOpenLink(context, externalMapService, href);
              },
              styleSheet: _buildMarkdownStyleSheet(),
            ),
          ),
        ],
      ),
    );
  }
}
