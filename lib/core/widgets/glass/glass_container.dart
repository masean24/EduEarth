import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_constants.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Notifier global untuk mengatur apakah efek blur (Liquid Glass) dikurangi,
/// sekaligus mempersistensikan pilihannya ke `SharedPreferences`.
class ReduceGlassEffectNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadSavedPreference();
    return false;
  }

  Future<void> _loadSavedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(AppConstants.prefReduceMotionAndGlass) ?? false;
    if (state != saved) {
      state = saved;
    }
  }

  Future<void> toggle() async {
    await setReduceEffect(!state);
  }

  Future<void> setReduceEffect(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefReduceMotionAndGlass, value);
  }
}

final reduceGlassEffectProvider =
    NotifierProvider<ReduceGlassEffectNotifier, bool>(
  ReduceGlassEffectNotifier.new,
);

/// Kontainer iOS Liquid Glass / Glassmorphism untuk penggunaan selektif
/// (search bar, filter chip di atas peta, bottom navigation, modal, bottom sheet).
///
/// Mendukung fallback solid tanpa `BackdropFilter` blur secara otomatis lewat
/// `reduceGlassEffectProvider` atau parameter eksplisit `enableBlur`.
class GlassContainer extends ConsumerWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = AppTheme.cardRadius,
    this.blur = 20.0,
    this.tintOpacity = 0.62,
    this.borderOpacity = 0.55,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.tintColor = AppColors.surfaceWhite,
    this.enableBlur,
    this.useRepaintBoundary = true,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final double tintOpacity;
  final double borderOpacity;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color tintColor;

  /// Bila `null`, mengikuti nilai global dari `reduceGlassEffectProvider`.
  final bool? enableBlur;

  /// Membungkus dengan `RepaintBoundary` agar performa tetap ringan di atas peta.
  final bool useRepaintBoundary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceEffectGlobal = ref.watch(reduceGlassEffectProvider);
    final shouldBlur = (enableBlur ?? !reduceEffectGlobal) && blur > 0;

    final clampedTint = tintOpacity.clamp(0.0, 1.0);

    // Saat mode glass aktif: gunakan gradasi kaca semi-transparan dengan rim border
    // sageGreen lembut agar kontras di atas latar putih maupun di atas peta.
    // Saat mode "Kurangi efek glass" aktif: gunakan permukaan putih solid bersih.
    final BoxDecoration surfaceDecoration = shouldBlur
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tintColor.withValues(
                  alpha: (clampedTint + 0.08).clamp(0.0, 0.82),
                ),
                AppColors.mintGreen.withValues(
                  alpha: (clampedTint * 0.42).clamp(0.18, 0.45),
                ),
                tintColor.withValues(
                  alpha: (clampedTint - 0.08).clamp(0.38, 0.72),
                ),
              ],
            ),
            border: Border.all(
              color: AppColors.sageGreen.withValues(
                alpha: borderOpacity.clamp(0.35, 0.75),
              ),
              width: 1.2,
            ),
          )
        : BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: AppColors.divider,
              width: 1.2,
            ),
          );

    Widget innerSurface = Container(
      padding: padding,
      decoration: surfaceDecoration,
      child: child,
    );

    if (shouldBlur) {
      innerSurface = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: innerSurface,
        ),
      );
    }

    // Bayangan ambient + rim highlight di luar ClipRRect agar efek kaca mengapung jelas
    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withValues(alpha: 0.11),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.surfaceWhite.withValues(alpha: 0.65),
            blurRadius: 2,
            spreadRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: innerSurface,
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (useRepaintBoundary) {
      return RepaintBoundary(child: content);
    }

    return content;
  }
}
