import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'primary_button.dart';
import 'soft_image_placeholder.dart';

/// Tampilan standar ketika terjadi kegagalan memuat data (Error State).
///
/// Dilengkapi tombol "Coba Lagi" sesuai aturan desain & error handling.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Terjadi Kendala',
    this.retryLabel = 'Coba Lagi',
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SoftImagePlaceholder(
              width: 96,
              height: 96,
              borderRadius: 24,
              assetPath: 'assets/images/mascot/eco_sad.png',
              backgroundColor: Colors.transparent,
              fallbackIcon: Icons.error_outline_rounded,
              iconColor: AppColors.errorRed,
              iconSize: 36,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: retryLabel,
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
              isExpanded: false,
            ),
          ],
        ),
      ),
    );
  }
}

