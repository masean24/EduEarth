import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/category_chip.dart';
import '../../../../core/widgets/common/primary_button.dart';
import '../../../../core/widgets/common/secondary_button.dart';
import '../../../../core/widgets/common/soft_image_placeholder.dart';
import '../../../../models/learning_material.dart';
import '../../../../models/power_plant.dart';
import '../../domain/learning_material_parser.dart';

/// Item navigasi cepat (ScrollSpy) di bawah header materi.
class MaterialNavItem {
  const MaterialNavItem({
    required this.id,
    required this.label,
    required this.sectionKey,
  });

  final String id;
  final String label;
  final GlobalKey sectionKey;
}

/// Data satu tahapan pada stepper alur konversi energi.
typedef MaterialWorkflowStage = ({
  String shortTitle,
  IconData icon,
  String headline,
  String detail,
  String tag,
});

/// Header sticky materi: tombol kembali, judul ringkas, tombol bookmark,
/// bar progres baca tipis 5dp, banner lanjut posisi opsional, & strip ScrollSpy.
class MaterialTopHeaderBar extends StatelessWidget {
  const MaterialTopHeaderBar({
    super.key,
    required this.title,
    required this.categoryLabel,
    required this.isBookmarked,
    required this.isBookmarkBusy,
    required this.onBack,
    required this.onToggleBookmark,
    required this.progressFraction,
    required this.navItems,
    required this.activeNavId,
    required this.navItemKeys,
    required this.onSelectNav,
    this.resumePercent,
    this.onResumeOffset,
  });

  final String title;
  final String categoryLabel;
  final bool isBookmarked;
  final bool isBookmarkBusy;
  final VoidCallback onBack;
  final VoidCallback onToggleBookmark;
  final double progressFraction;
  final List<MaterialNavItem> navItems;
  final String? activeNavId;
  final Map<String, GlobalKey> navItemKeys;
  final ValueChanged<MaterialNavItem> onSelectNav;
  final int? resumePercent;
  final VoidCallback? onResumeOffset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.offWhite.withValues(alpha: 0.96),
        border: const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Kembali',
                  child: Tooltip(
                    message: 'Kembali',
                    child: InkResponse(
                      onTap: onBack,
                      radius: 24,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWhite,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: AppColors.forestGreen,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.subtitle.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: AppColors.forestGreen,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        categoryLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  toggled: isBookmarked,
                  label: isBookmarked ? 'Hapus dari Bookmark' : 'Simpan materi',
                  child: Tooltip(
                    message:
                        isBookmarked ? 'Hapus dari Bookmark' : 'Simpan materi',
                    child: InkResponse(
                      onTap: isBookmarkBusy ? null : onToggleBookmark,
                      radius: 24,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isBookmarked
                                  ? AppColors.forestGreen
                                  : AppColors.surfaceWhite,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isBookmarked
                                    ? AppColors.forestGreen
                                    : AppColors.divider,
                              ),
                            ),
                            child: isBookmarkBusy
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    isBookmarked
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_border_rounded,
                                    size: 20,
                                    color: isBookmarked
                                        ? AppColors.surfaceWhite
                                        : AppColors.forestGreen,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bar progres baca tipis 5dp
          SizedBox(
            height: 5,
            width: double.infinity,
            child: ColoredBox(
              color: const Color(0xFFD5E2D8),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progressFraction.clamp(0.0, 1.0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.actionGreen,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (resumePercent != null && onResumeOffset != null)
            Container(
              width: double.infinity,
              color: AppColors.mintGreen.withValues(alpha: 0.45),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.restore_rounded,
                    size: 16,
                    color: AppColors.forestGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pernah dibaca hingga $resumePercent%',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onResumeOffset,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: const Size(48, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Lanjutkan'),
                  ),
                ],
              ),
            ),

          if (navItems.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: navItems.map((item) {
                  final isActive = item.id == activeNavId;
                  return Padding(
                    key: navItemKeys[item.id],
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: isActive
                          ? AppColors.forestGreen
                          : AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(AppTheme.pillRadius),
                        onTap: () => onSelectNav(item),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 36),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppTheme.pillRadius,
                            ),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.forestGreen
                                  : AppColors.divider,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            item.label,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? AppColors.surfaceWhite
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kartu Hero editorial bergradien lembut kategori energi + info Mode Tamu jujur.
class MaterialEditorialHeroCard extends StatelessWidget {
  const MaterialEditorialHeroCard({
    super.key,
    required this.material,
    required this.topicLabel,
    required this.topicIcon,
    required this.softCategoryBg,
    required this.iconColor,
    required this.isGuestSession,
    required this.onLoginTap,
  });

  final LearningMaterial material;
  final String topicLabel;
  final IconData topicIcon;
  final Color softCategoryBg;
  final Color iconColor;
  final bool isGuestSession;
  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [softCategoryBg, AppColors.mintGreen],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFCFE8D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroChip(
                backgroundColor: AppColors.surfaceWhite,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(topicIcon, size: 14, color: iconColor),
                    const SizedBox(width: 6),
                    Text(
                      topicLabel,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ],
                ),
              ),
              _HeroChip(
                backgroundColor: AppColors.surfaceWhite,
                child: Text(
                  '${material.readMinutes} menit',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forestGreen,
                  ),
                ),
              ),
              _HeroChip(
                backgroundColor: AppColors.forestGreen,
                child: Text(
                  material.difficultyLabel,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.surfaceWhite,
                  ),
                ),
              ),
              if (material.isDraft)
                _HeroChip(
                  backgroundColor: AppColors.warningBg,
                  child: Text(
                    'Draf',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warningFg,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            material.title,
            style: AppTextStyles.display.copyWith(
              fontSize: 22,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: AppColors.forestGreen,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            material.summary,
            style: AppTextStyles.body.copyWith(
              fontSize: 15,
              height: 1.6,
              color: AppColors.textMuted,
            ),
          ),
          if (isGuestSession) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Text('👋', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mode tamu: progres bacamu belum tersimpan.',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onLoginTap,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: const Size(48, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Masuk',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.backgroundColor,
    required this.child,
  });

  final Color backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      ),
      child: child,
    );
  }
}

/// Kartu Intisari Konsep (Forest Green solid ber kontras tinggi).
class MaterialTakeawayCallout extends StatelessWidget {
  const MaterialTakeawayCallout({
    super.key,
    required this.takeawayMd,
    required this.markdownStyleSheet,
  });

  final String takeawayMd;
  final MarkdownStyleSheet markdownStyleSheet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.forestGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Intisari, baca 30 detik',
            style: AppTextStyles.caption.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.sageGreen,
            ),
          ),
          const SizedBox(height: 6),
          MarkdownBody(
            data: takeawayMd,
            selectable: true,
            styleSheet: markdownStyleSheet.copyWith(
              p: AppTextStyles.body.copyWith(
                color: AppColors.surfaceWhite,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                height: 1.55,
              ),
              strong: AppTextStyles.body.copyWith(
                color: AppColors.warmYellow,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stepper interaktif alur kerja pembangkit (dots bernomor + panel mint + kontrol prev/next).
class MaterialFlowStepperCard extends StatelessWidget {
  const MaterialFlowStepperCard({
    super.key,
    required this.stages,
    required this.selectedIndex,
    required this.onSelectIndex,
  });

  final List<MaterialWorkflowStage> stages;
  final int selectedIndex;
  final ValueChanged<int> onSelectIndex;

  @override
  Widget build(BuildContext context) {
    final safeIdx = selectedIndex.clamp(0, stages.length - 1);
    final activeStage = stages[safeIdx];
    final isLast = safeIdx == stages.length - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Baris dots terhubung garis progres
          Row(
            children: List.generate(stages.length * 2 - 1, (idx) {
              if (idx.isEven) {
                final stepIdx = idx ~/ 2;
                final isDone = stepIdx < safeIdx;
                final isActive = stepIdx == safeIdx;
                return Semantics(
                  button: true,
                  selected: isActive,
                  label: 'Tahap ${stepIdx + 1}: ${stages[stepIdx].shortTitle}',
                  child: InkResponse(
                    onTap: () => onSelectIndex(stepIdx),
                    radius: 24,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.forestGreen
                                : isDone
                                    ? AppColors.mintGreen
                                    : AppColors.surfaceWhite,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isActive
                                  ? AppColors.forestGreen
                                  : isDone
                                      ? AppColors.actionGreen
                                      : AppColors.divider,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: isDone
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: AppColors.forestGreen,
                                )
                              : Text(
                                  '${stepIdx + 1}',
                                  style: AppTextStyles.subtitle.copyWith(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: isActive
                                        ? AppColors.surfaceWhite
                                        : AppColors.textMuted,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                final leftStepIdx = idx ~/ 2;
                final isDone = leftStepIdx < safeIdx;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 3,
                    decoration: BoxDecoration(
                      color: isDone ? AppColors.actionGreen : AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }
            }),
          ),
          const SizedBox(height: 12),

          // Panel detail tahap aktif
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Container(
              key: ValueKey<int>(safeIdx),
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 160),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.mintGreen,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tahap ${safeIdx + 1} dari ${stages.length}',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activeStage.headline,
                    style: AppTextStyles.subtitle.copyWith(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forestGreen,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    activeStage.detail,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14.5,
                      height: 1.58,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    ),
                    child: Text(
                      activeStage.tag,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Sebelumnya',
                  onPressed:
                      safeIdx == 0 ? null : () => onSelectIndex(safeIdx - 1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: isLast ? 'Ulangi dari awal' : 'Lanjut',
                  onPressed: () =>
                      onSelectIndex(isLast ? 0 : safeIdx + 1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Grid 2 kolom komponen utama (untuk tabel 2 kolom ringkas) atau daftar kartu tabel.
class MaterialTableCardsSection extends StatelessWidget {
  const MaterialTableCardsSection({
    super.key,
    required this.table,
    required this.softCategoryBg,
    required this.iconColor,
  });

  final MaterialTableData table;
  final Color softCategoryBg;
  final Color iconColor;

  static const List<IconData> _componentIcons = <IconData>[
    Icons.wb_sunny_outlined,
    Icons.sync_alt_rounded,
    Icons.battery_charging_full_rounded,
    Icons.bolt_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final isTwoColCompact = table.headers.length == 2 && table.rows.length <= 4;

    if (isTwoColCompact) {
      final rows = <Widget>[];
      for (var i = 0; i < table.rows.length; i += 2) {
        final left = table.rows[i];
        final right = i + 1 < table.rows.length ? table.rows[i + 1] : null;
        rows.add(
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < table.rows.length ? 12 : 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildGridTile(i, left)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: right != null
                        ? _buildGridTile(i + 1, right)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return Column(children: rows);
    }

    // Tabel 3 kolom / >= 5 baris -> kartu lebar penuh agar tidak berdesakan di mobile.
    return Column(
      children: table.rows.map((row) {
        final rowTitle = row.isNotEmpty ? row[0] : '';
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rowTitle,
                style: AppTextStyles.subtitle.copyWith(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forestGreen,
                ),
              ),
              for (var c = 1; c < row.length && c < table.headers.length; c++) ...[
                const SizedBox(height: 6),
                Text(
                  table.headers[c],
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.actionGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  row[c],
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13.5,
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGridTile(int index, List<String> cells) {
    final title = cells.isNotEmpty ? cells[0] : '';
    final desc = cells.length > 1 ? cells[1] : '';
    final isEven = index.isOdd;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isEven ? AppColors.mintGreen : softCategoryBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _componentIcons[index % _componentIcons.length],
              size: 21,
              color: isEven ? AppColors.forestGreen : iconColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTextStyles.subtitle.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.forestGreen,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: AppTextStyles.caption.copyWith(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.48,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kontrol tab 2-segmen + panel putih untuk sub-bagian / dua inovasi teknologi.
class MaterialSegmentedTabsCard extends StatefulWidget {
  const MaterialSegmentedTabsCard({
    super.key,
    required this.tabs,
    required this.markdownStyleSheet,
    required this.onTapLink,
  });

  final List<MaterialSegmentedTab> tabs;
  final MarkdownStyleSheet markdownStyleSheet;
  final void Function(String text, String? href, String title) onTapLink;

  @override
  State<MaterialSegmentedTabsCard> createState() =>
      _MaterialSegmentedTabsCardState();
}

class _MaterialSegmentedTabsCardState extends State<MaterialSegmentedTabsCard> {
  int _selectedIdx = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.isEmpty) return const SizedBox.shrink();
    final safeIdx = _selectedIdx.clamp(0, widget.tabs.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0EA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: List.generate(widget.tabs.length, (i) {
              final isSelected = i == safeIdx;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selectedIdx = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.surfaceWhite
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.forestGreen.withValues(
                                  alpha: 0.12,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.tabs[i].label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.forestGreen
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Container(
            key: ValueKey<int>(safeIdx),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.divider),
            ),
            child: MarkdownBody(
              data: widget.tabs[safeIdx].bodyMd,
              selectable: true,
              onTapLink: widget.onTapLink,
              styleSheet: widget.markdownStyleSheet,
            ),
          ),
        ),
      ],
    );
  }
}

/// Kartu berpasangan Keunggulan (Mint) vs Tantangan (Soft Amber).
class MaterialProConSection extends StatelessWidget {
  const MaterialProConSection({
    super.key,
    required this.pair,
    required this.markdownStyleSheet,
    required this.onComparePressed,
  });

  final MaterialProConPair pair;
  final MarkdownStyleSheet markdownStyleSheet;
  final VoidCallback onComparePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.mintGreen,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: AppColors.forestGreen,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      pair.proTitle,
                      style: AppTextStyles.subtitle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              MarkdownBody(
                data: pair.proBodyMd,
                selectable: true,
                styleSheet: markdownStyleSheet.copyWith(
                  p: AppTextStyles.body.copyWith(
                    fontSize: 14.5,
                    height: 1.58,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF9E0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.warningFg.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppColors.warningFg,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      pair.conTitle,
                      style: AppTextStyles.subtitle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.warningFg,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              MarkdownBody(
                data: pair.conBodyMd,
                selectable: true,
                styleSheet: markdownStyleSheet.copyWith(
                  p: AppTextStyles.body.copyWith(
                    fontSize: 14.5,
                    height: 1.58,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SecondaryButton(
          label: 'Bandingkan dengan energi lain',
          icon: Icons.compare_arrows_rounded,
          onPressed: onComparePressed,
        ),
      ],
    );
  }
}

/// Kartu Flashcard 3D Flip interaktif "Uji Kilat Konsep".
class MaterialFlipFlashcard extends StatefulWidget {
  const MaterialFlipFlashcard({
    super.key,
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  State<MaterialFlipFlashcard> createState() => _MaterialFlipFlashcardState();
}

class _MaterialFlipFlashcardState extends State<MaterialFlipFlashcard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isRevealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    setState(() => _isRevealed = !_isRevealed);
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = _isRevealed ? 1.0 : 0.0;
      return;
    }
    if (_isRevealed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _isRevealed
          ? 'Kartu jawaban konsep, ketuk untuk kembali ke pertanyaan'
          : 'Kartu pertanyaan kilat, ketuk untuk melihat jawaban',
      child: GestureDetector(
        onTap: _toggleFlip,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final angle = _controller.value * math.pi;
            final showBack = angle >= (math.pi / 2);
            final displayAngle = showBack ? angle - math.pi : angle;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(displayAngle),
              child: showBack ? _buildBackFace() : _buildFrontFace(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFrontFace() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 176),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.sageGreen, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.question,
            style: AppTextStyles.subtitle.copyWith(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              height: 1.45,
              color: AppColors.forestGreen,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Ketuk untuk lihat jawaban',
            style: AppTextStyles.caption.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackFace() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 176),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.forestGreen,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
                child: Text(
                  'Jawaban Konsep Kunci',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warmYellow,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.answer,
                style: AppTextStyles.body.copyWith(
                  fontSize: 14.5,
                  height: 1.55,
                  color: AppColors.surfaceWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Ketuk untuk kembali',
            style: AppTextStyles.caption.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.sageGreen,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu baris pembangkit nyata di Indonesia yang tertaut ke PlantDetailPage.
class MaterialPlantLinkTile extends StatelessWidget {
  const MaterialPlantLinkTile({
    super.key,
    required this.plant,
    required this.onTap,
  });

  final PowerPlant plant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final slug = plant.categorySlug ?? '';
    final softBg = AppColors.softBackgroundForCategorySlug(slug);
    final fgColor = AppColors.foregroundColorForCategorySlug(slug);
    final locationParts = <String>[
      if (plant.city != null && plant.city!.trim().isNotEmpty)
        plant.city!.trim(),
      plant.province,
    ].join(', ');
    final capacityStr = plant.capacityMw != null
        ? ' · ${plant.capacityMw!.toStringAsFixed(1)} MW'
        : '';

    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: softBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  iconForCategorySlug(slug),
                  size: 21,
                  color: fgColor,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$locationParts$capacityStr',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mintGreen,
                            borderRadius: BorderRadius.circular(
                              AppTheme.pillRadius,
                            ),
                          ),
                          child: Text(
                            plant.operationalStatusLabel,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forestGreen,
                            ),
                          ),
                        ),
                        if (plant.isApproximate)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warningBg,
                              borderRadius: BorderRadius.circular(
                                AppTheme.pillRadius,
                              ),
                            ),
                            child: Text(
                              'Lokasi perkiraan',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warningFg,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.sageGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu CTA Kuis penutup di bagian paling bawah materi.
class MaterialQuizCtaCard extends StatelessWidget {
  const MaterialQuizCtaCard({
    super.key,
    required this.headline,
    required this.subtitle,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimaryTap,
    required this.onAllQuizzesTap,
  });

  final String headline;
  final String subtitle;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimaryTap;
  final VoidCallback onAllQuizzesTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.mintGreen, AppColors.surfaceWhite],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFCFE8D6)),
      ),
      child: Column(
        children: [
          const SoftImagePlaceholder(
            width: 56,
            height: 56,
            borderRadius: 28,
            assetPath: 'assets/images/mascot/eco_excited.png',
            backgroundColor: AppColors.surfaceWhite,
            fallbackIcon: Icons.emoji_events_rounded,
            iconColor: AppColors.forestGreen,
            iconSize: 28,
          ),
          const SizedBox(height: 12),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.forestGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: primaryLabel,
            icon: primaryIcon,
            onPressed: onPrimaryTap,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onAllQuizzesTap,
            child: const Text(
              'Lihat semua paket kuis',
              style: TextStyle(
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

