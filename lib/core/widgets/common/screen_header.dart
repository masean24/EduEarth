import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Tombol aksi bulat seragam untuk sisi kanan `ScreenHeader` dan `ScreenHeaderBar`.
class ScreenHeaderAction extends StatelessWidget {
  const ScreenHeaderAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconColor = AppColors.forestGreen,
    this.backgroundColor = AppColors.surfaceWhite,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ),
      ),
    );
  }
}

/// Header layar seragam untuk layar utama (5 tab) maupun bagian atas konten.
///
/// Menyeragamkan gaya judul (`title`), subjudul (`subtitle`), tombol kembali
/// opsional (`showBackButton`), dan deretan aksi kanan (`actions`).
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleAboveTitle = false,
    this.showBackButton = false,
    this.onBack,
    this.actions = const <Widget>[],
    this.padding = EdgeInsets.zero,
    this.isCompact = false,
  });

  final String title;
  final String? subtitle;
  final bool subtitleAboveTitle;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final titleStyle = isCompact
        ? AppTextStyles.title.copyWith(fontSize: 19)
        : AppTextStyles.display.copyWith(fontSize: 22);

    final subtitleWidget = (subtitle != null && subtitle!.trim().isNotEmpty)
        ? Text(
            subtitle!,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          )
        : null;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBackButton) ...[
            ScreenHeaderAction(
              icon: Icons.arrow_back_ios_new_rounded,
              tooltip: 'Kembali',
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (subtitleAboveTitle && subtitleWidget != null) ...[
                  subtitleWidget,
                  const SizedBox(height: 2),
                ],
                Text(
                  title,
                  style: titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!subtitleAboveTitle && subtitleWidget != null) ...[
                  const SizedBox(height: 3),
                  subtitleWidget,
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: _intersperseActions(actions),
            ),
          ],
        ],
      ),
    );
  }

  static List<Widget> _intersperseActions(List<Widget> items) {
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        result.add(const SizedBox(width: 8));
      }
      result.add(items[i]);
    }
    return result;
  }
}

/// Varian `PreferredSizeWidget` dari `ScreenHeader` untuk dipakai langsung pada
/// properti `Scaffold.appBar` di seluruh layar detail dan layar sekunder.
class ScreenHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  const ScreenHeaderBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.onBack,
    this.actions = const <Widget>[],
  });

  final String title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 72 : 60);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: AppColors.offWhite,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: ScreenHeader(
          title: title,
          subtitle: subtitle,
          showBackButton: showBackButton,
          onBack: onBack,
          actions: actions,
          isCompact: true,
        ),
      ),
    );
  }
}

